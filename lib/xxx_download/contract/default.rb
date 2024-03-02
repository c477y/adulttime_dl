# frozen_string_literal: true

require "active_support/core_ext/object/deep_dup"

module XXXDownload
  module Contract
    module Default # rubocop:disable Metrics/ModuleLength
      DEFAULT_CONFIG = {
        c00: "Download filters are rules that skip downloading scenes",
        "download_filters" => {
          cn01: "newline",
          c01: "[List] Skip studios based on name",
          c02: "If any scene belongs to that studio, the scene will be skipped",
          c03: "e.g. ['Hot and Mean']",
          "skip_studios" => [],

          cn02: "newline",
          c04: "[List] Skip performers based on name",
          c05: "Do note that if you use specify a performer here and then try to download all scenes",
          c06: "of that performer by passing their URL in the (performers) list, all scenes will be",
          c07: "skipped",
          "skip_performers" => [],

          cn03: "newline",
          c08: "[List] Skip keywords in scene title OR in scene description",
          "skip_keywords" => [],

          cn04: "newline",
          c09: "[Integer] Oldest scene year to allow downloading",
          c10: "This filter is only applied if the site provides release year of the scene",
          "oldest_year" => 2010,

          cn05: "newline",
          c11: "[Boolean] Skip downloading scenes with only female actors",
          c12: "This only works with certain sites that provide gender information for performers",
          "skip_lesbian" => false,

          cn06: "newline",
          c13: "[String] Minimum duration of scene to download in MM:SS format",
          c14: "e.g. '10:00' for 10 minutes",
          "minimum_duration" => "10:00",

          cn07: "newline",
          c15: "[Boolean] Skip downloading scenes with trans-actors",
          c16: "This only works with certain sites that provide gender information for performers",
          "skip_trans" => true
        },

        cn06: "newline",
        c13: "[String] Path to a cookie file. Used only for sites that require membership",
        c14: "information. Use a browser extension to get a cookie file",
        c15: "If you are on mozilla, you can use https://addons.mozilla.org/en-GB/firefox/addon/cookies-txt/",
        "cookie_file" => "cookies.txt",

        cn07: "newline",
        c16: "[String] Name of file that tracks list of downloaded scenes",
        c17: "It is recommended you leave this as the default value",
        "store" => "adt_download_status.store",

        cn08: "newline",
        c18: "[String] Name of downloader tool to use. Currently supports youtube-dl and yt-dlp",
        c19: "Ensure that the downloader is available in your $PATH",
        "downloader" => "youtube-dl",

        cn09: "newline",
        c20: "[String] Directory to download scenes. '.' means current directory",
        "download_dir" => ".",

        cn10: "newline",
        c21: "[String] Resolution of scene to download. Accepts one of 'sd', 'hd', and 'fhd'",
        "quality" => "hd",

        cn11: "newline",
        c22: "[Number] Number of parallel download jobs",
        c23: "Do not set this number more than 5, otherwise you might run into rate limiting issues.",
        "parallel" => 1,

        cn12: "newline",
        c24: "[Boolean] Just log to console, doesn't download anything",
        c25: "Useful for test the download commands the app generates",
        "dry_run" => false,

        cn13: "newline",
        c26: "[String] Arguments to pass to external downloader",
        c27: "Check the documentation of youtube-dl or yt-dlp for details",
        c28: "e.g. this accelerates downloads using aria2",
        "downloader_flags" => "--external-downloader aria2c --external-downloader-args \"-j 8 -s 8 -x 8 -k 5M\"",

        cn17: "newline",
        c29: "[String] Hostname of Chrome DevTools Protocol server",
        c30: "Used if you are running the tool using Docker",
        "cdp_host" => nil,

        cn18: "newline",
        c31: "[List] Directories to search for a file before downloading it",
        "pre_download_search_dir" => [],

        cn14: "newline",
        "urls" => {
          c29: "[List] URLs of performer names that will be downloaded",
          "performers" => [],
          c30: "[List] URLs of movie names that will be downloaded",
          "movies" => [],
          c31: "[List] URLs of scene names that will be downloaded",
          "scenes" => [],
          c32: "[List] URLs of page that lists scenes",
          "page" => []
        },
        cn15: "newline",
        c33: "[OPTIONAL] These are site specific configuration only needed for some sites",
        "site_config" => {
          "blowpass" => {
            c34: "Get Algolia credentials from Web Console",
            "algolia_application_id" => nil,
            "algolia_api_key" => nil
          }
        },

        cn16: "newline",
        c35: "Configuration for stash app to prevent downloading duplicate scenes",
        c36: "At the moment, Stash App is used to prevent re-downloading a scene that's already",
        c37: "part of your library. Skip if you don't use stash app.",
        "stash_app" => {
          c38: "[String] URL path where your Stash App is hosted",
          c39: "e.g. http://localhost:9999",
          "url" => nil,
          c40: "[String] Optional token if your Stash App is password protected",
          "api_token" => nil
        }
      }.freeze

      DEFAULT_CONFIG_FILE = "config.yml"

      class << self
        def cleaned_config
          cloned_hash = DEFAULT_CONFIG.deep_dup
          filter_hash(cloned_hash).deep_transform_keys!(&:to_s)
        end

        private

        def filter_hash(hash)
          hash.each do |key, value|
            if key.to_s.match(/^c\d+$/) || key.to_s.match(/^cn\d+$/)
              hash.delete(key)
            elsif value.is_a?(Hash)
              filter_hash(value)
            end
          end
        end
      end
    end
  end
end
