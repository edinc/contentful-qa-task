module ExtJSElementContainer
  extend Capybara::DSL

  EXTJS_VERSION_3_JS_STR = "Ext.version"
  EXTJS_VERSION_4_JS_STR = "Ext.versions.extjs.version"

  SitePrism::ElementContainer.module_eval do

    def extjs_element(element_name, identifier, *find_args)
      extjs_build element_name, identifier, *find_args do
        define_method element_name.to_s do |*runtime_args|
          css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
          find_first css, *runtime_args
        end
      end
    end

    def extjs_elements(collection_name, identifier, *find_args)
      build collection_name, identifier, *find_args do
        define_method collection_name.to_s do |*runtime_args|
          css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
          find_all css, *runtime_args
        end
      end
    end
    alias :collection :extjs_elements

    def extjs_section(section_name, identifier, *args, &block)
      section_class, find_args = extract_section_options args, &block
      extjs_build section_name, identifier, *find_args do
        define_method section_name do | *runtime_args |
          css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
          section_class.new self, find_first(css, *runtime_args)
        end
      end
    end

    private

    def extjs_build(name, identifier, *find_args)
      if find_args.empty?
        create_no_selector name
      else
        add_to_mapped_items name
        yield
      end
      add_extjs_helper_methods name, identifier, *find_args
    end

    def add_extjs_helper_methods(name, identifier, *find_args)
      create_extjs_existence_checker name, identifier, *find_args
      create_extjs_nonexistence_checker name, identifier, *find_args
      create_extjs_waiter name, identifier, *find_args
      create_extjs_visibility_waiter name, identifier, *find_args
      create_extjs_invisibility_waiter name, identifier, *find_args
    end

    def create_extjs_existence_checker(element_name, identifier, *find_args)
      method_name = "has_#{element_name.to_s}?"
      create_helper_method method_name, *find_args do
        define_method method_name do |*runtime_args|
          wait_time = SitePrism.use_implicit_waits ? Capybara.default_wait_time : 0
          Capybara.using_wait_time wait_time do
            css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
            element_exists? css, *runtime_args
          end
        end
      end
    end

    def create_extjs_nonexistence_checker(element_name, identifier, *find_args)
      method_name = "has_no_#{element_name.to_s}?"
      create_helper_method method_name, *find_args do
        define_method method_name do |*runtime_args|
          wait_time = SitePrism.use_implicit_waits ? Capybara.default_wait_time : 0
          Capybara.using_wait_time wait_time do
            css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
            element_does_not_exist? css, *runtime_args
          end
        end
      end
    end

    def create_extjs_waiter(element_name, identifier, *find_args)
      method_name = "wait_for_#{element_name.to_s}"
      create_helper_method method_name, *find_args do
        define_method method_name do |timeout = nil, *runtime_args|
          timeout = timeout.nil? ? Capybara.default_wait_time : timeout
          Capybara.using_wait_time timeout do
            css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
            element_exists? css, *runtime_args
          end
        end
      end
    end

    def create_extjs_visibility_waiter(element_name, identifier, *find_args)
      method_name = "wait_until_#{element_name.to_s}_visible"
      create_helper_method method_name, *find_args do
        define_method method_name do |timeout = Capybara.default_wait_time, *runtime_args|
          Timeout.timeout timeout, SitePrism::TimeOutWaitingForElementVisibility do
            Capybara.using_wait_time 0 do
              css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
              # Sleep is derived from original SitePrism::ElementContainer.
              sleep 0.05 while not element_exists? css, *runtime_args, visible: true
            end
          end
        end
      end
    end

    def create_extjs_invisibility_waiter(element_name, identifier, *find_args)
      method_name = "wait_until_#{element_name.to_s}_invisible"
      create_helper_method method_name, *find_args do
        define_method method_name do |timeout = Capybara.default_wait_time, *runtime_args|
          Timeout.timeout timeout, SitePrism::TimeOutWaitingForElementInvisibility do
            Capybara.using_wait_time 0 do
              css = ExtJSElementContainer.get_element_css_from_extjs find_args, identifier
              # Sleep is derived from original SitePrism::ElementContainer.
              sleep 0.05 while element_exists? css, *runtime_args, visible: true
            end
          end
        end
      end
    end
  end

  def self.get_element_css_from_extjs find_args, identifier_key
    identifier_key = identifier_key.to_s.gsub('_', '.') if identifier_key.is_a? Symbol
    identifier_value = get_value_from_extjs find_args, identifier_key

    if identifier_key.match /.*\.?id/
      '#' + identifier_value
    else
      '.' + identifier_value
    end
  end

  def self.get_value_from_extjs find_args, identifier_key
    wait_for_rendered find_args
    js = get_js_command_for find_args, identifier_key
    page.evaluate_script(js)
  end

  def self.get_js_command_for find_args, identifier_key
    extjs_version = get_extjs_version
    case extjs_version[0]
      when "3"
        js = "Ext.ComponentMgr.all.map.#{find_args[0]}"
      when "4"
        js = "Ext.ComponentQuery.query(\"#{find_args[0]}\")"
      else
        raise "Unsupported ExtJS version: #{extjs_version} "
    end
      js + "[0].#{identifier_key}"
  end

  def self.wait_for_rendered find_args
    js_command = get_js_command_for find_args, 'rendered'
    rendered = false
    Timeout.timeout Capybara.default_wait_time, SitePrism::TimeOutWaitingForElementVisibility do
      until rendered
        begin
          rendered = page.evaluate_script(js_command)
        rescue Selenium::WebDriver::Error::UnknownError
          # Sources not loaded yet. Possible error: "Cannot read property 'find' of undefined", so we have to wait.
          # Sleep is derived from original SitePrism::ElementContainer.
          sleep 0.05
        end
      end
    end
  end

  def self.get_extjs_version
    begin
      v_3 = page.evaluate_script(EXTJS_VERSION_3_JS_STR)
      v_4 = page.evaluate_script(EXTJS_VERSION_4_JS_STR)
    rescue Selenium::WebDriver::Error::UnknownError
      # Happens when the javascript command for ExtJS version is unknown in the loaded javascript sources.
      # Nothing to do here.
    end
    return v_3 if v_3
    return v_4 if v_4
  end

end
