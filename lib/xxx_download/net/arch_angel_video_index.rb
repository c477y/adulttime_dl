# frozen_string_literal: true

module XXXDownload
  module Net
    class ArchAngelVideoIndex
      class << self
        # @param [Nokogiri::HTML4::Document] doc
        # @return [Array]
        def parse_page(doc)
          doc.css(".items .item").map do |m_doc|
            make_scene_data(m_doc)
          end
        end

        def make_scene_data(doc)
          Data::UnknownActorGenderScene.new(
            title: doc.css(".item-thumb span").text.strip,
            actors: actors(doc),
            network_name: "ArchAngel",
            video_link: doc.css(".item-thumb a").map { |link| link["href"] }.compact.first
          )
        end

        def make_scene_data_from_scene(doc, url)
          Data::UnknownActorGenderScene.new(
            title: doc.css(".title h2").first&.text&.strip,
            actors: doc.css(".info p a").map(&:text).map(&:strip).map do |x|
                      Data::Actor.new(name: x, gender: "unknown")
                    end,
            network_name: "ArchAngel",
            video_link: url
          )
        end

        def actors(doc)
          doc.css("p a")
             .map(&:text)
             .map(&:strip)
             .map { |x| Data::Actor.new(name: x, gender: "unknown") }
        end
      end
    end
  end
end
