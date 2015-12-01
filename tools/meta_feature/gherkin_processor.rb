require 'singleton'
require 'gherkin'
require 'gherkin/parser/parser'
require 'gherkin/formatter/pretty_formatter'
require 'stringio'
require 'multi_json'
require_relative 'gherkin_generated_formatter'
require_relative 'gherkin_ast_builder'
require_relative 'gherkin_ast_filter_country'

module Rocket
  module MetaFeature
    class GherkinProcessor
      include ::Singleton
      def initialize
      end


# This example reads a couple of features and outputs them as JSON.
      def process file, country
        ast_builder = ::Rocket::MetaFeature::Gherkin::AstBuilder.new
        @parser = ::Gherkin::Parser::Parser.new(ast_builder)
        @parser.parse(file.content(country), file.path, 0)
        ast_builder.done
        ast = ast_builder.ast_root
        print_formatted_ast ast
        ast
      end


      def print_formatted_ast ast
        formatter = ::Rocket::MetaFeature::GherkinGeneratedFormatter.new
        formatter.format ast
      end
    end
  end
end
