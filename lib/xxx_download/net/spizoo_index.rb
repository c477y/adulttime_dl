# frozen_string_literal: true

module XXXDownload
  module Net
    class SpizooIndex < BaseIndex
      include SiteAuthenticationHandler

      TAG = "SPIZOO_INDEX"
      BASE_URI = "https://www.spizoo.com/members"
      base_uri BASE_URI

      def search_by_all_scenes(url)
        verify_urls(url, "/gallery")
        ensure_cookies!

        fetch(url) # to verify the link is valid
        [create_lazy_scene(scene_link(url))]
      end

      def search_by_actor(url)
        verify_urls(url, "/sets")
        ensure_cookies!

        doc = fetch(url)

        # If an actor has many scenes, Spizoo renders a different HTML
        multi = doc.css("#model-bio-scene .row .thumbnail-img")
                   .map { |x| x["href"] }.uniq.compact
                   .map { |x| create_lazy_scene(x) }

        last = doc.css("#model-bio-scene .model-last-video a")
                  .map { |x| x["href"] }
                  .map { |x| create_lazy_scene(x) }

        multi + last
      end

      def search_by_page(url)
        verify_urls(url, "/category")
        ensure_cookies!

        doc = fetch(url)
        doc.css("#videos-section .row .thumbnail-img")
           .map { |x| x["href"] }.uniq.compact
           .map { |x| create_lazy_scene(x) }
      end

      def actor_name(resource)
        ensure_cookies!

        doc = fetch(resource)
        doc.css("#model-bio .model-name").text.strip.presence
      end

      private

      # @param [String] url
      # @param [String] path
      def verify_urls(url, path)
        return if url.include?(path)

        XXXDownload.logger.warn "[#{TAG}] URL should be a link to #{path}. You may get unexpected results."
      end

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
          cookies_arr = authenticate(BASE_URI) { |cookies| user_logged_in?(cookies) }
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

        cookies.any? { |x| x[:name]&.starts_with?("pcar") }
      end

      def logged_in?
        @cookies ||= []
        @cookies.length.positive?
      end

      def scene_link(url)
        url.gsub(BASE_URI, "")
      end

      def create_lazy_scene(path)
        path = "/#{path}" unless path.start_with? "/"
        Data::Scene.new(
          video_link: path,
          refresher: Refreshers::Spizoo.new(path, @cookies),
          **Data::Scene::LAZY
        )
      end

      def fetch(url)
        path = url.gsub(BASE_URI, "") # remove the base URL
        resp = handle_response!(return_raw: true) { self.class.get(path, follow_redirects: false) }
        Nokogiri::HTML(resp.body)
      end
    end
  end
end
