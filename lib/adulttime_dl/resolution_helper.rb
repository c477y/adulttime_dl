# frozen_string_literal: true

module AdultTimeDL
  module ResolutionHelper
    FOUR_K_EXP = /\b(4K|2160p?)\b/i.freeze
    FHD_EXP = /\b(HD|1080p?)\b/i.freeze
    HD_EXP = /\b(HD|720p?|576p?)\b/i.freeze
    SD_EXP = /\b(HD|480p?|360p?)\b/i.freeze

    # @param [Hash] res_hash
    def matched_url(res_hash)
      res_hash.each_pair do |resolution_str, url|
        return url if resolution_match?(resolution_str)
      end
      nil
    end

    private

    def resolution_match?(resolution_str)
      case @config.quality
      when "fhd" then FHD_EXP.match?(resolution_str)
      when "hd" then HD_EXP.match?(resolution_str)
      when "sd" then SD_EXP.match?(resolution_str)
      else false
      end
    end
  end
end
