# frozen_string_literal: true

module AdultTimeDL
  module Data
    class UnknownActorGenderScene < Scene
      def file_name
        initial_name = "#{title} [C] #{network_name}"
        final = safely_add_actors(initial_name, all_actors, prefix: "[A]")
        clean(final)
      end
    end
  end
end
