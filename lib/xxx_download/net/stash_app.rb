# frozen_string_literal: true

require "base64"

# require "xxx_rename/errors"
# require "xxx_rename/integrations/base"
# require "xxx_rename/file_utilities"

module XXXDownload
  module Net
    class StashAPIError < StandardError
      def initialize(errors)
        @errors = errors
        super(message)
      end

      def message
        msg = "Stash API returned error:\n"
        @errors.each do |e|
          s = "\tMESSAGE #{e["message"]}\n"
          s += "\tOPERATION #{e["path"]} \n"
          msg += s
        end
        msg
      end
    end

    class StashApp < Base
      GRAPHQL_ENDPOINT = "/graphql"
      TAG = "STASH_APP"

      def initialize(config)
        @config = config
        super()

        raise FatalError, "Stash App requires 'url'. Check your configuration." if config.stash_app.url.nil?

        self.class.default_options.update(verify: false)
        self.class.base_uri(config.stash_app.url)
        self.class.headers("Content-Type" => "application/json")
        self.class.default_timeout(10)
        self.class.open_timeout(10)
        self.class.read_timeout(10)
      end

      def setup_credentials!
        register_api_key(stash_app_config.api_token) if api_key_provided?

        validate_credentials!
      end

      # @param [Data::Scene] scene_data
      def scene(scene_data)
        all_first_names = scene_data.all_actors(false).map { |x| x.split.first }.join(" ")
        query = "#{scene_data.title} #{all_first_names}"
        XXXDownload.logger.debug "[#{TAG} FIND_SCENE QUERY] #{query}"
        response = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body: find_scene_body(query)) }
        result = response.dig("data", "findScenes", "scenes")&.first
        XXXDownload.logger.ap result, :extra
        result
      end

      private

      attr_reader :config

      def find_scene_body(title)
        {
          operationName: "FindScenes",
          variables: {
            filter: {
              q: title.to_s,
              page: 1,
              per_page: 40
            }
          },
          query: <<~GRAPHQL
            query FindScenes($filter: FindFilterType, $scene_filter: SceneFilterType, $scene_ids: [Int!]) {
              findScenes(filter: $filter, scene_filter: $scene_filter, scene_ids: $scene_ids) {
                scenes {
                  title
                  files {
                    path
                  }
                }
              }
            }
          GRAPHQL
        }.to_json
      end

      def register_api_key(api_token)
        @api_key_set = true
        self.class.headers "ApiKey" => api_token
      end

      def api_key_provided?
        stash_app_config.api_token.to_s.is_a?(String)
      end

      def validate_credentials!
        body = {
          operationName: "Version",
          query: <<~GRAPHQL
            query Version {
              version {
                version
              }
            }
          GRAPHQL
        }.to_json

        resp = handle_response! { self.class.post(GRAPHQL_ENDPOINT, body:) }
        resp.dig("data", "version", "version")
      end

      def stash_app_config
        config.stash_app
      end
    end
  end
end
