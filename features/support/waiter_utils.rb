module WaiterUtils

  def wait_until_element_stopped_moving element
    wait_time = SitePrism.use_implicit_waits ? Capybara.default_wait_time : 0
    Timeout.timeout wait_time, Rocket::TimeOutWaitingForElementStopMovingError do
      Capybara.using_wait_time 0 do
        while true
          initial_location = element.native.location
          sleep 0.05 # sleep necessary to check if element has changed its position within some time
          final_location = element.native.location
          break if initial_location.eql? final_location
        end
      end
    end
  end

end