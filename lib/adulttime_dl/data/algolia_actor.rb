# frozen_string_literal: true

module AdultTimeDL
  module Data
    class AlgoliaActor < Base
      GENDERS = Types::String.enum("male", "female")

      attribute :name, Types::String
      attribute :gender, GENDERS
    end
  end
end
