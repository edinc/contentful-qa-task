require 'singleton'

class JavaScriptHelper
  include RSpec::Matchers
  extend Capybara::Node::Matchers
  extend Capybara::RSpecMatchers
  include Capybara::DSL
  include MonitorMixin

  include Singleton

  def self.instance
    @@instance ||= new
  end

  def initialize debug_mode=false
    @debug_mode = debug_mode
    @monitor = new_cond
  end


  def alert_present?
    begin
      session.driver.browser.switch_to.alert

      $logger.info "Alert open!" if @debug_mode

      return true
    rescue

      $logger.info "No alert present" if @debug_mode

      return false
    end
  end


  def wait_for_ajax
    if jquery_not_present
      $logger.info "jQuery is not present."
      return
    end

    if Capybara.current_driver == :selenium

      Timeout.timeout Capybara.default_wait_time do
        loop until page.evaluate_script("$.active").zero?
      end

    else
      $logger.warn "Selenium is needed to perform Javascript-based actions. Current driver is: #{Capybara.current_driver}"
    end
  end


  def jquery_not_present
    page.evaluate_script "typeof jQuery === 'undefined'"
  end


  # For viable key symbols, please check Selenium::WebDriver::Keys
  def send_keys_to_alert_or_confirm key_sym
    begin
      page.driver.browser.switch_to.alert.send_keys key_sym
    rescue Selenium::WebDriver::Error::NoAlertOpenError
      p "no alert open!"
    end
  end


  def accept_alert_or_confirm
    page.driver.browser.switch_to.alert.accept
  end


  def suppress_unload_events
    page.execute_script "window.onbeforeunload = null"
    page.execute_script "window.onunload = null"
  end

end