require 'rails_helper'

RSpec.describe TopicPresenter do
  describe "rendering for publishing-api" do
    let(:parent) { build(:topic, :slug => 'oil-and-gas') }
    let(:topic) {
      topic = build(:topic, {
        :parent => parent,
        :slug => 'offshore',
        :title => 'Offshore',
        :description => 'Oil rigs, pipelines etc.',
      })
      topic.valid? # Cause before_validation hooks to run
      topic
    }
    let(:presenter) { TopicPresenter.new(topic) }
    let(:presented_data) { presenter.render_for_publishing_api }

    it "returns the base_path for the browse page" do
      expect(presenter.base_path).to eq("/oil-and-gas/offshore")
    end

    it "includes the base fields" do
      expect(presented_data).to include({
        :content_id => topic.content_id,
        :format => 'topic',
        :title => 'Offshore',
        :description => 'Oil rigs, pipelines etc.',
        :need_ids => [],
        :publishing_app => 'collections-publisher',
        :rendering_app => 'collections',
        :redirects => [],
        :update_type => "major",
      })
    end

    it "sets public_updated_at based on the browse page update time" do
      Timecop.travel 3.hours.ago do
        topic.save!
      end

      expect(presented_data[:public_updated_at]).to eq(topic.updated_at)
    end

    describe "details hash" do
      before :each do
        topic.save!
      end

      it "should contain an empty groups array with no curated lists" do
        expect(presented_data[:details]).to eq({
          :groups => [],
        })
      end

      it "provides the curated lists ordered by their index" do
        oil_rigs = create(:list, :topic => topic, :index => 1, :name => 'Oil rigs')
        allow(oil_rigs).to receive(:tagged_list_items).and_return([
          OpenStruct.new(:api_url => "http://api.example.com/oil-rig-safety-requirements"),
          OpenStruct.new(:api_url => "http://api.example.com/oil-rig-staffing"),
        ])
        piping = create(:list, :topic => topic, :index => 0, :name => 'Piping')
        allow(piping).to receive(:tagged_list_items).and_return([
          OpenStruct.new(:api_url => "http://api.example.com/undersea-piping-restrictions"),
        ])
        allow(topic).to receive(:lists).and_return(double(:ordered => [piping, oil_rigs]))

        expect(presented_data[:details]).to eq({
          :groups => [
            {
              :name => "Piping",
              :contents => [
                "http://api.example.com/undersea-piping-restrictions",
              ]
            },
            {
              :name => "Oil rigs",
              :contents => [
                "http://api.example.com/oil-rig-safety-requirements",
                "http://api.example.com/oil-rig-staffing",
              ]
            }
          ]
        })
      end
    end

    describe "routing" do
      it "includes routes for latest, and email_signups in addition to base route" do
        expect(presented_data[:routes]).to eq([
          {:path => "/oil-and-gas/offshore", :type => "exact"},
          {:path => "/oil-and-gas/offshore/latest", :type => "exact"},
          {:path => "/oil-and-gas/offshore/email-signup", :type => "exact"},
          {:path => "/oil-and-gas/offshore/email-signups", :type => "exact"},
        ])
      end

      it "only includes the base route for a top-level topic" do
        data = TopicPresenter.new(parent).render_for_publishing_api

        expect(data[:routes]).to eq([
          {:path => "/oil-and-gas", :type => "exact"},
        ])
      end
    end

    it "has no links" do
      expect(presented_data[:links]).to eq({})
    end
  end
end