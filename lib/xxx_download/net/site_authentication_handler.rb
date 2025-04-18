# frozen_string_literal: true

require "selenium-webdriver"

module XXXDownload
  module Net
    # Experimental module that is capable of requesting authentication
    # when required, thus allowing the user to not get the cookies manually.
    module SiteAuthenticationHandler
      include BrowserSupport

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
    end
  end
end
