require_relative 'gherkin_generated_formatter'

module Rocket
  module MetaFeature
    class MetaFile
      class Output
        attr_accessor :erb
        attr_writer :gherkin
        attr_accessor :country
        attr_accessor :gherkin_ast

        def initialize country
          @country = country
        end

        def gherkin
          @gherkin_output_formatter = ::Rocket::MetaFeature::GherkinGeneratedFormatter.new unless defined? @gherkin_output_formatter
          @gherkin_output_formatter.format gherkin_ast
        end

        def content
          if gherkin_ast
            self.gherkin
          else
            self.erb
          end
        end
      end
      attr_accessor :input_meta_filename
      attr_accessor :output_files
      attr_accessor :profiles
      attr_accessor :erb_processor

      attr_accessor :gherkin_processor
      attr_accessor :gherkin_ast_filters
      alias_method :path, :input_meta_filename

      def initialize filename, for_profiles
        @input_meta_filename = filename
        @output_files        = {}
        @profiles            = for_profiles
        @gherkin_ast_filters = []
      end

      def process
        puts '00'
        profiles.each do |p|
          puts "Processing country '#{p}'..."
          process_erb p
          process_gherkin p
          apply_filters p
        end
      end

      def process_erb country
        output                 = @output_files.has_key?(country) ? @output_files[country] : Output.new(country)
        output.erb             = erb_processor.process self, country
        @output_files[country] = output
      end

      def process_gherkin country
        output                 = @output_files.has_key?(country) ? @output_files[country] : raise(Exception('dppf'))
        output.gherkin_ast     = gherkin_processor.process self, country
        @output_files[country] = output
      end

      def apply_filters country
        output = @output_files.has_key?(country) ? @output_files[country] : Output.new(country)
        gherkin_ast_filters.each do |filter|
          output.gherkin_ast = filter.filter output.gherkin_ast
        end
      end

      def content for_profile
        @output_files.has_key?(for_profile) ? @output_files[for_profile].content : nil
      end

    end
  end
end

