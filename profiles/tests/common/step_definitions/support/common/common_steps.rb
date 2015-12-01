Given /^I (?:go to|visit)(?: the)? "?(.*?)"?$/ do |path|

  # Sometimes, servers for static resources or the cms content are protected by http basic authentication.
  # In this case, we need to login to this server at least once.
  # Please add special characters to chars_to_encode string.
  # They have to be encoded and parsed to avoid URI:InvalidURIError, e.g. "[" or "]"
  chars_to_encode = "["
  static_resources_provider = Configuration.fetch "urls.static_resources_provider", false
  visit URI.parse(URI.encode(path_to(static_resources_provider), chars_to_encode)) if static_resources_provider

  cms_url = Configuration.fetch "urls.cms_url", false
  visit URI.parse(URI.encode(path_to(cms_url), chars_to_encode)) if cms_url

  visit URI.parse(URI.encode(path_to(path), chars_to_encode))

end

When /^I open a new tab$/ do
  page.execute_script("window.open('','_blank');")
end

When /^I switch to the new tab$/ do
  window = page.driver.browser.window_handles
  page.driver.browser.switch_to.window(window.last)
end

When /^I go back to the first tab$/ do
  window = page.driver.browser.window_handles
  page.driver.browser.switch_to.window(window.first)
end

Then /^I should see the homepage$/ do
  current_url.should =~ /^http[^\/]*\/\/[^\/]+\/\s*$/
end

When /^I delete cache and cookies$/ do
  #todo remove if selenium is fixed
  page.driver.browser.manage.add_cookie({:name => 'cookie_to_reset', :value => 'just_now'}) # prevents NullPointerException in Selenium http://code.google.com/p/selenium/issues/detail?id=1526
  Capybara.current_session.reset!
end

When /^I reload the page$/ do
  page.driver.browser.navigate.refresh
end

When /^I clear all cookies$/ do
  #todo remove if selenium is fixed
  page.driver.browser.manage.add_cookie({:name => 'cookie_to_reset', :value => 'just_now'}) # prevents NullPointerException in Selenium http://code.google.com/p/selenium/issues/detail?id=1526
  page.driver.browser.manage.delete_all_cookies
end
