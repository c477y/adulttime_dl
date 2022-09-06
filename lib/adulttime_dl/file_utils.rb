# frozen_string_literal: true

module AdultTimeDL
  module FileUtils
    class << self
      def read_file!(file)
        return File.read(file).strip if file && File.file?(file) && File.exist?(file)

        raise FatalError, "Unable to read file #{file}"
      end

      def read_yaml(file, default = {}, validate_type = nil)
        read_yaml!(file, validate_type)
      rescue FatalError
        default
      end

      def read_yaml!(file, validate_type)
        raise FatalError, "Unable to read yaml file #{file}" unless file && File.file?(file) && File.exist?(file)

        yaml = YAML.load_file(file)
        return yaml unless validate_type

        return yaml if yaml.is_a?(validate_type)

        raise FatalError, "#{file}: Invalid YAML contents. Was expecting #{validate_type}, but received #{yaml.class}"
      end
    end
  end
end
