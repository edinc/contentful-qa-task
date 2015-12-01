require 'forwardable'

module Rocket
  module MetaFeature
    module Gherkin
      module Ast
        class ModelElement
        end

        class AstRoot < ModelElement
          attr_accessor :features

          def initialize
            @features = []
          end

          def find_scenario_outlines
            ret = []
            features.each do |feature|
              ret << feature.scenarios.select do |s|
                s.keyword =~ /(Scenario Outline|Scenario Template)/i
              end
            end
            ret.flatten!
          end
        end
        class BasicElement < ModelElement
          attr_accessor :parsed_element
          attr_accessor :line
          attr_accessor :comments
          attr_accessor :name
          attr_accessor :keyword

          def initialize parsed_element
            @parsed_element                   = parsed_element
            @comments, @keyword, @name, @line = parsed_element.comments, parsed_element.keyword, parsed_element.name, parsed_element.line
          end

        end
        class DescribedElement < BasicElement
          attr_accessor :description

          def initialize f
            super
            @description = f.description
          end

        end
        class NamedElement < DescribedElement


        end

        class TaggedElement < NamedElement
          attr_accessor :tags, :id

          def initialize f
            super
            @tags, @id = f.tags, f.id
            #@description = f.description
          end

        end
        class FeatureElement < TaggedElement
          attr_accessor :steps
          attr_accessor :steps_rewritten

          def initialize f
            super
            @steps = []
          end
        end
        class Features < BasicElement
          attr_accessor :features

        end
        class Feature < TaggedElement
          attr_accessor :background
          attr_accessor :scenarios

          def initialize f
            super
            @scenarios = []
          end

        end
        class Scenario < FeatureElement
          attr_accessor :background

        end

        class Background < NamedElement
          attr_accessor :steps

          def initialize f
            super
            @steps = []
          end
        end

        class Step < BasicElement
          attr_accessor :multiarg, :doc_string

          def initialize f
            super
            @doc_string = f.doc_string
            if f.rows && f.rows.count > 0
              @multiarg = ::Rocket::MetaFeature::Gherkin::Ast::MultilineArg.new f.rows
            end
          end

        end


        class Comment < BasicElement
          attr_accessor :comment
        end
        class Tags < BasicElement
          include Enumerable
          extend Forwardable
          def_delegators :@tags, :each, :<<
          attr_accessor :tags

          def add_tag tag_name
            @tags = [] unless @tags
            @tags.push tag_name
          end
        end
        class ScenarioOutline < FeatureElement
          attr_accessor :examples

          def initialize f
            super
            @examples = []
          end
        end

        class Examples < TaggedElement
          attr_accessor :rows

          def initialize f
            super
            @rows = f.rows
          end

        end

        class ExamplesArray < BasicElement
          attr_accessor :examples

          def add_examples examples
            @examples = [] unless @examples
            @examples.push examples
          end
        end
        class OutlineTable < BasicElement
          attr_accessor :table_rows

          def add_table_row row
            @table_rows = [] unless @table_rows
            @table_rows.push row
          end

        end

        class ExamplesOutlineTable < OutlineTable

        end

        class TableRow < BasicElement
          attr_accessor :table_cells

          def add_table_cell cell
            @table_cells = [] unless @table_cells
            @table_cells.push cell
          end

          def status
            precedent_status table_cells
          end

        end

        class MultilineArg
          attr_accessor :rows

          def initialize f
            @rows = f
          end
        end
      end


    end
  end
end
