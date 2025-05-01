# frozen_string_literal: true

module XXXDownload
  module Net
    class BellesaIndex < BaseIndex
      include SiteAuthenticationHandler
      TAG = "BELLESA_INDEX"
      BASE_URI = "https://bellesaplus.co"
      base_uri BASE_URI

      VIDEO_API_PATH = "/api/rest/v1/videos"

      # URL for non-members
      GUEST_BASE_URI = "https://www.bellesa.co"
      LOGIN_ENDPOINT = "/login"

      def initialize
        super
        self.class.headers "Cookie" => config.cookie
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_all_scenes(url)
        uri = URI.parse(url)
        verify_urls!(uri, %r{/videos/\d+})

        video_id = uri.path.split("/")[2]
        if video_id.nil?
          XXXDownload.logger.warn "[#{TAG}] Unable to extract video ID from #{url}. Skipping..."
          return []
        end

        fetch_video_data(video_id)
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_movie(url)
        uri = URI.parse(url)
        verify_urls!(uri, "/videos")

        uri_params = URI.decode_www_form(uri.query.to_s).to_h
        provider_name = uri_params["providers"]&.split(",")&.first
        if provider_name.nil?
          XXXDownload.logger.warn "[#{TAG}] Unable to extract provider-name from #{url}. Skipping..."
          return []
        end

        fetch_scenes_for_provider(provider_name)
      end

      # @param [String] url
      # @return [Array<Data::Scene>]
      def search_by_actor(url)
        uri = URI.parse(url)
        verify_urls!(uri, "/videos")

        uri_params = URI.decode_www_form(uri.query.to_s).to_h
        performer_name = uri_params["performers"]
        if performer_name.blank?
          XXXDownload.logger.warn "[#{TAG}] Unable to extract performers from #{url}. Skipping..."
          return []
        end

        fetch_scenes_for_performer(performer_name)
      end

      # @param [String] resource
      # @return [String]
      def actor_name(resource)
        uri = URI.parse(resource)
        params = URI.decode_www_form(uri.query.to_s).to_h
        performers = params["performers"]&.to_s&.split(",")
        raise FatalError, "[#{TAG}] Unable to extract performers from #{resource}" if performers.blank?

        XXXDownload.logger.warn "[#{TAG}] Multiple performers found for #{resource}" if performers.size > 1
        performers.first.gsub("-", " ").split.map(&:capitalize).join(" ")
      end

      private

      def fetch_scenes_for_performer(performer_name)
        with_retry_for_cookies do
          query = { "filter[performer]" => performer_name, "limit" => 1000 }
          response = handle_response! { self.class.get(VIDEO_API_PATH, query:) }
          transform_response(response)
        end
      end

      # @param [String] video_id
      def fetch_video_data(video_id)
        with_retry_for_cookies do
          query = { "filter[id]" => video_id }
          response = handle_response! { self.class.get(VIDEO_API_PATH, query:) }
          transform_response(response)
        end
      end

      def fetch_scenes_for_provider(provider_name)
        with_retry_for_cookies do
          query = { "filter[provider]" => provider_name, "limit" => 1000 }
          response = handle_response! { self.class.get(VIDEO_API_PATH, query:) }
          transform_response(response)
        end
      end

      def with_retry_for_cookies(&block)
        block.call
      rescue Dry::Struct::Error => e
        raise e unless e.cause&.key == :source && e.cause&.value.nil?

        cookie = authenticator.request_cookie(force_request: true, cookie_key: "bellesa_authentication")
        self.class.headers "Cookie" => cookie
        with_retry_for_cookies(&block)
      end

      def transform_response(resp)
        resp.each(&:deep_symbolize_keys!)
        scene_data = []
        resp.map do |h|
          XXXDownload.logger.ap h, :extra
          scene_data << Data::BellesaApiScene.new(
            id: h[:id],
            posted_on: h[:posted_on],
            title: h[:title],
            tags: h[:tags].split(","),
            source: h[:source],
            resolutions: h[:resolutions].present? ? h[:resolutions].split(",") : %w[720 1080],
            duration: h[:duration],
            content_provider: h[:content_provider].map { |x| { name: x[:name] } },
            performers: h[:performers].map { |x| { name: x[:name] } }
          ).to_scene
        end
        scene_data
      end

      def authenticator = @authenticator ||= SiteAuthenticator.new(login_url)
      def login_url = "#{BASE_URI}#{LOGIN_ENDPOINT}"
    end
  end
end
