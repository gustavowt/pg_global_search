require 'pg_search'

module PgGlobalSearch
  class InvalidSetup < Exception;end

  def self.included(base)
    base.send :include, PgSearch unless base.include?(PgSearch)
    base.extend ClassMethods
  end

  module ClassMethods
    # Reimplements pg_search pg_search_scope to store the search options
    # for later usage.
    def pg_search_scope(name, options)
      unless respond_to?(:pg_search_scope_options)
        cattr_accessor :pg_search_scope_options
        self.pg_search_scope_options = {}
      end

      self.pg_search_scope_options[name] = options

      self.scope(name, PgSearch::Scope.new(name, self, options).to_proc)
    end

    # Checks if the model was configured with pg_search_scope.
    def pg_search_scope?
      respond_to?(:pg_search_scope_options) && pg_search_scope_options
    end

    # Sets up a global search.
    #
    # If you want to use existing configurations for pg_search_scope,
    # call pg_global_search with a list of the models you want to be
    # searchable:
    #
    #    pg_global_search :contact
    #
    # If you want to manually setup the search parameters, you can
    # pass a hash of models and their setup. This mimics the
    # pg_search_scope available options. E.g.:
    #
    #    pg_global_search contact: { against: [:name], associated_against: { address: [:city] }}
    def pg_global_search(*args)
      cattr_accessor :pg_global_search_options
      self.pg_global_search_options = args

      self.primary_key = :searchable_id

      belongs_to :searchable, polymorphic: true

      pg_search_scope_options = if args.size > 1
        args.extract_options!.delete(:pg_search_scope) || {}
      else
        args.first.delete(:pg_search_scope) || {}
      end

      pg_search_scope (pg_search_scope_options.delete(:scope) || :for_term), pg_search_scope_options.merge(:against => [:term])
    end

    def pg_global_search?
      respond_to?(:pg_global_search_options) && pg_global_search_options
    end

    # Recreates the search view
    def recreate_global_search_view!
      ::ActiveRecord::Base.connection.execute pg_global_search_view_sql
    end

    # Retrieves the view creation sql
    def pg_global_search_view_sql
      raise InvalidSetup, "#{self.name} model is not configured with pg_global_search" unless respond_to?(:pg_global_search_options)

      setup = if pg_global_search_options.size > 1
        # we have a list of models, so we use the already configured pg_search_scope
        pg_search_scope_model_setups
      else
        # uses the custom setup
        pg_global_search_options.extract_options!
      end

      unions = setup.map do |model, options|
        model = model.to_s.camelize.constantize

        pg_global_search_fields_sql(model, options[:against]) +
          pg_global_search_associations_fields_sql(model, options[:associated_against])
      end.flatten

      raise InvalidSetup, "Did you configured #{self.name} with pg_global_search properly?" unless unions.present?

      "CREATE OR REPLACE VIEW #{table_name} AS #{unions.join(" UNION ")};"
    end

    private

    def pg_search_scope_model_setups
      pg_global_search_options.each_with_object({}) do |model, hash|
        model_class = model.to_s.camelize.constantize

        unless model_class.respond_to?(:pg_search_scope_options) && model_class.pg_search_scope_options
          raise InvalidSetup, "#{model_class.name} is not setup with pg_search_scope"
        end

        # use the first available configured pg_search_scope
        hash[model] = model_class.pg_search_scope_options.first.last
      end
    end

    def pg_global_search_fields_sql(model, fields)
      fields ||= []

      fields.map do |field|
        "SELECT #{model.table_name}.#{field} AS term, #{model.table_name}.#{model.primary_key} AS searchable_id, CAST ('#{model.name}' AS varchar) AS searchable_type FROM #{model.table_name}"
      end
    end

    def pg_global_search_associations_fields_sql(model, associations)
      associations ||= {}

      associations.map do |association_name, fields|
        association = model.reflect_on_association(association_name)

        fields.map do |field|
          select = "SELECT #{association.table_name}.#{field} AS term, #{model.table_name}.#{model.primary_key} AS searchable_id, CAST ('#{model.name}' AS varchar) AS searchable_type FROM #{model.table_name} JOIN #{association.table_name} ON #{model.table_name}.#{model.primary_key} = #{association.table_name}.#{association.foreign_key}"

          # Deals with polymorphic associations
          if association.respond_to?(:type)
            "#{select} AND #{association.table_name}.#{association.type} = '#{model.name}'"
          else
            select
          end
        end
      end
    end
  end

  def readonly?
    true
  end
end
