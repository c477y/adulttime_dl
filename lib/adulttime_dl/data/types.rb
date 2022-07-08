# frozen_string_literal: true

module AdultTimeDL
  module Data
    module Types
      include Dry.Types()

      CustomSet = Types.Constructor(Set) do |values|
        if values
          AdultTimeDL.logger.info values.join(", ").to_s
          clean_values = values.map(&:downcase).map { |s| s.gsub(/\W+/i, "") }
          Set.new(clean_values)
        else
          Set.new([])
        end
      end
    end
  end
end
