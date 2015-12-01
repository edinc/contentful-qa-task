module AbstractPage

  def click_element element
    raise NotImplementedError, "Method not implemented!"
  end

  def loaded_successfully?
    raise NotImplementedError, "Method not implemented!"
  end


  def get_mandatory_fields_with_values
    $logger.info "No mandatory fields defined. Returning an empty hash instead."
    Hash.new
  end


  def security_attack_submit_button
    raise NotImplementedError, "Security attack submit button not implemented!"
  end
end
