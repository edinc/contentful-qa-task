class SeleniumNativeHelper
  extend Capybara::DSL

  def self.hover elem
    page.driver.browser.action.move_to(elem.native).perform
  end
end