require "rails_helper"
require "support/mock_directory"

RSpec.describe LibraryScanJob do
  before :all do
    ActiveJob::Base.queue_adapter = :test
  end

  context "with files in various folders" do
    around do |ex|
      MockDirectory.create([
        "model_one/part_1.obj",
        "model_one/part_2.obj",
        "subfolder/model_two/part_one.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "can scan a library directory" do
      expect { described_class.perform_now(library) }.to change { library.models.count }.to(2)
      expect(library.models.map(&:path)).to contain_exactly("model_one", "subfolder/model_two")
    end

    it "queues up model scans" do
      expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(2).times
    end

    it "only scans models with changes on rescan" do
      model_one = create(:model, path: "model_one", library: library)
      ModelScanJob.perform_now(model_one)
      expect { described_class.perform_now(library) }.to have_enqueued_job(ModelScanJob).exactly(1).times
    end
  end

  context "with a thingiverse-style model folder" do
    around do |ex|
      MockDirectory.create([
        "thingiverse_model/files/part_one.stl",
        "thingiverse_model/images/preview.png",
        "thingiverse_model/README.txt"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "understands that it's a single model" do
      expect { described_class.perform_now(library) }.to change { library.models.count }.to(1)
      expect(library.models.map(&:path)).to contain_exactly("thingiverse_model")
    end
  end

  context "with folders that look like filenames" do
    around do |ex|
      MockDirectory.create([
        "wrong.stl/file.stl"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "does not include directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).not_to include File.join(library.path, "wrong.stl")
    end

    it "does include files within directories in file list" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "wrong.stl/file.stl")
    end
  end

  context "with a case sensitive filesystem", case_sensitive: true do
    around do |ex|
      MockDirectory.create([
        "model/file.obj",
        "model/file.OBJ",
        "model/file.Obj"
      ]) do |path|
        @library_path = path
        ex.run
      end
    end

    # rubocop:disable RSpec/InstanceVariable
    let(:library) { create(:library, path: @library_path) }
    # rubocop:enable RSpec/InstanceVariable

    it "detects lowercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.obj")
    end

    it "detects uppercase file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.OBJ")
    end

    it "detects mixed case file extensions" do
      expect(described_class.new.filenames_on_disk(library)).to include File.join(library.path, "model/file.Obj")
    end
  end
end
