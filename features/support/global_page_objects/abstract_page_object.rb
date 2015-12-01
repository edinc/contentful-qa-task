require_relative '../waiter_utils'
class AbstractPageObject < SitePrism::Page
  include RSpec::Matchers
  extend Capybara::Node::Matchers
  extend Capybara::RSpecMatchers
  include Capybara::DSL
  include AbstractPage
  include WaiterUtils

  include MonitorMixin

  # example wait_until call for MonitorMixin
  # monitor = new_cond
  # monitor.wait_until { page.evaluate_script('$.active') == 0 } if Capybara.current_driver == :selenium
end