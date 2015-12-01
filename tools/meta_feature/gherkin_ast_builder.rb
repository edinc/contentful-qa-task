require 'gherkin/formatter/ansi_escapes'
require 'gherkin/formatter/step_printer'
require 'gherkin/formatter/argument'
require 'gherkin/formatter/escaping'
require 'gherkin/formatter/model'
require 'gherkin/native'
require 'stringio'
require_relative 'gherkin_ast'

module Rocket
  module MetaFeature
    module Gherkin
      class AstBuilder
        native_impl('gherkin')

        include ::Gherkin::Formatter::AnsiEscapes
        include ::Gherkin::Formatter::Escaping

        def initialize
          @step_printer   = ::Gherkin::Formatter::StepPrinter.new
          @background     = nil
          @tag_statement  = nil
          @steps          = []
          @io             = StringIO.new
          @step_container = nil
          @feature_container = ::Rocket::MetaFeature::Gherkin::Ast::AstRoot.new
          @scenario_container = nil
          @examples_container = nil
        end

        def ast_root
          @feature_container
        end

        def uri(uri)
          @uri = uri
        end

        def feature(feature)
          f               = ::Rocket::MetaFeature::Gherkin::Ast::Feature.new(feature)
          @feature_container.features << f
          @scenario_container = f
          @step_container = nil
        end

        def background(background)
          b = ::Rocket::MetaFeature::Gherkin::Ast::Background.new background
          @scenario_container.scenarios << b
          @step_container = b
        end

        def scenario(scenario)
          b = ::Rocket::MetaFeature::Gherkin::Ast::Scenario.new scenario
          @scenario_container.scenarios << b
          @step_container = b
        end

        def scenario_outline(scenario_outline)
          b = ::Rocket::MetaFeature::Gherkin::Ast::ScenarioOutline.new scenario_outline
          @scenario_container.scenarios << b
          @examples_container = b
          @step_container = b
        end

        def examples(examples)
          b = ::Rocket::MetaFeature::Gherkin::Ast::Examples.new examples
          @examples_container.examples << b
          @step_container = nil
        end

        def step(step)
          @step_container.steps << (::Rocket::MetaFeature::Gherkin::Ast::Step.new step)
        end

        def arg_format(key)
          format("#{key}_arg")
        end

        def eof
          # NO-OP
        end

        def done
          # NO-OP
        end

        private

        def doc_string(doc_string)
          @io.puts "      \"\"\"" + doc_string.content_type + "\n" + escape_triple_quotes(indent(doc_string.value, '      ')) + "\n      \"\"\""
        end

        def exception(exception)
          exception_text = "#{exception.message} (#{exception.class})\n#{(exception.backtrace || []).join("\n")}".gsub(/^/, '      ')
          @io.puts(failed(exception_text))
        end

        def escape_triple_quotes(s)
          s.gsub(TRIPLE_QUOTES, '\"\"\"')
        end
      end
    end
  end
end
