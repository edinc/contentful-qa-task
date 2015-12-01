require 'yaml'

class YAMLHandler

  def initialize fixtures_dir
    @profile_fixtures_dir = File.join(fixtures_dir,ENV['CUCUMBER_ENV'])
    @common_fixtures_dir = File.join(fixtures_dir,"common")
  end


  def read_from_yaml file_name
    begin

      profile_fixtures_path = file_path_profile_fixtures(file_name)
      YAML.load_file(profile_fixtures_path)

    rescue SystemCallError

      # If the file could not be found in a profile fixtures dir, then use the common fixtures - dir as a fallback.
      $logger.debug "#{file_name} not found in #{profile_fixtures_path}. Try loading from common..."

      begin
        YAML.load_file(file_path_common_fixtures(file_name))
      rescue
        $logger.info "No fixture file found with name: #{file_name}"
      end
    end
  end


  def file_path_profile_fixtures(file_name)
    File.join(@profile_fixtures_dir, file_name)
  end
  private :file_path_profile_fixtures


  def file_path_common_fixtures(file_name)
    File.join(@common_fixtures_dir, file_name)
  end
  private :file_path_common_fixtures


  def self.load_urls_map
    project_name = ENV['CUCUMBER_ENV'].split('.')[0]
    urls_file_pattern = File.join(File.dirname(__FILE__), "..", "..", "profiles", "#{project_name}", "**", "#{ENV['CUCUMBER_ENV']}", "urls.yml")

    urls_file_paths = Dir.glob(urls_file_pattern)

    return Hash.new if urls_file_paths.empty?

    return YAML.load_file urls_file_paths.first
  end

end