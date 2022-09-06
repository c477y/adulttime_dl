# frozen_string_literal: true

module AdultTimeDL
  module Net
    class ArchAngelIndex < BaseIndex
      ARCH_ANGEL_VIDEO = "archangelvideo.com"
      ARCH_ANGEL_WORLD = "archangelworld.com"

      def search_by_actor(url)
        if url.include?(ARCH_ANGEL_VIDEO)
          doc = fetch(url)

          # Not sure if ARCH_ANGEL_VIDEO supports pagination
          ArchAngelVideoIndex.parse_page(doc)
        elsif url.include?(ARCH_ANGEL_WORLD)
          current_page_doc = fetch(url)
          scenes = []
          scenes.concat(ArchAngelWorldIndex.parse_page(current_page_doc))

          pages = ArchAngelWorldIndex.pages(url, current_page_doc)
          pages.map do |m_url|
            m_page = fetch(m_url)
            scenes.concat(ArchAngelWorldIndex.parse_page(m_page))
          end
          scenes
        else
          AdultTimeDL.logger.error "UNHANDLED URL #{url}"
          []
        end
      end

      def search_by_movie(url)
        if url.include?(ARCH_ANGEL_VIDEO)
          doc = fetch(url)
          ArchAngelVideoIndex.parse_page(doc)
        elsif url.include?(ARCH_ANGEL_WORLD)
          doc = fetch(url)
          ArchAngelWorldIndex.parse_page(doc)
        else
          AdultTimeDL.logger.error "UNHANDLED URL #{url}"
          []
        end
      end

      def search_by_all_scenes(url)
        if url.include?(ARCH_ANGEL_VIDEO)
          doc = fetch(url)
          [ArchAngelVideoIndex.make_scene_data_from_scene(doc, url)]
        elsif url.include?(ARCH_ANGEL_WORLD)
          doc = fetch(url)
          [ArchAngelWorldIndex.make_scene_data_from_scene(doc, url)]
        else
          AdultTimeDL.logger.error "UNHANDLED URL #{url}"
          nil
        end
      end

      private

      def fetch(url)
        http_resp = HTTParty.get(url,
                                 headers: headers,
                                 follow_redirects: false,
                                 logger: AdultTimeDL.logger,
                                 log_level: :debug)
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

