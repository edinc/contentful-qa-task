require 'cucumber/formatter/gherkin_formatter_adapter'

module Cucumber
  module Formatter
    # Adapts Cucumber formatter events to Gherkin formatter events
    # This class will disappear when Cucumber is based on Gherkin's model.
    class GherkinFormatterAdapter
      def before_step_result(keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line)
        arguments = step_match.step_arguments.map{|a| Gherkin::Formatter::Argument.new(a.offset, a.val)}
        location = step_match.file_colon_line
        match = Gherkin::Formatter::Model::Match.new(arguments, location)
        if @print_emtpy_match
          # Trick the formatter to believe that's what was printed previously so we get arg highlights on #result
          @gf.instance_variable_set('@match', match)
        else
          @gf.match(match)
        end

        error_message = exception ? "#{exception.message} (#{exception.class})\n#{exception.backtrace.join("\n")}" : nil
        @gf.result(Gherkin::Formatter::Model::Result.new(status, nil, error_message))
      end
    end
  end
end
