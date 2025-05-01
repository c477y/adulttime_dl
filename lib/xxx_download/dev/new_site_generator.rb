# frozen_string_literal: true

module XXXDownload
  module Dev
    class NewSiteGenerator < Thor::Group
      include Thor::Actions

      desc "Generates a new site downloader for xxx_download"

      source_root File.expand_path("templates", __dir__)

      argument :name, type: :string, desc: "Name of the site to generate. Provide in CamelCase"
      class_option :short_name, type: :string, required: true,
                                desc: "Short name of the site to invoke the download command"
      class_option :supports_streaming, default: false, type: :boolean,
                                        desc: "If the site supports download using streaming. " \
                                              "Keep this true if the site uses HLS streaming"
      class_option :supports_download, default: true, type: :boolean,
                                       desc: "If the site supports download using direct download"

      def self.exit_on_failure?
        true
      end

      def verify_name
        return if name.match?(/\A[A-Z][a-zA-Z]*\z/)

        say_error "Name should be in CamelCase"
        exit 1
      end

      def verify_unique_site
        exists = occurs_between_lines? "lib/xxx_download/contract/download_filters_contract.rb",
                                       /SUPPORTED_SITES = %w\[\n/,
                                       /\].freeze\n/,
                                       options[:short_name]
        return unless exists

        say_error "Site already exists in the contract contract/download_filters_contract.rb"
        exit 1
      end

      def generate_index
        template "site_index_template.rb.erb",
                 "lib/xxx_download/net/#{snake_name}_index.rb"
        inject_into_file("lib/xxx_download/data/config.rb",
                         after: "      MODULE_NAME = {\n") do
          "        \"#{options[:short_name]}\"     => \"#{name}\",\n"
        end

        inject_into_file "lib/xxx_download/contract/download_filters_contract.rb",
                         "        \"#{options[:short_name]}\",\n",
                         after: "      SUPPORTED_SITES = [\n",
                         force: true
        inject_into_file "lib/xxx_download/contract/download_filters_contract.rb",
                         "      # TODO: Sort these lines before you commit!\n",
                         before: "      SUPPORTED_SITES = [\n",
                         force: true

        inject_into_file "bin/docker_rspec",
                         "# TODO: Sort these lines before you commit!\n",
                         after: "export DOCKER_CLI_HINTS=false\n"

        inject_into_file "bin/docker_rspec",
                         "#{name.upcase}_COOKIE_STR=${#{name.upcase}_COOKIE_STR:-cookie}\n",
                         after: "LOG_LEVEL=${LOG_LEVEL:-extra}\n"

        inject_into_file "bin/docker_rspec",
                         "  -e #{name.upcase}_COOKIE_STR=\"$#{name.upcase}_COOKIE_STR\" \\\n",
                         after: "-e LOG_LEVEL=\"$LOG_LEVEL\" \\\n"
      end

      def generate_download_links
        if options[:supports_download]
          template "site_download_links_template.rb.erb",
                   "lib/xxx_download/net/#{snake_name}_download_links.rb"
        else
          inject_into_file "lib/xxx_download/data/config.rb",
                           "        #{options[:short_name]}\n",
                           after: "      DOWNLOADING_UNSUPPORTED_SITE = %w[\n",
                           force: true
          inject_into_file "lib/xxx_download/data/config.rb",
                           "      # TODO: Sort these lines before you commit!\n",
                           before: "      DOWNLOADING_UNSUPPORTED_SITE = %w[\n",
                           force: true
        end
      end

      def generate_streaming_links
        if options[:supports_streaming]
          template "site_streaming_links_template.rb.erb",
                   "lib/xxx_download/net/#{snake_name}_streaming_links.rb"
        else
          inject_into_file "lib/xxx_download/data/config.rb",
                           "        #{options[:short_name]}\n",
                           after: "      STREAMING_UNSUPPORTED_SITE = %w[\n",
                           force: true
          inject_into_file "lib/xxx_download/data/config.rb",
                           "      # TODO: Sort these lines before you commit!\n",
                           before: "      STREAMING_UNSUPPORTED_SITE = %w[\n",
                           force: true
        end
      end

      def generate_refresher
        template "site_refresher_template.rb.erb",
                 "lib/xxx_download/net/refreshers/#{snake_name}.rb"
      end

      def generate_index_specs
        template "site_index_spec_template.rb.erb",
                 "spec/xxx_download/net/#{snake_name}_index_spec.rb"
      end

      no_tasks do
        def snake_name
          Thor::Util.snake_case(name)
        end

        def occurs_between_lines?(file_path, start_pattern, end_pattern, search_string)
          start_found = false

          File.foreach(file_path) do |line|
            if line.match(start_pattern)
              start_found = true
            elsif line.match(end_pattern)
              break
            elsif start_found && line.include?(search_string)
              return true
            end
          end

          false
        end
      end
    end
  end
end
