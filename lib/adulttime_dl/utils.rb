# frozen_string_literal: true

module AdultTimeDL
  module Utils
     def valid_file?(file)
      file && File.file?(file) && File.exist?(file)
    end

    # @param [String] site
    # @return [String (frozen)]
    def base_url(site)
      case site
      when "adulttime" then Constants::ADULTTIME_BASE_URL
      when "ztod" then Constants::ZTOD_BASE_URL
      else raise FatalError, "received unexpected site name #{site}"
      end
    end
  end
end
