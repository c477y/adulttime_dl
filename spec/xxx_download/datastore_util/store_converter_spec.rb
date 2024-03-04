# frozen_string_literal: true

require "rspec"
require "pstore"
require "yaml/store"

RSpec.describe XXXDownload::DatastoreUtil::StoreConverter, type: :file_support do
  let(:file) { "test.store" }
  let(:seed_data) { { "key" => "value" } }

  shared_context "seed data" do
    before { store.transaction { store["key"] = "value" } }
  end

  # Return the complete data in the store file in hash format
  # @param [String] file
  # @param [Object] store_klass Either {PStore} or {YAML::Store}
  def data(file, store_klass)
    store = store_klass.new(file)
    out = {}
    store.transaction do
      store.roots.each { |key| out[key] = store[key] }
    end
    out
  end

  describe ".export" do
    subject(:out_file) { described_class.new(file).export }

    context "with supported file types" do
      include_context "seed data"

      context "when store is a pstore file" do
        let(:store) { PStore.new(file) }
        it "converts the data" do
          expect(data(out_file, YAML::Store)).to eq(seed_data)
        end
      end

      context "when store is a yaml file" do
        let(:store) { YAML::Store.new(file) }
        it "returns the same file back" do
          expect(out_file).to eq(file)
        end
      end
    end

    context "when store is an invalid file" do
      before { File.write(file, "random random data") }

      it "raises an error" do
        expect { out_file }.to raise_error(XXXDownload::FatalError)
      end
    end
  end

  describe ".import" do
    subject(:out_file) { described_class.new(file).import }

    context "with supported file types" do
      include_context "seed data"

      context "when store is a pstore file" do
        let(:store) { PStore.new(file) }
        it "returns the same file back" do
          expect(out_file).to eq(file)
        end
      end

      context "when store is a yaml file" do
        let(:store) { YAML::Store.new(file) }
        it "converts the data" do
          expect(data(out_file, PStore)).to eq(seed_data)
        end
      end
    end

    context "when store is an invalid file" do
      before { File.write(file, "random random data") }

      it "raises an error" do
        expect { out_file }.to raise_error(XXXDownload::FatalError)
      end
    end
  end
end
