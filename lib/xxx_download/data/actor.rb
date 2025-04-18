# frozen_string_literal: true

module XXXDownload
  module Data
    class Actor < Base
      GENDERS = Types::String.enum("male", "female", "unknown", "shemale")

      attribute :name, Types::String
      attribute :gender, GENDERS

      def self.unknown(name) = new(name:, gender: "unknown")
      def self.male(name) = new(name:, gender: "male")
      def self.female(name) = new(name:, gender: "female")
    end
  end
end
