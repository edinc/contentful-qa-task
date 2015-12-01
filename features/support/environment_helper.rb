class EnvironmentHelper

  # Get the environment descriptor from the profile name.
  # E.g. intspace.staging.uk => staging
  def self.get_env
    Configuration::PROFILE[/\.(.*)\./, 1]
  end


  def self.is_staging_env?
    get_env.include? 'staging'
  end


  def self.is_mobile_env?
    get_env.include? 'mobile'
  end


  # Get the country descriptor from the profile name.
  # E.g. intspace.staging.uk => uk
  def self.get_country
    Configuration::PROFILE[/\..*\.(.*)/, 1]
  end


  # Get the TLD for a country.
  def self.get_tld
    case get_country
      when "uk"
        "co.uk"
      when "us"
        "com"
      when "fr"
        "fr"
      when "ca"
        "ca"
      when "au"
        "com.au"
    end
  end

end
