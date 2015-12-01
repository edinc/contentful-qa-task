require 'awesome_print'
require_relative '../../features/support/ruby'

module Rocket
  module MetaFeature
    class GherkinGeneratedFormatter


      def initialize
        @io     = StringIO.new
        @indent = []
      end

      def format ast
        ast.features.each do |feature|
          print_feature feature
        end
        @io.string
      end

      protected

      def indent
        @indent.join('')
      end

      def print_feature feature
        print_comments feature
        print_name feature
        @indent << '  '
        print_description feature
        @indent << '  '
        feature.scenarios.each do |element|
          if element.instance_of? ::Rocket::MetaFeature::Gherkin::Ast::Scenario
            print_scenario element
          elsif element.instance_of? ::Rocket::MetaFeature::Gherkin::Ast::ScenarioOutline
            print_scenario_outline element
          elsif element.instance_of? ::Rocket::MetaFeature::Gherkin::Ast::Background
            print_background element
          end
        end
        @indent.pop
      end

      def print_comments element
        element.comments.each do |comment|
          @io.write indent
          @io.write comment.value
          @io.puts
        end
      end

      def print_name element
        @io.write indent
        @io.write element.keyword.rstrip.downcase.ucfirst
        @io.write ': '
        @io.write element.name
        @io.puts
      end

      def print_tags element
        @io.write indent
        element.tags.each do |tag|
          @io.write ' '+ tag.name
        end
        @io.puts
      end

      def print_feature_element element
        print_comments element
        print_tags element if defined? element.tags
        print_name element
        @indent << '      '
        print_description element
        @indent.pop
      end

      def print_description element
        @io.write indent
        @io.write element.description
        @io.puts
      end

      def print_steps steps
        steps.each do |step|
          print_step step
        end
      end

      def print_step step
        @io.write indent
        @io.write step.keyword.rstrip.downcase.ucfirst
        @io.write ' '
        @io.write step.name
        @io.puts
        if step.doc_string
          @indent << '      '
          @io.write indent+'"""'
          if step.doc_string.content_type
            @io.write step.doc_string.content_type
          end
          @io.puts
          step.doc_string.value.to_s.split("\n").each do |text|
            @io.puts indent+text
          end
          @io.puts indent+'"""'
          @indent.pop
        end
        if step.multiarg
          @indent << '      '
          print_table step.multiarg.rows
          @indent.pop
        end
      end

      def print_table rows

        rows.each do |row|
          print_comments row
          @io.write indent
          row.cells.each do |cell|
            @io.write ' | '+cell
          end
          @io.write ' |'
          @io.puts
        end

      end

      def print_scenario scenario
        print_feature_element scenario
        @indent << '  '
        print_steps scenario.steps
        @indent.pop
      end

      def print_background background
        print_feature_element background
      end

      def print_scenario_outline scenario_outline
        print_feature_element scenario_outline
        @indent << '  '
        print_steps scenario_outline.steps
        @indent.pop

        scenario_outline.examples.each do |example_table|
          print_examples example_table
        end
      end

      def print_examples examples
        print_feature_element examples
        print_table examples.rows
      end

    end
  end
end

