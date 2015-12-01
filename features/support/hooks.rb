$pids_to_kill = {}

#can add @fast/@superfast to a feature and it will fail if it takes longer
# than the defined time
Around('@superfast') do |scenario, block|
  Timeout.timeout(2) do
    block.call
  end
end
Around('@fast') do |scenario, block|
  Timeout.timeout(5) do
    block.call
  end
end

After('@cleanup_curl') do |scenario|
  @curl_session.close if @curl_session
end

#after every step, we want to take a screenshot
AfterStep do |scenario|
  do_screenshot scenario
end

def do_screenshot(scenario)

  unless Configuration.fetch('driver') == :mobile_app
    jquery_wait_check scenario
  end

  sleep Configuration['options.wait_time_after_each_step'] if Configuration.fetch('options.wait_time_after_each_step', 0) > 0

  if Configuration.fetch('output.take_screenshot', false)
    screenshot_directory = Fixtures.instance.scenario_build_dir

    FileUtils.mkdir_p(screenshot_directory)
    time = Time.now.strftime("%Y-%m-%d_%H-%M-%S")

    screenshot_filename = ""

    if scenario.failed?
      screenshot_filename = SCENARIO_ERROR_SCREENSHOT_NAME
    else
      screenshot_filename = "#{time}.png"

      #find the currently active step
      i = 1
      scenario.steps.each do |step|
        if step.currently_active
          step_line = "#{step.keyword}#{step.name}"
          step_number = "%0#{scenario.steps.count.to_s.length}d" % i

          screenshot_filename = "#{step_number}_#{step_line.pathify}___#{time}.png"
        end

        i += 1
        end
    end

      #in headless mode, we can take the screenshot directly from the virtual frame buffer
      #which should be more fail save; Selenium has problems taking screenshots when alert
      #boxes are shown (e. g. due to SSL problems)
      if Capybara.current_driver == :webkit
        page.driver.render("#{screenshot_directory}/#{screenshot_filename}")
      elsif Configuration.fetch('driver') == :mobile_app
        screenshot({:prefix =>screenshot_directory + '/', :name => screenshot_filename})
      else
        begin
          page.driver.browser.save_screenshot("#{screenshot_directory}/#{screenshot_filename}")
        rescue Exception => e
          $stderr.puts "\nScreenshot error, but continue to execute. See https://groups.google.com/forum/?fromgroups=#!topic/selenium-users/evoYeU6nP_o ."
          $stderr.puts e.to_s
        end
      end

    if Configuration.fetch('output.embed_screenshot_link', false)
      #embed screenshot with link to file into the html output
      #make path relative
      path = screenshot_directory.to_s.sub(BASE_DIR,'')
      while path.start_with? '/'
        path = path[1..-1]
      end

      filename = File.join(path,screenshot_filename)
      embed filename, "image/png"
    end

    #it's also possible to embed screenshots as base64 directly into the HTML output
    #encoded_img = Base64.encode64(IO.read(screenshot_directory + '/' + screenshot_filename)).gsub(/\n/, '')
    #embed("data:image/png;base64,#{encoded_img}", 'image/png')
  end
end

def jquery_wait_check(scenario)
  if (not scenario.source_tag_names.include?('@no_jquery_wait')) && (Configuration.fetch('options.wait_for_jquery_after_each_step', 0) > 0)
    using_wait_time Configuration['options.wait_for_jquery_after_each_step'] do
      begin
        page.evaluate_script('$.active') == 0
      rescue
        if Configuration.fetch('options.fail_if_jquery_doesnt_finish', false)
          raise "Failed to wait for jQuery to finish operation"
        end
      end
    end
  end
end

Before do |scenario|
  feature_name = get_feature_name(scenario)
  scenario_title = scenario.instance_of?(::Cucumber::Ast::OutlineTable::ExampleRow) ? scenario.name.pathify : scenario.title.pathify
  Fixtures.instance.scenario = scenario
  Fixtures.instance.scenario_build_dir = File.absolute_path(File.join(BUILD_DIR, feature_name , scenario_title))
  if $headless && Configuration.fetch('output.make_video', false)
    $headless.video.start_capture
  end

  if Configuration.fetch('driver') != :mobile_app
    @auth_fixed_urls = {}
    if Configuration.fetch('basic_auth_fix', false)
      if Configuration.fetch('base_url', false) && Configuration.fetch('secure_url', false)
        unless scenario.source_tag_names.include?('@not_auth_fix') || scenario.source_tag_names.include?('@no_auth_fix')
          puts "Using basic auth fix"
          url=Configuration['base_url']
          puts "Visiting base url #{url.gsub(/:[^:@]+@/,':***@')}"
          visit(url)
          @auth_fixed_urls[url.gsub(/:\/\/[^@]*@/,'://')] = true
          url=Configuration['secure_url']
          puts "Visiting secure base url #{url.gsub(/:[^:@]+@/,':***@')}"
          visit(url)
          @auth_fixed_urls[url.gsub(/:\/\/[^@]*@/,'://')] = true
        end
      else
        raise "You need to define in your config.yml file base_url and secure_url if you want to use the basic_auth_fix"
      end
    end
  else
    # Install mobile app or reinstall if already on device.
    Rocket::Mobile::AppLifeCycleHandler.instance.set_up(scenario.source_tag_names.include?('@reinstall'))
  end
  #hash variable to remember captured values between steps, could be replace with a specialized object in feature
  @memory = {}

  initialize_httpaccess
end

def initialize_httpaccess
  $url_map ||= YAMLHandler.load_urls_map

  $url_map.each_value do |urls|
    urls.each do |url|
      visit url
      page.should have_css "body"
    end
  end

end
private :initialize_httpaccess

After do |scenario|
  #ensure we take a screenshot after a failed scenario (AfterStep isn't called if a step fails)
  if scenario.failed?
    do_screenshot scenario

    if Configuration.fetch('output.take_screenshot', false)
      if Configuration.fetch('output.attach_error_screenshot_to_email', false)
        feature_name = get_feature_name(scenario)
        path = File.join(BASE_DIR, 'build', 'error')
        FileUtils.mkdir_p(path)

        Dir.glob(Fixtures.instance.scenario_build_dir + '/*.png') do |f|
          file_name = File.join(feature_name , scenario.name.pathify, File.basename(f, ".png") + '.jpg').gsub(File::SEPARATOR, '-')
          puts "KKKK", file_name
          result = system("convert '#{f}' -compress jpeg -quality 15% '#{File.join(path,file_name)}'")
        end
      end
    end

  end
  if $headless
    if Configuration.fetch('output.make_video', false) and (scenario.failed? or not Configuration.fetch('output.video_only_on_error', false))
      sleep Configuration['output.video_end_wait_time'] if Configuration.fetch('output.video_end_wait_time', 0) > 0
      output_dir = Fixtures.instance.scenario_build_dir
      FileUtils.mkdir_p(output_dir)
      $headless.video.stop_and_save(output_dir+"/video_#{scenario.steps.count.to_s}_steps.mov")
    else
      $headless.video.stop_and_discard
    end
  end

  if Configuration.fetch('driver') == :mobile_app
    Rocket::Mobile::AppLifeCycleHandler.instance.tear_down(scenario.source_tag_names.include?('@uninstall'))
  end

  ## BEGIN - remember running processes to kill later ##
  pid = Process.pid
  child_pids = get_child_pids pid
  merge_pids child_pids
  ## END - remember ##

  Fixtures.instance.next_scenario
end


### DEV: the following function get_child_pids, kill_chromes, real_kill_chromes are in development and not finished
### but to be run on cucumber.ri to find out, if they are addressing the right processes <- done through writing logs of PIDs in report
def get_child_pids(pid)
  cmd = "pgrep -P #{pid}"
  #$stderr.puts cmd
  pipe = IO.popen(cmd)

  child_pids = {}
  pipe.readlines.map do |line|
    #$stderr.puts line
    child_pids[line.strip.to_i] = pid
  end
  pipe.close
  #$stderr.puts child_pids
  child_pids.keys.each do |cpid|
    #$stderr.puts "Checking #{cpid}"
    child_pids[cpid] = {:comm => child_pids[cpid], :children => get_child_pids(cpid)}
  end
  child_pids
end

def kill_chromes(pid_tree)
  ret = []
  pid_tree.each_pair do |pid,node|
    if node[:comm] == 'chromedriver'
      ret.concat real_kill_chromes(node[:children])
    else
      kill_chromes node[:children]
    end
  end
  ret
end

def real_kill_chromes(chromedriver_pid_tree)
  $stderr.puts "REAL KILLS"
  ret = []
  chromedriver_pid_tree.each_pair do |pid,node|

    #depth first
    $stderr.puts "KILL children"
    ret.concat real_kill_chromes(node[:children])

    $stderr.puts "KILL #{pid}"
    Process.kill('KILL', pid) rescue
    ret.push pid
  end
  ret
end

def merge_pids(pid_tree, all=false)
  pid_tree.each_pair do |pid, node|
    if all || (node[:comm] == 'chromedriver')
      $pids_to_kill[pid] = node
      merge_pids(node[:children], true)
    else
      merge_pids(node[:children], all)
    end
  end
  $pids_to_kill
end

def kill_all_detected_childprocesses
  $pids_to_kill.each_key do |pid|
    $stderr.puts "KILL #{pid}..."
    begin
      Process.kill('KILL', pid)
    rescue Exception => ex
      $stderr.puts ex
    end
  end
end

#it probably isn't necessary to do this
at_exit do
  $stderr.puts "#### DEBUGGING BEGIN ####"
  pid = Process.pid
  $stderr.puts "Own PID: #{Process.pid}"

  child_pids = get_child_pids pid

# Show the child processes.
  PP.pp(child_pids,$stderr)
  kill_all_detected_childprocesses
  $stderr.puts "#### DEBUGGING END ####"
  #kill_chromes(child_pids)
  #PP.pp(child_pids,$stderr)

#child_pids.each do |cpid|
#  Process.kill('KILL',cpid)
#end
end

#it probably isn't necessary to do this
Capybara::Selenium::Driver.class_eval do
  def quit
    warn "Trying to exit browser now"
    #this is just a try to handle chrome processes which couldn't be closed correctly,
    # found on: https://code.google.com/p/selenium/issues/detail?id=3378#c31
    sleep 2
    @browser.quit
    warn "DONE Trying to exit browser now"
  rescue Errno::ECONNREFUSED
    # Browser must have already gone
  end
end

def get_feature_name(scenario)
  feature_name = ''
  if defined?(scenario.scenario_outline)
    feature_name = File.join(defined?(scenario.feature) ? scenario.feature.name.pathify : scenario.scenario_outline.feature.name.pathify , scenario.scenario_outline.name.pathify)
  else
    feature_name = defined?(scenario.feature) ? scenario.feature.name.pathify : ''
  end
  return feature_name
end

at_exit do
  if Configuration.fetch('driver') == :mobile_app
    if ENV.has_key?('MOBILE_TRACKING_TEST') && (ENV['MOBILE_TRACKING_TEST'] == '1')
      tracking_env = Rocket::Mobile::TrackingEnv.instance
      if tracking_env.enabled
        tracking_env.stop_proxy
      end
    end

    Rocket::Mobile::AppLifeCycleHandler.instance.stop
  end
end


