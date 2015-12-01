require "deep_clone"

module Rocket
  module MetaFeature
    module Gherkin
      class AstCountryFilter
        def filter ast
          @for_country
          @countries        = []
          @country_replaces = {}
          @ast              = DeepClone.clone ast
          @ast.find_scenario_outlines.each do |outline|
            process_outline outline if applies? outline
          end
          #pp ast
          #pp @ast
          @ast
        end

        protected

        def applies? outline
          outline.tags.each do |tag|
            if tag.name =~ /^@tpl_i18n/i
              outline.tags.unshift ::Gherkin::Formatter::Model::Tag.new '@tpl_generated', tag.line
              outline.tags.delete(tag)
              return true
            end
          end
          false
        end

        def process_outline outline
          #prepare the mapping
          del = []
          outline.examples.each do |example|
            example.tags.each do |tag|
              if tag.name =~ /^@tpl_i18n/i
                process_example example
                del.push example
              end
            end
          end
          get_countries.each do |country|
            outline.steps.each do |step|
              process_step step, country
            end
          end
          del.each do |item|
            outline.examples.delete item
          end
          #outline.examples.delete_if do |example|
          #  example.tags.each do |tag|
          #    if tag.name =~ /^@tpl_i18n/i
          #      return true
          #    end
          #  end
          #  false
          #end
        end

        def process_step step, country
          #pp step, country
          ret = step
          #pp ret
          @country_replaces[country].each_pair do |key, value|
            reg_key = Regexp.quote(key)
            #puts step.name + ' -> '+key
            if step.name =~ /\<(#{reg_key})\>/
              #puts "FOUND#{$1}"
              #puts "OLD:  "+step.name
              step.name.gsub!(/\<#{reg_key}\>/, value)
              #puts "NEW:  "+ret.name
              #step.name
            end
          end
          #pp ret
          ret
        end

        def get_countries
          @country_replaces.keys
        end

        def get_country_replaces country
          @country_replaces[country]
        end

        def process_example example
          maps        = [] #col pos to name
          country_col = -1

          example.rows[0].cells.each_with_index do |cell, i|
            maps.push cell
            if cell =~ /^@@country/i
              country_col = i
            end
          end
          if country_col < 0
            raise ::Exception, "@@country column is missing"
          end
          example.rows[1..-1].each do |row|
            map = {}
            maps.each_with_index do |key, i|
              map[key] = row.cells[i]
            end
            @country_replaces[map['@@country'].to_sym] = map
          end
        end

        @country_replaces
      end
    end
  end
end
