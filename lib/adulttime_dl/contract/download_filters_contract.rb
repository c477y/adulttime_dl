# frozen_string_literal: true

class DownloadFiltersContract < Dry::Validation::Contract
  json do
    required(:skip_studios).maybe(array[:string])
    required(:skip_performers).maybe(array[:string])
    required(:skip_lesbian).value(:bool)
    required(:cookie_file).value(:string)
    required(:store).value(:string)
    required(:downloader).value(:string)
    required(:quality).value(:string)
  end

  rule(:cookie_file) do
    key.failure("file does not exist or cannot be read") unless File.file?(value) && File.exist?(value)
  end
end
