# frozen_string_literal: true

require "selenium-webdriver"

module XXXDownload
  module Net
    # Experimental module that is capable of requesting authentication
    # when required, thus allowing the user to not get the cookies manually.
    module SiteAuthenticationHandler
      # @param [String] login_url
      # @param [Proc] block A block that receives the cookies and determines
      #   if the user has logged in
      # @return [Array[HTTP::Cookie], Nil]
      # noinspection RubyMismatchedReturnType
      def authenticate(login_url, &block)
        request do
          driver.get(login_url)
          wait.until { block.call(driver.manage.all_cookies) }

          driver.manage.all_cookies.map do |h|
            HTTP::Cookie.new(h[:name], h[:value],
                             path: h[:path],
                             domain: h[:domain],
                             expires: h[:expires]&.to_time,
                             secure: h[:secure],
                             httponly: h[:http_only])
          end
        end
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise FatalError, "Browser window was closed"
      end

      private

      def request(&block)
        setup
        block.call(driver, wait)
      ensure
        teardown
      end

      def setup
        options = Selenium::WebDriver::Chrome::Options.new

        if XXXDownload.config.cdp_host.present?
          options.add_argument("remote-allow-origins=*")
          default_options[:driver] = Selenium::WebDriver.for(:remote, url: XXXDownload.config.cdp_host, options:)
          return default_options[:driver]
        end

        default_options[:driver] = Selenium::WebDriver.for(:chrome, options:)
      end

      def teardown
        driver&.close
        default_options[:driver] = nil
        nil
      rescue Selenium::WebDriver::Error::NoSuchWindowError => e
        XXXDownload.logger.warn "[BROWSER CLOSED] #{e.message}"
      end

      def driver
        default_options[:driver]
      end

      def wait
        @wait ||= Selenium::WebDriver::Wait.new(timeout: 1_000)
      end

      def default_options
        @default_options ||= {}
      end
    end
  end
end
