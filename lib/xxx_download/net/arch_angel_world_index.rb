# frozen_string_literal: true

module XXXDownload
  module Net
    class ArchAngelWorldIndex
      class << self
        # @param [String] current_url
        # @param [Nokogiri::HTML4::Document] doc
        def pages(current_url, doc)
          all = doc.css(".pagination ul a[href]").map { _1["href"] }
          return [] if all.empty?

          all.reject! { |x| x == current_url }
          all.pop(2)
          XXXDownload.logger.debug "Detected #{all.length} pages in #{current_url}"
          all
        end

        # @param [Nokogiri::HTML4::Document] doc
        def parse_page(doc)
          doc.css(".section .items .item-episode").map do |m_doc|
            make_scene_data(m_doc)
          end
        end

        def make_scene_data_from_scene(doc, url)
          Data::UnknownActorGenderScene.new(
            title: doc.css(".content .item-info h4").children.first.text&.strip,
            actors: doc.css(".content .item-info h5")
                       .first.css("a")
                       .map(&:text).map(&:strip).map { |x| Data::Actor.new(name: x, gender: "unknown") },
            network_name: "ArchAngel",
            video_link: url
          )
        end

        def make_scene_data(doc)
          Data::UnknownActorGenderScene.new(
            title: title(doc),
            actors: actors(doc),
            network_name: "ArchAngel",
            video_link: video_link(doc)
          )
        end

        def title(doc)
          doc.css(".item-info .item-title-row .right h3 a").text&.strip
        end

        def actors(doc)
          doc.css(".fake-h5 a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end

        def video_link(doc)
          doc.css(".item-info .item-title-row .right h3 a").map { |x| x["href"] }.first
        end
      end
    end
  end
end
