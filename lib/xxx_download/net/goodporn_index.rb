# frozen_string_literal: true

module XXXDownload
  module Net
    class GoodpornIndex < BaseIndex
      def initialize
        super

        self.class.base_uri BASE_URI
      end

      # @param [String] resource
      # @return [Array[Data::Scene]]
      def search_by_actor(resource)
        path = convert_resource_to_path(resource)
        all_scenes = fetch_all_scenes(path) do |doc|
          doc.css(".list-videos .item .thumb-link").map { |x| x["href"] }.compact
        end
        process_scenes(all_scenes)
      end

      # @param [String] url
      # @return [Array[Data::Scene]]
      def search_by_movie(url)
        all_scenes = fetch_all_scenes(url) do |doc|
          doc.css(".list-videos .item .thumb-link").map { |x| x["href"] }.compact
        end
        process_scenes(all_scenes)
      end

      # @param [String] resource
      # @return [String]
      def actor_name(resource)
        resource.slice!(-1) if resource.end_with?("/") # remove trailing slash if present
        resource.split("/").last.gsub("-", " ").titleize # remove the last part of the URL and convert to title case
      end

      def command(scene_data, url, _strategy)
        XXXDownload::Downloader::CommandBuilder.build_basic do |b|
          b.path(scene_data.file_name, config.download_dir, "mp4")
          b.url(url)
        end
      end

      private

      BASE_URI = "https://goodporn.to"
      TAG = "GOODPORN"

      # @param [String] resource can be a complete URL
      #     e.g. (https://goodporn.to/tags/alexa-grace/) or just the name (alexa grace)
      # @return [String] path to the resource
      #     e.g. /tags/alexa-grace/
      def convert_resource_to_path(resource)
        if resource.start_with?(BASE_URI)
          resource.gsub(BASE_URI, "").tap { |r| r << "/" unless r.end_with?("/") }
        else
          "/tags/#{resource.downcase.gsub(" ", "-")}/"
        end
      end

      def fetch_all_scenes(url, &block)
        scene_links = []
        page = 1
        loop do
          XXXDownload.logger.info "[#{TAG}] [FETCHING PAGE #{page}]"
          doc = fetch(url, page)
          if doc.nil?
            XXXDownload.logger.debug "[#{TAG}] [NO MORE SCENES]"
            break
          end

          scene_links.concat(block.call(doc))
          page += 1
        end
        scene_links
      end

      # @param [Array[String]] scene_urls
      # @return [Array[Data::Scene]]
      def process_scenes(scene_urls)
        scene_urls.map do |url|
          Data::Scene.new(
            video_link: url,
            refresher: Refreshers::GoodPorn.new(url),
            **Data::Scene::LAZY
          )
        end
      end

      def fetch(path, page = 1)
        XXXDownload.logger.trace "[#{TAG}] [FETCH] #{path} [PAGE: #{page}]"
        http_resp = handle_response!(return_raw: true) { self.class.get(path, query: { from: page }) }
        Nokogiri::HTML(http_resp.body)
      rescue XXXDownload::NotFoundError
        nil
      end
    end
  end
end
