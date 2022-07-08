# frozen_string_literal: true

module AdultTimeDL
  module Utils
    def validate_download_filters!(file)
      default_download_filters = { skip_studios: [], skip_performers: [], skip_lesbian: [] }
      download_filters = FileUtils.read_yaml(file, default_download_filters)

      contract = DownloadFiltersContract.new.call(download_filters)

      unless contract.errors.empty?
        messages = []
        contract.errors.messages.each do |key|
          messages << "#{key.path.join(", ")} #{key.text}"
        end
        raise FatalError, "[INVALID DOWNLOAD FILTERS] #{messages.join(", ")}"
      end

      contract.to_h
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
