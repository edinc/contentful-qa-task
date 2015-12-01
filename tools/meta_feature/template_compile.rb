require_relative 'metafile'
require_relative 'compiler'
require_relative 'erb_processor'
require_relative 'gherkin_processor'
require 'pp'

module Rocket
  module MetaFeature
    class Make

      def run
        files = get_files(File.realpath(File.dirname(__FILE__)+'/../../profiles/'))
        pp files

        files.each do |filename|
          puts '0'
          file = MetaFile.new filename, ['vn','th']
          file.erb_processor= ::Rocket::MetaFeature::ErbProcessor.instance
          file.gherkin_processor= ::Rocket::MetaFeature::GherkinProcessor.instance
          file.gherkin_ast_filters.push ::Rocket::MetaFeature::Gherkin::AstCountryFilter.new
          file.process
          file.output_files.each_pair do |country,output|
            File.open('/tmp' + "/test.#{country}.feature", 'wb') do |f|
              f.puts output.gherkin
            end
          end
        end
      end

      protected
      def get_files dir
        ret = []
        Dir.entries(dir).each do |ldir|
          unless ldir == '.' || ldir == '..'

            full_dir = File.join(dir, ldir)

            if File.directory? full_dir
              ret.push get_files full_dir
            end
            if full_dir.to_s.end_with? '.feature.erb'
              ret.push full_dir
            end
          end
        end
        ret.flatten!
        ret
      end


    end
  end
end

t = Rocket::MetaFeature::Make.new

t.run
