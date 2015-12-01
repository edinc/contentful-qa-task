module Everjobs
  module Dsl
    def within_extjs_context
      alias normal_fill_in_smart fill_in_smart
      alias fill_in_smart extjs_fill_in_smart
      yield
      alias fill_in_smart normal_fill_in_smart
    end

    def extjs_fill_in_smart (field, options)
      value = options[:with]
      element = find_field(field)
      #puts element.tag_name
      #puts element[:class]
      if element.is_fillable?
        fill_in field, :with => value
      elsif element.is_radio?
        choose(value)
      elsif element.is_select?
        element.select(value)
      else
        raise "Could not fill in any form fields with name, label or id \"#{field}\" and value \"#{value}\""
      end
      normal_fill_in_smart field, options
    end

    def extjs_select field, options
      element = find_field(field)
      puts element.tag_name

    end

    def wait_for_extjs_finish
      sleep 1 # time for showing loading layer...
      page.should_not have_selector(:css, '.x-mask-loading')
      sleep 10 # time for updating the selenium cache, otherwise element-updated exception occur
    end

  end
end
