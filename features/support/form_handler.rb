require 'singleton'

class FormHandler
  extend Capybara::Node::Actions
  include Capybara::DSL
  include Singleton


  def self.instance timestamp
    @@instance ||= new timestamp
  end


  def initialize timestamp
    @timestamp = timestamp
  end


  def fill_form_by_fixtures form_data
    resolved_input = Hash.new

    form_data.each do |id,val|

      case find_by_id(id).tag_name
        when "input","textarea"
          val = resolve_command_value val if is_command_value val
          fill_input_field id,val
        when "select"
          select_option id,val
          val = clean_select_val val
      end

      resolved_input.store id,val
    end

    resolved_input
  end


  private

  def fill_input_field id,val
    page.fill_in id, :with => val unless find_by_id(id)["disabled"]
  end


  def is_command_value val
    val.is_a?(String) && val.match(/~(.*)~/)
  end


  def resolve_command_value command_val
    command_val = command_val.gsub /~/, ""

    core_fixtures_manager = Fixtures.instance

    if command_val.include? ","
      # command value must be containing parameters. Extract and send them...

      command_and_arguments = command_val.split(",")
      command_val = command_and_arguments.first
      arguments = command_and_arguments.drop(1)

      core_fixtures_manager.send(command_val,arguments)
    else
      core_fixtures_manager.send(command_val)
    end
  end


  def select_option id,val
    return if val.nil?

    if val.to_s.match /POSITION_/
      position = val[ /(\d)+/ ].to_i

      find_by_id(id).find("option:not([value=''])")
      find_by_id(id).all("option:not([value=''])")[position].click
    elsif val.to_s.match /TEXT%\s/
      select val.to_s.gsub(/TEXT%\s/,""),from: id
    else
      find_by_id(id).find("option[value='#{val}']").click
    end
  end


  def clean_select_val val
    val.to_s.gsub(/TEXT%\s/,"")
  end

end