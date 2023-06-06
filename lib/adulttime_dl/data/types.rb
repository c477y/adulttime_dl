# frozen_string_literal: true

module AdultTimeDL
  module Data
    module Types
      include Dry.Types()

      CustomSet = Types.Constructor(Set) do |values|
        if values
          clean_values = values.map(&:downcase).map { |s| s.gsub(/\W+/i, "") }
          Set.new(clean_values)
        else
          Set.new([])
        end
      end

      CustomArray = Types.Constructor(Array) do |values|
        if values
          values.map(&:downcase).map { |s| s.gsub(/\W+/i, "") }
        else
          []
        end
      end
    end
  end
end
