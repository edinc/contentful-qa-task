require 'capybara/selenium/driver'
require 'selenium-webdriver'

module Capybara
  module Selenium
    Driver.class_eval do

      def browser_with_resize
        browser_was_uninitialized = @browser.nil?
        browser_without_resize
        # If the browser window was just opened, we resize it:
        if browser_was_uninitialized
          @browser.manage.window.size = ::Selenium::WebDriver::Dimension.new(Configuration.fetch('browser.width',1024), Configuration.fetch('browser.height',768))
        end
        @browser
      end

      alias_method :browser_without_resize, :browser
      alias_method :browser, :browser_with_resize

    end
  end
end

module Selenium
  module WebDriver
    module Firefox
      Binary.class_eval do
        remove_const :WAIT_TIMEOUT
        WAIT_TIMEOUT=90
      end

      Launcher.class_eval do
        remove_const :STABLE_CONNECTION_TIMEOUT
        STABLE_CONNECTION_TIMEOUT=60

        def launch_with_retry(*args)
          retry_count = 0
          begin
            launch_without_retry *args
          rescue Error::WebDriverError
            retry_count += 1
            if (retry_count <= Configuration.fetch('selenium.retry_count', 3))
              warn "Warning: Retrying Firefox launch due to timeout - attempt #{retry_count}"
              if Configuration.fetch('output.take_screenshot', false)
                screenshot_directory = Fixtures.instance.scenario_build_dir

                FileUtils.mkdir_p(screenshot_directory)
                time                = Time.now.strftime("%Y-%m-%d_%H-%M-%S")
                screenshot_filename = "#{time}-retry#{retry_count.to_s}.png"
                begin
                  page.driver.browser.save_screenshot("#{screenshot_directory}/#{screenshot_filename}")
                rescue Exception => e
                  $stderr.puts "\nScreenshot error, but continue to execute. See https://groups.google.com/forum/?fromgroups=#!topic/selenium-users/evoYeU6nP_o ."
                  $stderr.puts e.to_s
                end
              end

              retry
            end
            raise
          end
        end

        alias_method :launch_without_retry, :launch
        alias_method :launch, :launch_with_retry

      end
    end
  end
end

module Selenium
  module WebDriver
    module Remote
      module Http
        Default.class_eval do

          def response_for_with_retry(*args)
            retry_count = 0
            begin
              response_for_without_retry *args
            rescue Timeout::Error
              retry_count += 1
              if (retry_count <= Configuration.fetch('selenium.retry_count', 3))
                warn "Warning: Retrying HTTP fetch due to timeout - attempt #{retry_count}"
                retry
              end
              raise
            end
          end

          alias_method :response_for_without_retry, :response_for
          alias_method :response_for, :response_for_with_retry

        end
      end
    end
  end
end
