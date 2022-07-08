# frozen_string_literal: true

class DownloadFiltersContract < Dry::Validation::Contract
  json do
    required(:skip_studios).maybe(array[:string])
    required(:skip_performers).maybe(array[:string])
    required(:skip_lesbian).value(:bool)
    # required(:use_database).value(:bool)
    # required(:performers).maybe(array[:string])
    # required(:movies).maybe(array[:string])
  end
end
