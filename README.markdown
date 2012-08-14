pg_global_search [![pg_global_search Build Status][Build Icon]][Build Status]
===========================================================

pg_global_search is an extension for [pg_search](https://github.com/Casecommons/pg_search).
It is an alternative for pg_search Multi-search implementation. Instead of creating a lookup
table, pg_global_search uses a database view to search for entries.

[Site5 LLC]: http://www.site5.com
[Build Status]: http://travis-ci.org/gustavowt/pg_global_search
[Build Icon]: https://secure.travis-ci.org/site5/pg_global_search.png?branch=master

Basic Examples
--------------

First, you will need a search model:

    class Search < ActiveRecord::Base
      def readonly?
        true
      end
    end

Do not create a table for it, as it will use the database view instead.

Next we need to setup what models and fields will it look for. Add something
like this to your search model:

    pg_global_search contact: { against: [:name], associated_against: { address: [:city] }}

That will include a model called Contact in the global search, using its name field and its
Address association city field.

If you are already using pg_search, you can just pass the model names you want it to search,
and pg_global_search will use the same configuration you setup up for pg_search_scope for
those models:

    pg_global_search :contact

Next step is to create the database view. Your search model has a method called "recreate_global_search_view!",
you can use it to create the database view. You can create your own rake task to do that,
just remember that whenever you change the searchable fields, you'll have to generate the database view again.

By default, your search model will be setup will a scope named "for_term", so you can do
searches like this:

    Search.for_term "my query"

If you want to customize the search scope, you can do it like this:

    pg_global_search contact: { against: [:name], associated_against: { address: [:city] }},
                     pg_search_scope: { scope: :search, :using => :trigram, :ignoring => :accents }

    pg_global_search :contact, pg_search_scope: { scope: :search, :using => :trigram, :ignoring => :accents }

The pg_search_scope hash will be passed to pg_search_scope, so you can use the same options available in there.

Requirements
------------

* pg_search
* postgres

Installation
------------

    gem install pg_global_search

Contributors
------------

* [Fabio Kreusch](http://github.com/fabiokr)

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Add yourself to the Contributors list
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2010-2012 Site5.com. See LICENSE for details.
