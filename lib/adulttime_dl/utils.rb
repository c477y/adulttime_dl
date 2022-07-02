# frozen_string_literal: true

module AdultTimeDL
  module Utils
    # @param [File] file
    # @param [String] key
    def load_yaml!(file, key)
      yaml = YAML.load_file(file)
      raise FatalError, "#{file}: Invalid YAML format" unless yaml
      raise FatalError, "#{file}: Missing #{key} key" unless yaml.key?(key)
      unless yaml[key].is_a?(Array) || yaml[key].nil?
        raise FatalError, "#{file}: Invalid key format. Was expecting Array, but received #{yaml[key].class}"
      end

      yaml[key] || []
    end
  end
end
