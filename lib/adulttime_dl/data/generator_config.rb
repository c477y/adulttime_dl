# frozen_string_literal: true

module AdultTimeDL
  module Data
    class GeneratorConfig < Base
      include AdultTimeDL::Utils

      SUPPORTED_SITE = Types::String.enum("julesjordan",
                                          "manuelferrara",
                                          "archangelvideo",
                                          "archangelworld")
      OBJECT = Types::String.enum("actors", "movies")

      attribute :site, SUPPORTED_SITE
      attribute :object, OBJECT
      attribute :cookie_file, Types::String

      def initialize(attributes)
        validate_config!(attributes)
        super
      end

      def generator
        case site
        when "julesjordan" then Net::Generators::JulesJordan.new(self)
        when "manuelferrara" then Net::Generators::ManuelFerrara.new(self)
        when "archangelvideo" then Net::Generators::ArchAngelVideo.new(self)
        when "archangelworld" then Net::Generators::ArchAngelWorld.new(self)
        else raise FatalError, "#{site} does not support actor/movie scraping yet"
        end
      end

      def cookie
        jar = HTTP::CookieJar.new
        jar.load(cookie_file, :cookiestxt)
        HTTP::Cookie.cookie_value(jar.cookies)
      end

      private

      def validate_config!(attributes)
        validate_cookie!(attributes[:cookie_file] || attributes["cookie_file"])
      end

      def validate_cookie!(cookie_file)
        return true if valid_file?(cookie_file)

        raise FatalError, "#{cookie_file} does not exist or cannot be read"
      end
    end
  end
end
