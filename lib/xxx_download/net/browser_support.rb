# frozen_string_literal: true

require "selenium-webdriver"

module XXXDownload
  module Net
    module BrowserSupport
      def cookie(url, cookie_str)
        default_options[:url] = url

        cookie_hash = HTTParty::CookieHash.new
        cookie_str.split(";").map(&:strip).each do |c|
          XXXDownload.logger.trace "[BROWSER COOKIE] Add #{c}"
          cookie_hash.add_cookies(c)
        end
        default_options[:cookie] = cookie_hash
      end

      def wait_timeout(seconds) = default_options[:wait_timeout] = seconds
      def links = @links ||= []
      def reset_links = @links.clear
      def driver = default_options[:driver]
      def wait = @wait ||= Selenium::WebDriver::Wait.new(timeout: default_options[:wait_timeout])
      def start_browser = setup && set_cookie

      def request(teardown_browser: true, add_cookies: true, &block)
        setup
        set_cookie if cookie_set? && add_cookies
        block.call
      ensure
        teardown if teardown_browser
      end

      def capture_links(video_link, play_button: nil, ext: ".m3u8")
        request do
          driver.intercept do |request, &continue|
            uri = URI.parse(request.url)
            links << url if uri.path&.end_with?(ext)
            continue.call(request)
          rescue Selenium::WebDriver::Error::WebDriverError => e
            XXXDownload.logger.error "[INTERCEPTOR ERROR] #{e}"
          end

          XXXDownload.logger.debug "PROCESSING URL #{video_link}"
          driver.get(video_link)
          driver.find_element(**play_button).click if play_button

          wait.until { links.length.positive? }

          XXXDownload.logger.debug "M3U8 URLS captured:"
          links.each { |url| XXXDownload.logger.debug "\t#{url}" }
        end
        links
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise FatalError, "Browser window was closed"
      end

      def setup
        return if default_options[:driver]

        options = Selenium::WebDriver::Chrome::Options.new

        if XXXDownload.config.cdp_host.present?
          options.add_argument("--remote-allow-origins=*")
          options.add_argument("--remote-debugging-port=9222")

          default_options[:driver] ||= Selenium::WebDriver.for(:remote,
                                                               url: XXXDownload.config.cdp_host,
                                                               options:)
          return default_options[:driver]
        end

        # options.add_argument("--headless") if XXXDownload.logger.level > XXXDownload::CustomLogger::DEBUG
        default_options[:driver] ||= Selenium::WebDriver.for(:chrome, options:)
      end

      def teardown
        driver&.close
        default_options[:driver] = nil
        nil
      rescue Selenium::WebDriver::Error::NoSuchWindowError => e
        XXXDownload.logger.warn "[BROWSER CLOSED] #{e.message}"
      end

      private

      def set_cookie
        driver.get(default_options[:url])
        default_options[:cookie].each_pair do |key, value|
          driver.manage.add_cookie(name: key, value:)
        end
        XXXDownload.logger.debug "[ADD COOKIE] #{default_options[:url]}"
      end

      def cookie_set? = default_options[:url] && default_options[:cookie]
      def default_options = @default_options ||= { wait_timeout: 20 }
    end
  end
end
