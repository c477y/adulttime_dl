# frozen_string_literal: true

module XXXDownload
  module Data
    class PornVEScene < Scene
      def key
        title
      end

      def file_name
        clean(title)
      end
    end
  end
end
