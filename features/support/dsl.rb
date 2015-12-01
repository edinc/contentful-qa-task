require 'capybara/dsl'

module Everjobs
  module Dsl
    def eval_feature_input(string)
      ret     = string.to_s
      replace = {}
      ret.gsub(/%([^%]+)%/) do |match|
        fixture_name=$1
        if fixture_name =~ /^([^:]*):(.*)$/
          modifier = $1
          fix_orig = Fixtures.instance.send($2)
          case modifier.downcase
            when 'domain_only'
              fix_orig.gsub!(/(?:https?:\/\/)?(?:[^@]*@)?([^\/]+).*$/i, '\1')
            when 'img'
              fix_orig = Fixtures.instance.get_image_fixture_path($2)
          end
          replace[match] = fix_orig
        else
          replace[match] = Fixtures.instance.send(fixture_name)
        end
      end

      replace.keys.each do |to_replace|
        ret.gsub!(to_replace, replace[to_replace].to_s)
      end

      ret
    end

    def numberstring_to_i string
      case string.downcase
        when 'first'
          return 1
        when 'second'
          2
        when 'third'
          3
        when 'fourth'
          4
        else
          string.to_i
      end
    end

    def http_first_auth_fix path, clean=nil
      real_path = path_to path
      protocol  = (real_path =~ /https:\/\//i) ? 'https' : 'http'
      clean_url = real_path.gsub(/https?:\/\/([^@]*@)?(.*)$/i, '\2')
      user      = nil
      pass      = nil
      if real_path =~ /:\/\/([^:]*):([^@]*)@/
        user = $1
        pass = $2
      end

      if user && pass
        puts "#{protocol}://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}" #to show in reports where path is resolved to
      else
        puts "#{protocol}://#{clean_url}" #to show in reports where path is resolved to
      end

      #http
      if (not Configuration.fetch("urls.#{path}!no_http_auth", false)) && (not @auth_fixed_urls['http://'+ clean_url]) && (user && pass)
        visit "http://#{user}:#{pass}@#{clean_url}"
        @auth_fixed_urls['http://'+ clean_url] = true
        puts "HTTP  auth SUCCESS: http://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
      else
        visit "http://#{clean_url}"
      end

      #clean cookies
      if clean #todo remove if selenium is fixed
        page.driver.browser.manage.add_cookie({:name => 'cookie_to_reset', :value => 'just_now'}) # prevents NullPointerException in Selenium http://code.google.com/p/selenium/issues/detail?id=1526
        page.driver.browser.manage.delete_all_cookies
                                                                                                  #Capybara.current_session.reset!
        puts "Cleaned cookies" #to show in reports
      end

      #https
      if (not Configuration.fetch("urls.#{path}!no_https_auth", false)) && (not @auth_fixed_urls['https://'+ clean_url]) && (user && pass)
        begin
          using_wait_time 10 do
            visit "https://#{user}:#{pass}@#{clean_url}"
            @auth_fixed_urls['https://'+ clean_url] = true
            puts "HTTPS auth SUCCESS: https://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
          end
        rescue Exception
          #nothing to do just rescue
          puts "HTTPS auth FAILED: https://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
        end
      end


      if protocol =~ /https/
        visit "#{protocol}://#{clean_url}"
      end
    end

    def https_first_auth_fix path, clean = nil
      real_path = path_to path
      protocol  = (real_path =~ /https:\/\//i) ? 'https' : 'http'
      clean_url = real_path.gsub(/https?:\/\/([^@]*@)?(.*)$/i, '\2')
      user      = nil
      pass      = nil
      if real_path =~ /:\/\/([^:]*):([^@]*)@/
        user = $1
        pass = $2
      end

      if user && pass
        puts "#{protocol}://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}" #to show in reports where path is resolved to
      else
        puts "#{protocol}://#{clean_url}" #to show in reports where path is resolved to
      end

      #https
      if (not Configuration.fetch("urls.#{path}!no_https_auth", false)) && (not @auth_fixed_urls['https://'+ clean_url]) && (user && pass)
        begin
          using_wait_time 10 do
            visit "https://#{user}:#{pass}@#{clean_url}"
            @auth_fixed_urls['https://'+ clean_url] = true
            puts "HTTPS auth SUCCESS: https://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
          end
        rescue Exception
          #nothing to do just rescue
          puts "HTTPS auth FAILED: https://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
        end
      end

      #http
      if (not Configuration.fetch("urls.#{path}!no_http_auth", false)) && (not @auth_fixed_urls['http://'+ clean_url]) && (user && pass)
        visit "http://#{user}:#{pass}@#{clean_url}"
        @auth_fixed_urls['http://'+ clean_url] = true
        puts "HTTP  auth SUCCESS: http://#{user}:#{pass.gsub(/^((.)|(.).*(.))$/, '\3***\4')}@#{clean_url}"
      else
        visit "http://#{clean_url}"
      end
      #clean cookies

      if clean #todo remove if selenium is fixed
        page.driver.browser.manage.add_cookie({:name => 'cookie_to_reset', :value => 'just_now'}) # prevents NullPointerException in Selenium http://code.google.com/p/selenium/issues/detail?id=1526
        page.driver.browser.manage.delete_all_cookies
                                                                                                  #Capybara.current_session.reset!
        puts "Cleaned cookies" #to show in reports
      end

      if protocol =~ /https/
        visit "#{protocol}://#{clean_url}"
      end
    end
  end
end

#make Rocket::Dsl methods directly available in step definitions
World(Everjobs::Dsl)

def retry_on_timeout(n = 3, &block)
  block.call
rescue Timeout::Error, Capybara::ElementNotFound => e
  if n > 0
    #puts "Catched error: #{e.message}. #{n-1} more attempts."
    #puts "Catched error. #{n-1} more attempts."
    retry_on_timeout(n - 1, &block)
  else
    raise
  end
end

def fill_in_smart(field, options={})
  value   = options[:with]
  element = find_field(field)
  if element.is_fillable?
    fill_in field, :with => value
  elsif element.is_radio?
    choose(field)
  elsif element.is_select?
    element.select(value)
  else
    raise "Could not fill in any form fields with name, label or id \"#{field}\" and value \"#{value}\""
  end
end

Capybara::Node::Element.class_eval do
  def click_at(x, y)
    wait_until do
      right = x - (native.size.width / 2)
      top   = y - (native.size.height / 2)
      driver.browser.action.move_to(native).move_by(right.to_i, top.to_i).click.perform
    end
  end

  def is_fillable?
    return (%w(input textarea).include? tag_name) && (native[:type] != 'radio')
  end

  def is_select?
    return (tag_name == 'select')
  end

  def is_radio?
    return (native[:type] == 'radio') && (tag_name == 'input')
  end
end

#module Capybara
#  module RSpecMatchers
#    include Capybara::DSL
#    include Capybara::Node::Matchers
#    include RSpec::Matchers
#    def have_no_content(text)
#      RSpec::Matchers:: HaveMatcher.new(:content, text.to_s) do |page, matcher|
#        %(expected there to be content #{matcher.locator.inspect} in #{page.text.inspect})
#      end
#    end
#  end
#end
