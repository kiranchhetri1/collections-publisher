require "spec_helper"

RSpec.describe PublishingAPINotifier do
  let(:publishing_api) { double(:publishing_api, put_content_item: nil) }

  before do
    CollectionsPublisher.services(:publishing_api, publishing_api)
  end

  describe "#publish(sector_presenter)" do
    let(:sector_hash) { double(:sector_hash) }
    let(:base_path) { double(:base_path) }
    let(:presenter) { double(:sector_presenter, render_for_publishing_api: sector_hash) }

    before do
      allow(sector_hash).to receive(:[]).with(:base_path).and_return(base_path)
    end

    it "sends a formatted version of the sector groupings to the publishing API" do
      PublishingAPINotifier.publish(presenter)

      expect(publishing_api).to have_received(:put_content_item).with(base_path, sector_hash)
    end
  end
end
