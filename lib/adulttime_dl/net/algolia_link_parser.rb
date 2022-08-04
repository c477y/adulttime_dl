# frozen_string_literal: true

module AdultTimeDL
  module Net
    module AlgoliaLinkParser
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def entity_name(url)
          path = URI(url).path
          path.split("/")&.[](-2)&.gsub("-", " ")
        end

        def entity_uri_name(url)
          path = URI(url).path
          path.split("/")&.[](-2)
        end

        def entity_id(url)
          path = URI(url).path
          path.split("/")&.last
        end
      end
    end
  end
end
