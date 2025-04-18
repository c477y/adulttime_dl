# frozen_string_literal: true

module XXXDownload
  module Net
    class ScoreGroupIndex < BaseIndex
      def search_by_actor(url)
        url = clean_url(url)
        doc = fetch(url)
        base_url = base_url(url)
        doc.css("#model-scenes .row .box").map do |scene|
          make_scene_data(scene, base_url)
        end
      end

      def search_by_movie(url)
        XXXDownload.logger.error "Scorepass does not have any DVD, skipping #{url}"
        []
      end

      def search_by_all_scenes(_url)
        raise "Not implemented"
      end

      private

      def base_url(url)
        uri = URI.parse(url)
        "#{uri.scheme}://#{uri.host}"
      end

      def clean_url(url)
        uri = URI.parse(url)
        uri = append_path(uri, { %r{scenes/?$}x => "scenes/" })
        uri = merge_query(uri, { "type" => "Video", "class" => "xxx" }, { "page" => "1" })
        uri.to_s
      end

      def append_path(uri, replacement_opt = {})
        replacement_opt.each_pair do |re, replacement|
          uri.path = File.join(uri.path.gsub(%r{/$}, ""), replacement) unless uri.path&.match?(re)
        end
        uri
      end

      def merge_query(uri, override = {}, optional = {})
        query_hash = uri.query.nil? ? {} : URI.decode_www_form(uri.query).to_h
        query_hash.merge!(override)
        final = optional.merge(query_hash)
        uri.query = URI.encode_www_form(final)
        uri
      end

      def make_scene_data(doc, base_url)
        Data::UnknownActorGenderScene.new(
          title: title(doc),
          actors: actors(doc),
          release_date: nil,
          network_name: "ScoreGroup",
          download_sizes: [], # exclusive to algolia scenes
          is_streamable: false,
          video_link: File.join(base_url, video_link(doc))
        )
      end

      def title(doc)
        doc.css(".i-title").text.strip
      end

      def actors(doc)
        doc.css(".i-model")
           .map(&:text)
           .map(&:strip)
           .map { |x| Data::Actor.new(name: x, gender: "unknown") }
      end

      def video_link(doc)
        doc.css("a").map { |link| link["href"] }.compact.first
      end

      def fetch(url)
        http_resp = HTTParty.get(url, headers:, follow_redirects: false)
        resp = handle_response!(http_resp, return_raw: true)
        Nokogiri::HTML(resp.body)
      end

      def headers
        default_headers.merge(
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          "DNT" => "1",
          "Cookie" => config.cookie
        )
      end
    end
  end
end
