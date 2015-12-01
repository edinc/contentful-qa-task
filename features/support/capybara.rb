require 'capybara'
require 'capybara/selector'

module Capybara
  module Helpers
    class << self
      def normalize_whitespace(text)
        # http://en.wikipedia.org/wiki/Whitespace_character#Unicode
        # We should have a better reference.
        # See also http://stackoverflow.com/a/11758133/525872
        text.to_s.gsub(/[\s[:space:]]+/, ' ').strip
      end
    end
  end
end

module Capybara
  class Result
    def find!
      raise find_error if @result.size < 1
      @result.first
    end

    def find_error
      if @result.size == 0
        Capybara::ElementNotFound.new("Unable to find #{@query.description}")
      end
    end
  end
end

# this does not work "can't access dead object" in webdriver, but should be preferred over @driver.browser.mouse.double_click(native) in Capybara::Selenium::Node
# when a solution is found
#
#module Selenium
#  module WebDriver
#    class Element
#      def double_click
#        @bridge.doubleClick
#      end
#
#      def right_click
#        @bridge.contextClick
#      end
#    end
#  end
#end

module Capybara
  module Selenium
    class Node
      def double_click
        @driver.browser.mouse.double_click(native)
      end

      def context_click
        @driver.browser.mouse.context_click(native)
      end
    end
  end

  module Node
    class Element
      #needed for PET interactions (ExtJS)
      def double_click
        synchronize { base.double_click }
      end

      #needed for PET interactions (ExtJS)
      def context_click
        synchronize { base.context_click }
      end

      alias_method :right_click, :context_click
    end
  end
end

module Capybara
  module Node
    class Element
      def hover
        @session.driver.browser.action.move_to(self.native).perform
      end
    end
  end
end

Capybara::Selector.all[:xpath].filter(:value) { |node, value| node.value == value }

