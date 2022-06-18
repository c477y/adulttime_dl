# frozen_string_literal: true

module AdultTimeDL
  module Data
    class StreamingLinks < Base
      attribute? "res_1080p", Types::String
      attribute? "res_720p", Types::String
      attribute? "res_576p", Types::String
      attribute? "res_480p", Types::String
      attribute? "res_432p", Types::String
    end

    def sd
      res_480p || res_432p || nil
    end

    def hd
      res_720p || res_576p || sd
    end

    def fhd
      res_1080p || hd
    end
  end
end
