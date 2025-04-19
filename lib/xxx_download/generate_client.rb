# frozen_string_literal: true

module XXXDownload
  class GenerateClient
    def initialize(config)
      @config = config
    end

    def start!
      actors = config.generator.send(config.object.to_sym)
      file = filename(config.object)
      File.write(file, actors.to_yaml)
      XXXDownload.logger.info "#{config.object} data generated to #{file}"
    end

    private

    attr_reader :config

    def filename(object_name)
      "generated_#{object_name}_#{DateTime.now.strftime("%s")}.yml"
    end
  end
end
