require 'cucumber/formatter/pretty'
module Slowandcuke
  class Formatter < Cucumber::Formatter::Pretty
    def before_step( step )
      @io.printf format_string("... %s", :comment), step.name
      @io.flush
    end

    def before_step_result( *args )
      @io.printf "\r"
      super
    end
  end
end
