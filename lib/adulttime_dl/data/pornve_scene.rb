# frozen_string_literal: true

module AdultTimeDL
  module Data
    class PornVEScene < Scene
      def file_name
        clean(title)
      end
    end
  end
end
