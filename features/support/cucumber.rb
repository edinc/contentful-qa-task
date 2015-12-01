#make current step accessible in AfterStep hook

module Cucumber
  module Ast
    class Scenario
      attr_reader :steps

      def current_step_number
        i = 1
        @steps.each do |step|
          if step.currently_active
            step_number = "%0#{@steps.count.to_s.length}d" % i
            return step_number
          end
          i += 1
        end
        return -1
      end
    end
  end
end

module Cucumber
  module Ast
    class ScenarioOutline
      attr_reader :steps

      def current_step_number
        #this will probably always return -1 because at execution time
        # no step is mark currently_active (steps is not a list of StepInvocations)
        i = 1
        @steps.each do |step|
          if step.currently_active
            step_number = "%0#{@steps.count.to_s.length}d" % i
            return step_number
          end
          i += 1
        end
        return -1
      end
    end
  end
end

module Cucumber
  module Ast
    class Background
      def steps
        return @step_invocations
      end

      def current_step_number
        i = 1
        steps.each do |step|
          if step.currently_active
            step_number = "%0#{steps.count.to_s.length}d" % i
            return step_number
          end
          i += 1
        end
        return -1
      end
    end
  end
end

module Cucumber
  module Ast
    class OutlineTable
      class ExampleRow
        def steps
          return @step_invocations
        end

        def current_step_number
          i = 1
          steps.each do |step|
            if step.currently_active
              step_number = "%0#{steps.count.to_s.length}d" % i
              return step_number
            end
            i += 1
          end
          return -1
        end
      end
    end
  end
end

module Cucumber
  module Ast
    class StepInvocation
      attr_reader :step, :currently_active

      def invoke_with_active(step_mother, configuration)
        @currently_active = true
        invoke_without_active(step_mother, configuration)
        @currently_active = false
      end

      alias_method :invoke_without_active, :invoke
      alias_method :invoke, :invoke_with_active
    end
  end
end

module Cucumber
  module Ast
    class Step
      attr_reader :step, :currently_active

      def accept_with_active(visitor)
        @currently_active = true
        accept_without_active(visitor)
        @currently_active = false
      end

      alias_method :accept_without_active, :accept
      alias_method :accept, :accept_with_active
    end
  end
end

