# frozen_string_literal: true

require "selenium-webdriver"
require "webdrivers/chromedriver"

module AdultTimeDL
  module Net
    module BrowserSupport
      def self.included(base)
        base.extend ClassMethods
        base.instance_variable_set(:@default_options, {})
      end

      module ClassMethods
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
          close_browser
        end

        attr_reader :default_options

        def setup(headless)
          driver = if headless
                     Selenium::WebDriver.for(:chrome, capabilities: headless_capability)
                   else
                     Selenium::WebDriver.for :chrome
                   end
          default_options[:driver] = driver
        end

        def driver
          default_options[:driver]
        end

        def wait
          default_options[:wait] = Selenium::WebDriver::Wait.new(timeout: 20)
        end

        def close_browser
          driver.close
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
end
