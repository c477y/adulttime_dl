# frozen_string_literal: true

module AdultTimeDL
  module Data
    class Base < Dry::Struct
      transform_keys(&:to_sym)

      # resolve default types on nil
      # https://dry-rb.org/gems/dry-struct/1.0/recipes/#resolving-default-values-on-code-nil-code
      transform_types do |type|
        if type.default?
          type.constructor do |value|
            value.nil? ? Dry::Types::Undefined : value
          end
        else
          type
        end
      end
    end
  end
end


