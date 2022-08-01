# frozen_string_literal: true

module AdultTimeDL
  module Data
    class DownloadFilters < Base
      attribute :skip_studios, Types::CustomSet
      attribute :skip_performers, Types::CustomSet
      attribute :skip_lesbian, Types::Bool

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
        end
      end

      def blocked_performers(scene)
        scene.male_actors.select { |performer| blocked_performer?(performer) }.first
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
