# frozen_string_literal: true

module XXXDownload
  module Data
    class GeneratorConfig < Base
      include XXXDownload::Utils

      SUPPORTED_SITE = Types::String.enum("julesjordan",
                                          "manuelferrara",
                                          "archangelvideo",
                                          "archangelworld",
                                          "ztod")
      OBJECT = Types::String.enum("actors", "movies")

      attribute :site, SUPPORTED_SITE
      attribute :object, OBJECT
      attribute? :cookie_file, Types::String.optional

      def initialize(attributes)
        attributes[:exec_path] = Dir.pwd
        super
      end

      def generator
        case site
        when "archangelvideo" then Net::Generators::ArchAngelVideo.new(self)
        when "archangelworld" then Net::Generators::ArchAngelWorld.new(self)
        when "julesjordan" then Net::Generators::JulesJordan.new(self)
        when "manuelferrara" then Net::Generators::ManuelFerrara.new(self)
        when "ztod" then Net::Generators::ZtodGenerator.new(self)
        else raise FatalError, "#{site} does not support actor/movie scraping yet"
        end
      end
    end
  end
end
