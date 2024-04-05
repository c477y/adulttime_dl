# frozen_string_literal: true

module XXXDownload
  module Net
    module AlgoliaLinkParser
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def entity_name(url)
          path = URI(url).path
          path.split("/")&.[](-2)&.gsub("-", " ") || url
        rescue URI::InvalidURIError => e
          # Assume the user passed in the actor name instead of the actor URL
          XXXDownload.logger.trace("#{self.class.name} #{__method__} #{e.message}")
          url.gsub("-", " ")
        end

        def entity_id(url)
          path = URI(url).path
          path.split("/")&.last
        end
      end
    end
  end
end
