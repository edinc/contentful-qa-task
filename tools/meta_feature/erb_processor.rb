require 'singleton'
require 'erb'

module Rocket
  module MetaFeature
    class ErbProcessor
      include ::Singleton
      attr_accessor :current_country

      def initialize

      end

      def process file, country
        self.current_country = country.to_s
        file_handle          = File.open(file.path, "rb")
        ERB.new(file_handle.read).result(binding)
      end

      def country *args
        args.map! do |entry|
          entry.to_s.downcase
        end
        args.include? current_country
      end
    end
  end
end
