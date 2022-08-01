# frozen_string_literal: true

require "selenium-webdriver"
require "webdrivers/chromedriver"

module AdultTimeDL
  module Net
    module BrowserSupport
      def cookie(url, cookie_str)
        default_options[:url] = url

        cookie_hash = HTTParty::CookieHash.new
        cookie_str.split(";").map(&:strip).each { |c| cookie_hash.add_cookies(c) }
        default_options[:cookie] = cookie_hash
      end

      def request(headless: false, &block)
        setup(headless)
        set_cookie if cookie_set?
        block.call(driver, wait)
      ensure
        teardown
      end

      def capture_links(video_link, play_button: nil, headless: false, ext: ".m3u8")
        request(headless: headless) do |web_driver, waiter|
          web_driver.intercept do |request, &continue|
            uri = URI.parse(request.url)
            links << request.url if uri.path.end_with?(ext)
            continue.call(request)
          rescue Selenium::WebDriver::Error::WebDriverError => e
            AdultTimeDL.logger.error "[INTERCEPTOR ERROR] #{e}"
          end
          AdultTimeDL.logger.debug "PROCESSING URL #{video_link}"

          web_driver.get(video_link)
          web_driver.find_element(**play_button).click if play_button
          waiter.until { links.length.positive? }
          AdultTimeDL.logger.debug "M3U8 URLS captured:"
          links.each do |url|
            AdultTimeDL.logger.debug "\t#{url}"
          end
        end
        links
      end

      def setup(headless)
        driver = if headless
                   Selenium::WebDriver.for(:chrome, capabilities: headless_capability)
                 else
                   Selenium::WebDriver.for :chrome
                 end
        default_options[:driver] = driver
      end

      def default_options
        @default_options ||= {}
      end

      def links
        @links ||= []
      end

      def driver
        default_options[:driver]
      end

      def wait
        @wait ||= Selenium::WebDriver::Wait.new(timeout: 20)
      end

      def teardown
        driver.close
        default_options[:driver] = nil
      end

      private

      def set_cookie
        driver.get(default_options[:url])
        default_options[:cookie].each_pair do |key, value|
          driver.manage.add_cookie(name: key, value: value)
        end
      end

      def cookie_set?
        default_options[:url] && default_options[:cookie]
      end

      def headless_capability
        Selenium::WebDriver::Remote::Capabilities.chrome(
          "goog:chromeOptions" => { "args" => ["--headless"] }
        )
      end
    end
  end
end
