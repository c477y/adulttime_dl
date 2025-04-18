# frozen_string_literal: true

module XXXDownload
  module Data
    class CumLouderScene < Net::Base
      attr_reader :url, :doc

      include HTTParty

      def initialize(url, _cookie)
        @url = url
        super()
      end

      def process
        resp = handle_response!(self.class.get(url, headers: default_headers), return_raw: true)
        @doc = Nokogiri::HTML(resp.body)
        scene = {}.tap do |h|
          h[:title] = title
          h[:actors] = actors
          h[:network_name] = network_name
          h[:downloading_links] = downloading_links
          h[:collection_tag] = "CL"
          h[:is_streamable] = false # Force use download strategy
        end
        Data::Scene.new(scene)
      end

      def title
        doc.css(".video-top h1").text.strip
      end

      def actors
        doc.css(".pornstars .pornstar-link")
           .map { |x| x.text.strip }
           .map { |actor| Data::Actor.new(name: actor, gender: "unknown") }
      end

      def network_name
        "CumLouder"
      end

      def downloading_links
        Data::StreamingLinks.with_single_url(doc.css("#download-url").attr("href").value)
      end
    end
  end
end
