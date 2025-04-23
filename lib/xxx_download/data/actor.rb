# frozen_string_literal: true

module XXXDownload
  module Data
    class Actor < Base
      GENDERS = Types::String.enum("male", "female", "unknown", "shemale")

      attribute :name, Types::String
      attribute :gender, GENDERS

      def self.unknown(name) = new(name: name.strip, gender: "unknown")
      def self.male(name) = new(name: name.strip, gender: "male")
      def self.female(name) = new(name: name.strip, gender: "female")
    end
  end
end
