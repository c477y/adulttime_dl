# frozen_string_literal: true

module AdultTimeDL
  module Net
    # This is used by sites that do not support direct downloads at all
    # or streaming is the ONLY way downloading is implemented
    class NOOPDownloadLinks
      def fetch(_scene_data)
        nil
      end
    end
  end
end
