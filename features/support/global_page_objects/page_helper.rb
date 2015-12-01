require 'singleton'
class PageHelper
  include Singleton
  include RSpec::Matchers
  extend Capybara::Node::Matchers
  extend Capybara::RSpecMatchers
  include Capybara::DSL

  def self.instance
    @@instance ||= new
  end


  def get_page_for page_name
    page = page_name.downcase.tr(' ', '_') + '_page'
    page_class = @pages[page.to_sym]
    raise Rocket::PageNotImplementedError, "Page with name '#{page_name}' not implemented!" if page_class.nil?
    page_class
  end

end
