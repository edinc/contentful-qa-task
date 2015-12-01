require "#{File.dirname(__FILE__)}/slowandcuke.rb"

module Timestamped
  PrettyFormatter = AddsTimestamp.formatter_with_timestamped_scenario_names(Slowandcuke::Formatter)
end

