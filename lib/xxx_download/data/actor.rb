# frozen_string_literal: true

module XXXDownload
  module Data
    class Actor < Base
      GENDERS = Types::String.enum("male", "female", "unknown", "shemale")

      attribute :name, Types::String
      attribute :gender, GENDERS
    end
  end
end
