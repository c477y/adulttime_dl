# frozen_string_literal: true

module XXXDownload
  module Data
    class DownloadFilters < Base
      attribute :skip_studios, Types::CustomSet
      attribute :skip_performers, Types::CustomSet
      attribute :skip_lesbian, Types::Bool
      attribute :skip_trans, Types::Bool
      attribute :skip_keywords, Types::CustomArray
      attribute :oldest_year, Types::Integer
      attribute :minimum_duration, Types::String

      # @param [Scene] scene
      def skip?(scene) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        if scene.lesbian? && skip_lesbian?
          XXXDownload.logger.info "[SKIP LESBIAN] #{scene.file_name}"
          true
        elsif scene.trans? && skip_trans?
          XXXDownload.logger.info "[SKIP TRANS] #{scene.file_name}"
          true
        elsif skip_studios.member?(scene.network_name.downcase.gsub(/\W+/i, ""))
          XXXDownload.logger.info "[SKIP NETWORK] [#{scene.network_name}] #{scene.file_name}"
          true
        elsif (skip, performer = performer_blocked?(scene)) && skip
          XXXDownload.logger.info "[SKIP PERFORMER] [#{performer}] #{scene.file_name}"
          true
        elsif (skip, kw = keyword_blocked?(scene)) && skip
          XXXDownload.logger.info "[SKIP KEYWORD] [#{kw}] #{scene.file_name}"
          true
        elsif (skip, year = minimum_year?(scene)) && skip
          XXXDownload.logger.info "[SKIP OLDEST_YEAR] [#{year} < #{oldest_year}] #{scene.file_name}"
          true
        elsif (skip, duration = minimum_duration?(scene)) && skip
          XXXDownload.logger.info "[SKIP MINIMUM_DURATION] [#{duration} < #{minimum_duration}] #{scene.file_name}"
          true
        else
          false
        end
      end

      private

      alias skip_lesbian? skip_lesbian
      alias skip_trans? skip_trans

      def minimum_year?(scene)
        return [false, 0] unless oldest_year && scene.release_date

        time = Time.strptime(scene.release_date, "%Y-%m-%d")
        [time.year < oldest_year, time.year]
      rescue ArgumentError
        raise XXXDownload::FatalError, "Invalid date format(#{scene.release_date}) for #{scene.title}. " \
                                       "Expected in YYYY-MM-DD format"
      end

      def minimum_duration?(scene)
        return [false, "00:00"] unless minimum_duration && scene.duration

        scene_duration_t = duration_to_seconds(scene.duration)
        minimum_duration_t = duration_to_seconds(minimum_duration)
        [scene_duration_t < minimum_duration_t, scene.duration]
      rescue ArgumentError
        raise XXXDownload::FatalError, "Invalid duration format(#{scene.duration}) for #{scene.title}. " \
                                       "Expected in MM:SS or HH:MM:SS format"
      end

      def duration_to_seconds(duration)
        parts = duration.split(":").map(&:to_i)
        case parts.size
        when 2
          (parts[0] * 60) + parts[1] # MM:SS format
        when 3
          (parts[0] * 3600) + (parts[1] * 60) + parts[2] # HH:MM:SS format
        else
          raise ArgumentError, "Invalid duration format"
        end
      end

      def keyword_blocked?(scene)
        keyword = skip_keywords.find do |kw|
          [scene.title, scene.network_name, *scene.tags].find { |x| x.downcase.gsub(/\W+/i, "").include?(kw) }
        end
        [keyword.present?, keyword]
      end

      def performer_blocked?(scene)
        performer = scene.all_actors.select do |p|
          skip_performers.member?(p.downcase.gsub(/\W+/i, ""))
        end.first
        [performer.present?, performer]
      end
    end
  end
end
