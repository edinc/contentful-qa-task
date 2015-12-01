require "rubygems"
require "bundler/setup"
require 'rbconfig'
require 'cucumber/formatter/unicode'
require 'time'
require 'logger'

#Terminus and Watir are similar to Selenium and wrap around a
#(possibly headless) browser to run tests.
#require 'terminus'
#require 'watir'

require File.dirname(__FILE__) + '/configuration.rb';

$debug = ENV['CUCUMBER_DEBUG'] == '1'
puts "DEBUG MODE" if $debug

$unique_random_number = rand(899999999) + 100000000



### BUILD DIRECTORY ###

$build_id = ENV['BUILD_ID'] ? ENV['BUILD_ID'] : Time.now.strftime("%Y-%m-%d_%H-%M-%S")
$base_dir = File.absolute_path(File.expand_path(File.dirname(__FILE__) + '/../..'))
BASE_DIR=$base_dir

Dir.chdir($base_dir)
$build_dir = './build/' + $build_id
if ENV['BUILD_NUMBER']
  $build_dir += '_' + ENV['BUILD_NUMBER']
end
if ENV['RERUN'] && ENV['RERUN'] =~ /^(1|true|t)$/i
  $build_dir += '_rerun'
end
$workspace = File.join($base_dir, $build_dir)

BUILD_ROOT=File.join(BASE_DIR,'build')
BUILD_DIR=$workspace
BUILD_DIR_RELATIVE=$build_dir
FIXTURES_DIR=File.join($base_dir, 'fixtures')

FileUtils.mkdir_p(BUILD_DIR)


SCENARIO_ERROR_SCREENSHOT_NAME = "error_screenshot.png"


### SET PATH ###

#additional path where Selenium can find browser binaries

#64bit
if 1.size * 8 == 64
  ENV['PATH'] = ENV['PATH'] + ':' + BASE_DIR + '/bin/64'
#32bit
else
  ENV['PATH'] = ENV['PATH'] + ':' + BASE_DIR + '/bin'
end



### PRELOAD HOSTS FILE ###
if Configuration.fetch('options.load_custom_hosts_file', true)
  if File.exists? File.join(BASE_DIR.gsub(/ /, '\\ '), '/bin/override.so')
    ENV['LD_PRELOAD']=File.join(BASE_DIR.gsub(/ /, '\\ '), '/bin/override.so')
    ENV['EXCLUDE_HOSTS_FILE']=File.join(BASE_DIR,
       Configuration.fetch('options.custom_hosts_file', '/hosts'))
  end
end

def setup_global_logger
  unless $logger_prepared
    $logger = Logger.new $stdout
    $logger.level = Logger::INFO

    $logger_prepared = true
  end

end
private :setup_global_logger

setup_global_logger

def setup_browser_env
  require 'capybara'
  require 'capybara/dsl'
  require 'capybara/cucumber'
  require 'selenium-webdriver'
  require 'selenium/webdriver/remote/http/curb'
  require 'site_prism'


  ### CAPYBARA CONFIG ###

  Capybara.default_driver = Configuration['driver']

  #Time that Capybara waits to find html elements (e. g. after an AJAX action)
  Capybara.default_wait_time = Configuration['browser']['wait_time']

  # Default selector type for methods like find(), all(), has_selector(), etc.
  Capybara.default_selector = Configuration['browser']['selector']

  #Main URL of the current site/domain we're testing, read from config.yml for the selected profile
  Capybara.app_host = Configuration['base_url']

  ### SITEPRISM ###

  # Use implicit waits while initialization of elements
  SitePrism.configure do |config|
    config.use_implicit_waits = true
  end

  ### SELENIUM ###

  #To adjust browser and settings we can manually instanciate selenium, but this we don't have to.
  if Capybara.default_driver == :selenium
    Capybara.register_driver :selenium do |app|
      case Configuration.fetch('options.webdriver.client', :default)
        when :curb
          client = Selenium::WebDriver::Remote::Http::Curb.new
          puts "Using curb selenium client driver"
        when :persistent
          require 'selenium/webdriver/remote/http/persistent'
          client = Selenium::WebDriver::Remote::Http::Persistent.new
          puts "Using net-persistent selenium client driver"
        else #default
          client = Selenium::WebDriver::Remote::Http::Default.new # when using selenium hub, this prevents 500er errors
          puts "Using default selenium client driver"
      end

      #important timeout for communication between Selenium and Firefox; default is 60 s and if load
      #is high, the communication breaks easily if Firefox answers not fast enough (yes, Selenium and
      #Firefox communication through HTTP)
      client.timeout = Configuration.fetch('selenium.client_timeout', 60)

      port_increment = 10 * (ENV['EXECUTOR_NUMBER'] ? ENV['EXECUTOR_NUMBER'].to_i : 0)

      browser = Configuration.fetch('browser.type', :firefox)

      options = {
          #resynchronization shouldn't be set and used, it's deprecated and removed in Capybara 2.0
          #:resynchronize => Configuration.fetch('options.use_resynchronize', false),
          :browser => browser
      }

      if Configuration.fetch('options.webdriver.use_hub', false)
        options.store :desired_capabilities, browser
        options.store :http_client, client
        options.store :browser, :remote
        options.store :url, Configuration.fetch('options.webdriver.hub_url', "http://127.0.0.1:4444/wd/hub")

      elsif browser == :firefox
        profile = Selenium::WebDriver::Firefox::Profile.new

        profile["browser.download.folderList"] = 2
        profile["browser.download.dir"] = BUILD_DIR
        profile["browser.helperApps.neverAsk.saveToDisk"] = "text/csv application/zip"

        #firebug network traffic
        if Configuration.fetch("browser.firefox.network_traffic_log", true)
          puts "firebug traffic logger activated"
          profile.add_extension File.expand_path "features/support/extensions/firebug-2.0.11.xpi"
          profile.add_extension File.expand_path "features/support/extensions/netExport-0.9b7.xpi"

          #configure Firebug
          profile['extensions.firebug.currentVersion'] = "2.0.11" # avoid 'first run' tab
          profile["extensions.firebug.previousPlacement"] = 3 # start firebug minimized
          profile["extensions.firebug.onByDefault"] = true
          profile["extensions.firebug.allPagesActivation"] = "on"
          profile["extensions.firebug.defaultPanelName"] = "net" # sets the default pane to Net for easier access
          profile["extensions.firebug.net.enableSites"] = true # Enables the Net Panel
          profile["extensions.firebug.netexport.alwaysEnableAutoExport"]= true
          profile["extensions.firebug.netexport.defaultLogDir"]= File.expand_path BUILD_DIR_RELATIVE
          profile["extensions.firebug.netexport.showPreview"]= false
        end

        if Configuration.fetch("browser.log_js_errors",false)
          profile.add_extension File.expand_path "features/support/extensions/JSErrorCollector.xpi"
        end

        #useragent string
        if Configuration.fetch("browser.#{browser.to_s}.user_agent_string", nil)
          puts "Using user agent configuration: " + Configuration['browser.firefox.user_agent_string']
          profile['general.useragent.override'] = Configuration['browser.firefox.user_agent_string']
        end
        profile['dom.max_chrome_script_run_time'] = Configuration['browser']['wait_time'];
        profile['dom.max_script_run_time'] = Configuration['browser']['wait_time'];
        profile['network.dns.disableIPv6'] = true;
        profile['network.http.max-connections'] = 30;

        options.store :profile, profile
        #this doesn't work if browser == :chrome -> chrome with selenium grid
        options.store :port, 7055 + port_increment
      elsif browser == :chrome
        binary_path = Configuration.fetch('browser.chrome.binary',ENV['CUCUMBER_CHROME_BINARY'])
        if binary_path
          Selenium::WebDriver::Chrome.path = binary_path
          puts "Using chrome binary: #{Selenium::WebDriver::Chrome.path}"
        end

        # set user agent without mobile emulation
        if Configuration.fetch("browser.#{browser.to_s}.user_agent_string_no_mobile", nil)
          useragent = Configuration['browser.chrome.user_agent_string_no_mobile']
          options.store :switches, ["--user-agent='#{useragent}'"]

          puts "Using user agent #{useragent}"
        end

        # user agent string + (optional) width, height and pixel ratio
        if Configuration.fetch("browser.#{browser.to_s}.user_agent_string", nil)
          width = Configuration['browser.chrome.mobile_width'] ||= 360
          height = Configuration['browser.chrome.mobile_height'] ||= 600
          pixel_ratio = Configuration['browser.chrome.mobile_pixel_ratio'] ||= 3.0
          mobile_emulation = {
              :deviceMetrics => { :width => width, :height => height, :pixelRatio => pixel_ratio },
              :userAgent => Configuration['browser.chrome.user_agent_string']
          }
          caps = Selenium::WebDriver::Remote::Capabilities.chrome('chromeOptions' => { :mobileEmulation => mobile_emulation })
          options.store :desired_capabilities, caps

          puts 'Using user agent configuration: ' + Configuration['browser.chrome.user_agent_string']
        end
        # mobile device name
        if Configuration.fetch("browser.#{browser.to_s}.mobile_device_name", nil)
          mobile_emulation = { :deviceName => Configuration['browser.chrome.mobile_device_name'] }
          caps = Selenium::WebDriver::Remote::Capabilities.chrome('chromeOptions' => { :mobileEmulation => mobile_emulation })
          options.store :desired_capabilities, caps

          puts 'Using mobile configuration for device with name: ' + Configuration['browser.chrome.mobile_device_name']
        end
      end

      options.store :http_client, client

      Capybara::Selenium::Driver.new(app, options)
    end
  end

### WEBKIT ###
  if Capybara.default_driver == :webkit
    Capybara.current_session.driver.resize_window(Configuration['browser']['width'], Configuration['browser']['height'])
  end

end

setup_browser_env
