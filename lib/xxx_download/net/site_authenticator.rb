# frozen_string_literal: true

module XXXDownload
  module Net
    class SiteAuthenticator
      include SiteAuthenticationHandler

      def initialize(login_url)
        @login_url = login_url
        wait_timeout 1_000
      end

      TAG = "SITE_AUTHENTICATOR"

      #
      # @param [Boolean] force_request If true, authenticator will open a browser to re-authenticate user
      # @param [String] cookie_key Check if a user has logged in by checking the presence of a single cookie
      # @param [Proc] block Optional block if you want to pass your own authentication check logic
      # @return [String] cookie string
      def request_cookie(force_request: false, cookie_key: nil, &)
        if force_request
          XXXDownload.logger.info "[#{TAG}] Session cookies are requested. Please use your credentials to login again."
          request_cookies_from_browser(cookie_key, &)
        elsif XXXDownload.config.cookie.present?
          XXXDownload.logger.trace "[#{TAG}] Using persisted cookies from config/previous session"
          XXXDownload.config.cookie
        elsif !logged_in?
          request_cookies_from_browser(cookie_key, &)
        end
      end

      private

      attr_reader :login_url

      def request_cookies_from_browser(cookie_key, &block)
        XXXDownload.logger.info "[#{TAG}] Opening browser to authenticate session"
        # Attempt to authenticate
        cookies_arr = if cookie_key.present?
                        authenticate(login_url) { |cookies| user_logged_in?(cookies, cookie_key) }
                      else
                        raise ArgumentError, "Block must be given when no cookie_key is provided" unless block_given?

                        authenticate(login_url) { |cookies| block.call(cookies) }
                      end

        # Persist the cookies for future use
        XXXDownload.logger.extra "[#{TAG}] Got cookies #{cookies_arr}"
        XXXDownload.config.store_cookies(cookies_arr)
        cookie = HTTP::Cookie.cookie_value(cookies_arr)
        XXXDownload.logger.extra "[#{TAG}] Set session cookies #{cookie}"
        cookie
      end

      def logged_in?
        @cookies ||= []
        @cookies.length.positive?
      end

      #
      # Successful logins should return cookies reserved for that session
      # Checking the presence of the key should mean the user has logged in
      #
      # @param cookies [Array[Hash]] cookies a list of selenium cookies
      # @return [Boolean]
      def user_logged_in?(cookies, cookie_key)
        XXXDownload.logger.extra "[#{TAG}] Checking cookies for login status"
        return false if cookies.nil? || cookies.empty?

        cookies.any? { |x| x[:name]&.starts_with?(cookie_key) }
      end
    end
  end
end
