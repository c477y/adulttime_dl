# frozen_string_literal: true

module XXXDownload
  module Net
    # YPP (YourPaysitePartner) powers sites like:
    # https://www.s3xus.com and https://rickysroom.com
    # which share a common API schema to fetch data
    class YppClient < BaseIndex
      include SiteAuthenticationHandler

      SEARCH_ENDPOINT = "/api/search/"
      TAG = "YPP_CLIENT"

      # @param [Class] refresher_klass A klass that inherits from BaseRefresh
      # @param [String] login_url The URL that directs the user to the login page
      # @param [String] tour_base_url A URL to the non-member page
      # @param [String] network Network name (site powered by YPP)
      # @param [String] collection_tag A upto 3 character tag for the network
      # @param [String] default_actor The default actor name to add to the scene
      #   This is useful for sites that are owned by a single actor, so their name(s) are not
      #   returned in the API response
      def initialize(refresher_klass, login_url, tour_base_url, network, collection_tag, default_actor = nil)
        @refresher_klass = refresher_klass
        @login_url = login_url
        @tour_base_url = tour_base_url
        @network = network
        @collection_tag = collection_tag
        @default_actor = Data::Actor.new(name: default_actor, gender: "male") if default_actor.present?
        super()
      end

      def search_by_all_scenes(url)
        ensure_cookies!
        scene_name = resource_name(url)
        search_resp = handle_response! { self.class.get(SEARCH_ENDPOINT + ERB::Util.url_encode(scene_name)) }
        search_resp["scenes"].map do |scene|
          YppApiProcessor.new(tour_base_url, network, collection_tag, default_actor).make_scene_data(scene)
        end
      end

      def search_by_actor(url)
        ensure_cookies!

        site_name = actors_site_name(url)
        search_resp = handle_response! { self.class.get(SEARCH_ENDPOINT + ERB::Util.url_encode(site_name)) }
        search_resp["scenes"].map do |scene|
          YppApiProcessor.new(tour_base_url, network, collection_tag, default_actor).make_scene_data(scene)
        end
      rescue XXXDownload::NotFoundError => e
        XXXDownload.logger.warn "[#{TAG}] Unable to fetch actor name from URL: #{url}"
        XXXDownload.logger.warn e.message
        []
      end

      def resource_name(resource)
        resource.slice!(-1) if resource.end_with?("/") # remove trailing slash if present
        resource.split("/").last.gsub("-", " ").titleize # remove the last part of the URL and convert to title case
      end

      alias actor_name resource_name

      private

      attr_reader :login_url, :tour_base_url, :network, :collection_tag, :default_actor

      def ensure_cookies!
        @cookies = request_cookie
        self.class.headers "Cookie" => @cookies
      end

      def request_cookie
        # Check if cookies were persisted from a previous session
        if XXXDownload.config.cookie.present?
          XXXDownload.logger.trace "[#{TAG}] Using persisted cookies from config/previous session"
          XXXDownload.config.cookie
          # Otherwise check if the user has logged in before
        elsif !logged_in?
          XXXDownload.logger.info "[#{TAG}] Opening browser to authenticate session"
          # Attempt to authenticate
          cookies_arr = authenticate(login_url) { |cookies| user_logged_in?(cookies) }
          # Persist the cookies for future use
          XXXDownload.logger.extra "[#{TAG}] Got cookies #{cookies_arr}"
          XXXDownload.config.store_cookies(cookies_arr)
          cookie = HTTP::Cookie.cookie_value(cookies_arr)
          XXXDownload.logger.extra "[#{TAG}] Set session cookies #{cookie}"
          cookie
        end
      end

      # @param cookies [Array[Hash]] cookies a list of selenium cookies
      # @return [Boolean]
      def user_logged_in?(cookies)
        return false if cookies.nil? || cookies.empty?

        # It looks like a successful login returns the cookies that start
        # with pcar and psso followed by % and random text
        # While an incorrect login will return just the pcar cookie
        cookies.any? { |x| x[:name]&.starts_with?("psso") }
      end

      def logged_in?
        @cookies ||= []
        @cookies.length.positive?
      end
    end
  end
end
