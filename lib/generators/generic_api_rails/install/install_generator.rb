require 'generators/generic_api_rails/helpers'

module GenericApiRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include GenericApiRails::Generators::Helpers

      source_root File.expand_path("../templates", __FILE__)

      desc "Mounts GenericApiRails into a rails app."

      def create_initializer
        template "initializer.rb", File.join('config','initializers','generic_api.rb')
      end

      def mount_engine
        inject_into_file routes_path, :after => ".routes.draw do\n" do
          "  mount GenericApiRails::Engine => '/api' \n"
        end
      end

    end
  end
end
