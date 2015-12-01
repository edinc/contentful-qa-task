require 'singleton'

class PaypalPaymentPage < AbstractPageObject
  include Singleton

  SAND_BOX = EnvironmentHelper::is_staging_env? ? 'sandbox\.' : ''

  set_url_matcher /https:\/\/www\.#{SAND_BOX}paypal\.com\//
  
  element :email_field,                   '#login_email,#email'
  element :password_field,                '#login_password,#password'
  element :login_button,                  '#submitLogin,#login'
  element :continue_button,               '#continue'


  def click_element element_name
    element = case element_name
    when 'Login'
      login_button
    when 'Continue'
      expect(self).to have_no_login_button
      continue_button
    else
      raise "Unknown link|button|checkbox with name '#{element_name}' for the PaypalPaymentPage."
    end
    element.click
  end


  def loaded_successfully?
    self.displayed?(Capybara.default_wait_time * 2)
  end

end


module PaypalPaymentPageModule
  def paypal_payment_page
    PaypalPaymentPage.instance
  end
end

World(PaypalPaymentPageModule)