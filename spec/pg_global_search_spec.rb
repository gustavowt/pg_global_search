require 'pg_global_search'
require 'pg'

ActiveSupport.on_load :active_record do
  ActiveRecord::Base.send :include, PgGlobalSearch
end

begin
  ActiveRecord::Base.configurations = YAML.load_file(File.expand_path("spec/dummy/config/database.yml"))
  ActiveRecord::Base.establish_connection "test"

  connection = ActiveRecord::Base.connection
  postgresql_version = connection.send(:postgresql_version)
  connection.execute("SELECT 1")
rescue PGError => e
  puts "-" * 80
  puts "Unable to connect to database.  Please run:"
  puts
  puts "    createdb pg_global_search_test"
  puts "-" * 80
  raise e
end

class SearchableAssociation < ActiveRecord::Base; end

class SearchableModelOne < ActiveRecord::Base
  pg_search_scope :search, { :against => [:search_field_one, :search_field_two] }
end

class SearchableModelTwo < ActiveRecord::Base
  has_one :searchable_association, :as => :associatable
  pg_search_scope :search, { :against => [:search_field_three], :associated_against => { :searchable_association => [:search_field_four] }}
end

describe PgGlobalSearch do
  let(:example) do
    Class.new(ActiveRecord::Base).tap do |klass|
      klass.stub(:table_name => :pg_global_search_example)
    end
  end

  context "with manual setup" do
    before do
      example.pg_global_search :searchable_model_one =>  { :against => [:custom_field_one, :custom_field_two] },
                               :searchable_model_two => { :against => [:custom_field_three], :associated_against => { :searchable_association => [:custom_field_four] }},
                               :pg_search_scope => { :scope => :search, :using => :trigram, :ignoring => :accents }
    end

    let(:expected_sql) {
      expected = <<-SQL
        CREATE OR REPLACE VIEW pg_global_search_example AS
        SELECT searchable_model_ones.custom_field_one AS term, searchable_model_ones.id AS searchable_id, CAST ('SearchableModelOne' AS varchar) AS searchable_type FROM searchable_model_ones
        UNION SELECT searchable_model_ones.custom_field_two AS term, searchable_model_ones.id AS searchable_id, CAST ('SearchableModelOne' AS varchar) AS searchable_type FROM searchable_model_ones
        UNION SELECT searchable_model_twos.custom_field_three AS term, searchable_model_twos.id AS searchable_id, CAST ('SearchableModelTwo' AS varchar) AS searchable_type FROM searchable_model_twos
        UNION SELECT searchable_associations.custom_field_four AS term, searchable_model_twos.id AS searchable_id, CAST ('SearchableModelTwo' AS varchar) AS searchable_type FROM searchable_model_twos JOIN searchable_associations ON searchable_model_twos.id = searchable_associations.associatable_id AND searchable_associations.associatable_type = 'SearchableModelTwo';
      SQL

      expected.strip.gsub(/\s+/, ' ')
    }

    describe "#pg_global_search_view_sql" do
      it "outputs a valid view sql" do
        example.pg_global_search_view_sql.should == expected_sql
      end
    end

    it "belongs_to a polymorphic searchable" do
      example.reflect_on_association(:searchable).options[:polymorphic].should be_true
    end

    it "sets up pg_search_scope" do
      example.pg_search_scope_options.should == { :search => { :against => [:term], :using => :trigram, :ignoring => :accents }}
    end

    it "sets primary key to searchable_id" do
      example.primary_key.should == "searchable_id"
    end
  end

  context "with existing setup" do
    before do
      example.pg_global_search :searchable_model_one, :searchable_model_two, :pg_search_scope => { :scope => :search, :using => :trigram, :ignoring => :accents }
    end

    let(:expected_sql) {
      expected = <<-SQL
        CREATE OR REPLACE VIEW pg_global_search_example AS
        SELECT searchable_model_ones.search_field_one AS term, searchable_model_ones.id AS searchable_id, CAST ('SearchableModelOne' AS varchar) AS searchable_type FROM searchable_model_ones
        UNION SELECT searchable_model_ones.search_field_two AS term, searchable_model_ones.id AS searchable_id, CAST ('SearchableModelOne' AS varchar) AS searchable_type FROM searchable_model_ones
        UNION SELECT searchable_model_twos.search_field_three AS term, searchable_model_twos.id AS searchable_id, CAST ('SearchableModelTwo' AS varchar) AS searchable_type FROM searchable_model_twos
        UNION SELECT searchable_associations.search_field_four AS term, searchable_model_twos.id AS searchable_id, CAST ('SearchableModelTwo' AS varchar) AS searchable_type FROM searchable_model_twos JOIN searchable_associations ON searchable_model_twos.id = searchable_associations.associatable_id AND searchable_associations.associatable_type = 'SearchableModelTwo';
      SQL

      expected.strip.gsub(/\s+/, ' ')
    }

    describe "#pg_global_search_view_sql" do
      it "outputs a valid view sql" do
        example.pg_global_search_view_sql.should == expected_sql
      end
    end

    it "belongs_to a polymorphic searchable" do
      example.reflect_on_association(:searchable).options[:polymorphic].should be_true
    end

    it "sets up pg_search_scope" do
      example.pg_search_scope_options.should == { :search => { :against => [:term], :using => :trigram, :ignoring => :accents }}
    end

    it "sets primary key to searchable_id" do
      example.primary_key.should == "searchable_id"
    end
  end
end
