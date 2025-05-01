# frozen_string_literal: true

module XXXDownload
  module Net
    class BaseIndex < Base
      TAG = "BASE_INDEX"

      # Downloads {XXXDownload::Data::URLs.scenes}
      # Pass in a link to an individual scene
      def search_by_all_scenes(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_all_scenes"
      end

      # Downloads {XXXDownload::Data::URLs.movies}
      def search_by_movie(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_movie"
      end

      # Downloads {XXXDownload::Data::URLs.performers}
      def search_by_actor(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_actor"
      end

      # Downloads {XXXDownload::Data::URLs.page}
      def search_by_page(_url)
        raise NotImplementedError, "#{self.class.name} does not implement search_by_page"
      end

      #
      # Return the name of the performer from the given entity
      #
      def actor_name(_resource)
        raise NotImplementedError, "#{self.class.name} does not implement actor_name"
      end

      #
      # Perform any cleanup actions. E.g., close browsers
      #
      def cleanup = nil

      #
      # This is a default implementation to generate a download command
      # Override this and add a custom implementation if required.
      # e.g. for sites that use HLS streaming will require a custom command
      # @param [XXXDownload::Data::Scene] scene_data
      # @return [String] a command to run in shell to download a scene
      def command(scene_data, url, strategy = :download)
        case strategy.to_s.downcase.to_sym
        when :download
          XXXDownload::Downloader::CommandBuilder.build_basic do |b|
            b.path(scene_data.file_name, config.download_dir)
            b.url(url)
          end
        when :stream
          XXXDownload::Downloader::CommandBuilder.build_basic do |b|
            b.path(scene_data.file_name, config.download_dir)
            b.url(url)
            b.merge_parts
          end
        else raise FatalError, "[#{TAG}] Unknown strategy #{strategy}"
        end
      end

      #
      # Verify the URL to ensure it belongs to the expected site
      #
      # @param [String|URI] uri
      # @param [String|Regex] path
      # @raise [FatalError] if the uri is invalid or does not start with BASE_URI
      def verify_urls!(uri, path)
        begin
          uri = URI(uri) unless uri.is_a?(URI)
        rescue URI::InvalidURIError
          raise FatalError, "[#{TAG}] Invalid URL #{uri}"
        end

        validate_hostname!(uri)
        validate_path!(uri, path)
      end

      #
      # Helper method to make HTTP requests using HTTParty
      #
      # @param [String] uri
      # @param [Boolean] follow_redirects
      # @return [Nokogiri::XML::Document]
      # @raise [FatalError] if the URL is invalid
      def page(uri, follow_redirects: false)
        path = begin
          uri.start_with?(/(http|www)/) ? URI(uri).path : uri
        rescue URI::InvalidURIError
          uri
        end

        resp = handle_response!(return_raw: true) { self.class.get(path, follow_redirects:) }
        Nokogiri::HTML(resp.body)
      end

      private

      def validate_hostname!(uri)
        return if hostname(uri) == self.class.base_uri

        raise FatalError, "[#{TAG}] URL must start with #{self.class.base_uri}"
      end

      def validate_path!(uri, path)
        case path
        when String
          return if uri.path.include?(path)
        when Regexp
          return if uri.path.match?(path)
        else
          raise FatalError, "[#{TAG}] Invalid path type: expected String or Regexp, got #{path.class}"
        end

        XXXDownload.logger.warn "[#{TAG}] URL should be a link to #{path}. You may get unexpected results."
      end
    end
  end
end
