module Queries
  module Source
    class Autocomplete < Queries::Query

      # Either match against all Sources (default) or just those with ProjectSource 
      # @return [Boolean]
      # @param limit_to_project [String] `true` or `false`
      attr_accessor :limit_to_project

      def initialize(string, project_id: nil, limit_to_project: false)
        @limit_to_project = limit_to_project
        super
      end

      def base_query
        ::Source.select('sources.*')
      end

      # @return [ActiveRecord::Relation]
      #   if and only iff author string matches
      def autocomplete_exact_author
        a = table[:cached_author_string].eq(query_string)
        base_query.where(a.to_sql).limit(20) 
      end 

      # @return [ActiveRecord::Relation]
      #   author matches any full word exactly
      def autocomplete_any_author
        a = table[:cached_author_string].matches_regexp('\m' + query_string + '\M')
        base_query.where(a.to_sql).limit(20) 
      end 

      # @return [ActiveRecord::Relation]
      #   author matches partial string 
      def autocomplete_partial_author
        a = table[:cached_author_string].matches('%' + query_string + '%')
        base_query.where(a.to_sql).limit(5) 
      end 

      # @return [ActiveRecord::Relation]
      #   multi-year match? otherwise pointless 
      def autocomplete_year
        a = table[:year].eq_any(years)
        base_query.where(a.to_sql).limit(5) 
      end 

      # @return [ActiveRecord::Relation]
      #   title matches start 
      def autocomplete_start_of_title
        a = table[:title].matches(query_string + '%')
        base_query.where(a.to_sql).limit(5) 
      end 

      # @return [ActiveRecord::Relation]
      #   author matches partial string 
      def autocomplete_wildcard_pieces
        base_query.where(match_ordered_wildcard_pieces.to_sql).limit(5) 
      end 

      # @return [ActiveRecord::Relation]
      #   author matches partial string 
      def autocomplete_wildcard_pieces_and_year
        a = match_ordered_wildcard_pieces
        b = match_year
        return nil if a.nil? || b.nil?
        c = a.and(b)
        base_query.where(c.to_sql).limit(5) 
      end 

      # @return [ActiveRecord::Relation, nil]
      def autocomplete_year_letter
        a = match_year
        b = match_year_suffix
        return nil if a.nil? || b.nil?
        c = a.and(b)
        base_query.where(c.to_sql).limit(10) 
      end

      # @return [ActiveRecord::Relation, nil]
      def autocomplete_exact_author_year_letter
        a = match_exact_author
        b = match_year_suffix
        c = match_year
        return nil if [a,b,c].include?(nil)
        d = a.and(b).and(c)
        base_query.where(d.to_sql).limit(2) 
      end 

      # @return [ActiveRecord::Relation, nil]
      def autocomplete_exact_author_year
        a = match_exact_author
        b = match_year
        return nil if a.nil? || b.nil?
        c = a.and(b)
        base_query.where(c.to_sql).limit(10) 
      end 

      def autocomplete_wildcard_author_exact_year
        a = match_year
        b = match_wildcard_author
        return nil if a.nil? || b.nil?
        c = a.and(b)
        base_query.where(c.to_sql).limit(10) 
      end

      def autocomplete_wildcard_anywhere_exact_year
        a = match_year
        b = match_wildcard_cached
        return nil if a.nil? || b.nil?
        c = a.and(b)
        base_query.where(c.to_sql).limit(10) 
      end

      # removes years!
      def autocomplete_wildcard_anywhere
        a = match_wildcard_cached
        return nil if a.nil?
        base_query.where(a.to_sql).limit(20) 
      end

      # match ALL wildcards, but unordered, if 2 - 6 pieces provided
      def match_wildcard_cached
        b = fragments
        return nil if b.empty?
        a = table[:cached].matches_all(b)
      end 

      # match ALL wildcards, but unordered, if 2 - 6 pieces provided
      def match_wildcard_author
        b = fragments
        return nil if b.empty?
        a = table[:cached_author_string].matches_all(b)
      end

      def match_exact_author
        table[:cached_author_string].eq(author_from_author_year)
      end

      def match_year_suffix
        table[:year_suffix].eq(year_letter)
      end

      def match_year
        a = years.first
        return nil if a.nil?
        table[:year].eq(a)
      end

      def match_ordered_wildcard_pieces
        a = table[:cached].matches(wildcard_pieces)
      end

      def author_from_author_year
        query_string.match(/^(.+?)\W/).to_a.last
      end

      def member_of_project_id
        project_sources_table[:project_id].eq(project_id)
      end

      # @return [ActiveRecord::Relation, nil]
      #    if user provides 5 or fewer strings and any number of years look for any string && year
      def fragment_year_matches
        if fragments.any?
          s = table[:cached].matches_any(fragments)
          s = s.and(table[:year].eq_any(years)) if !years.empty? 
          s
        else
          nil
        end 
      end

      # @return [Array]
      def autocomplete
        queries = [
          autocomplete_exact_author_year_letter,
          autocomplete_exact_author_year,
          autocomplete_wildcard_author_exact_year,
          autocomplete_wildcard_pieces,
          autocomplete_wildcard_anywhere_exact_year,
          autocomplete_wildcard_anywhere
        ]

        queries.compact!

        updated_queries = []
        queries.each_with_index do |q ,i|  
          a = q.joins(:project_sources).where(member_of_project_id.to_sql) if project_id && !limit_to_project
          a ||= q
          updated_queries[i] = a
        end

        result = []
        updated_queries.each do |q|
          result += q.to_a
          result.uniq!
          break if result.count > 19
        end
        result[0..19]
      end

      def table
        ::Source.arel_table
      end

      def project_sources_table
        ProjectSource.arel_table
      end

      # def author_roles_table 
      #   AuthorRole.arel_table
      # end 

      # def authors_table
      #   Person.arel_table
      # end 

      # def authors_join
      #   table.join(author_roles_table).on(
      #     table[:id].eq(author_roles[:role_object_id]),
      #     author_roles[:role_object_type].eq('Author')
      #   ).join(authors_table).on(
      #     author_roles[:person_id].eq(authors_table[:id])
      #   )
      # end
    end
  end
end
