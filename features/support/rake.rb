require 'cucumber/rake/task'
require 'rake/dsl_definition'


module Everjobs
  module Rake
    class CucumberFailure < StandardError

    end

    class Task < ::Cucumber::Rake::Task

      def runner(task_args = nil) #:nodoc:
        cucumber_opts = [cucumber_opts_with_profile.concat((ENV['CUCUMBER_OPTS'] ? ENV['CUCUMBER_OPTS'].split(/\s+/) : []))]
        if (@rcov)
          RCovCucumberRunner.new(libs, binary, cucumber_opts, bundler, feature_files, rcov_opts)
        elsif (@fork)
          ForkedCucumberRunner.new(libs, binary, cucumber_opts, bundler, feature_files)
        else
          InProcessCucumberRunner.new(libs, cucumber_opts, feature_files)
        end
      end

      def cucumber_opts_with_profile #:nodoc:
        @profile ? [cucumber_opts, '--profile', @profile] : cucumber_opts
      end

      def define_task #:nodoc:
        desc @desc
        task @task_name => [BUILD_RESULTS, :compile_hosts] do
          runner.run
        end
      end
    end
    private
  end
end
