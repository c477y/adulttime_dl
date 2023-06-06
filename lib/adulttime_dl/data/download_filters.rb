# frozen_string_literal: true

module AdultTimeDL
  module Data
    class DownloadFilters < Base
      attribute :skip_studios, Types::CustomSet
      attribute :skip_performers, Types::CustomSet
      attribute :skip_lesbian, Types::Bool
      attribute :skip_keywords, Types::CustomArray
      attribute? :oldest_year, Types::Integer.optional

      # @param [Scene] scene
      def skip?(scene)
        if scene.lesbian? && skip_lesbian?
          AdultTimeDL.logger.info "[SKIP_LESBIAN] #{scene.file_name}"
          true
        elsif skip_studios.member?(scene.network_name.downcase.gsub(/\W+/i, ""))
          AdultTimeDL.logger.info "[SKIPPING NETWORK #{scene.network_name}] #{scene.file_name}"
          true
        elsif (performer = blocked_performers(scene))
          AdultTimeDL.logger.info "[SKIPPING PERFORMER #{performer}] #{scene.file_name}"
          true
        elsif (kw = blocked_keywords(scene))
          AdultTimeDL.logger.info "[SKIPPING KEYWORD #{kw}] #{scene.file_name}"
          true
        elsif oldest_year && scene.release_date
          time = Time.strptime(scene.release_date, "%Y-%m-%d")
          if time.year < oldest_year
            AdultTimeDL.logger.info "[SKIPPING OLDEST_YEAR #{time.year} < #{oldest_year}] #{scene.file_name}"
            true
          end
        else
          false
        end
      end

      def blocked_keywords(scene)
        skip_keywords.find do |kw|
          [scene.title, scene.network_name].find { |x| x.downcase.gsub(/\W+/i, "").include?(kw) }
        end
      end

      def blocked_performers(scene)
        scene.all_actors.select { |performer| blocked_performer?(performer) }.first
      end

      def blocked_performer?(performer)
        skip_performers.member?(performer.downcase.gsub(/\W+/i, ""))
      end

      def skip_lesbian?
        skip_lesbian
      end
    end
  end
end
