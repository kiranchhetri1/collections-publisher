require 'rails_helper'

RSpec.describe ReviewController do
  describe "#submit_for_2i" do
    let(:step_by_step_page) { create(:draft_step_by_step_page) }

    before do
      allow(Services.publishing_api).to receive(:lookup_content_id)
    end

    describe "submit for 2i" do
      describe "GET submit for 2i page" do
        required_permissions = ["signin", "GDS Editor", "Unreleased feature"]

        it "can be accessed by users with GDS editor and Unreleased feature permissions" do
          stub_user.permissions = required_permissions
          get :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

          expect(response.status).to eq(200)
        end

        (required_permissions - %w(signin)).each do |required_permission|
          it "cannot be accessed by users without the #{required_permission} permission" do
            stub_user.permissions = required_permissions
            stub_user.permissions.delete(required_permission)
            get :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

            expect(response.status).to eq(403)
          end
        end
      end

      describe "POST submit for 2i" do
        before do
          required_permissions = ["signin", "GDS Editor", "Unreleased feature"]
          stub_user.permissions = required_permissions
          stub_user.name = "Firstname Lastname"
        end

        it "sets status to submit_for_2i" do
          post :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }

          step_by_step_page.reload

          expect(step_by_step_page.status).to eq("submitted_for_2i")
          expect(step_by_step_page.review_requester_id).to eq(stub_user.uid)
        end

        describe "internal change notes" do
          it "creates an internal change note" do
            expected_change_note = "Submitted for 2i by Firstname Lastname"

            post :submit_for_2i, params: { step_by_step_page_id: step_by_step_page.id }
            step_by_step_page.reload

            expect(step_by_step_page.internal_change_notes.first.description).to eq expected_change_note
          end

          it "records the additional comments in the internal change note" do
            additional_comments = "additional comments for reviewer"

            post :submit_for_2i, params: {
              step_by_step_page_id: step_by_step_page.id,
              additional_comments: additional_comments
            }

            expect(step_by_step_page.internal_change_notes.first.description).to include(additional_comments)
          end
        end
      end
    end

    describe "POST approve 2i review" do
      let(:user) { create(:user) }
      let(:reviewer_user) { create(:user) }

      let(:step_by_step_page) do
        create(
          :draft_step_by_step_page,
          review_requester_id: user.uid,
          status: "submitted_for_2i"
        )
      end

      before do
        step_by_step_page.update_attributes(:status => 'in_review', :reviewer_id => reviewer_user.uid)
      end

      required_permissions = ["signin", "GDS Editor", "Unreleased feature", "2i reviewer"]

      it "can be accessed by users with GDS editor, Unreleased feature and 2i reviewer permissions" do
        stub_user.permissions = required_permissions
        post :approve_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response).to redirect_to step_by_step_page_path(step_by_step_page)
      end

      (required_permissions - %w(signin)).each do |required_permission|
        it "cannot be accessed by users without the #{required_permission} permission" do
          stub_user.permissions = required_permissions
          stub_user.permissions.delete(required_permission)
          post :approve_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

          expect(response.status).to eq(403)
        end
      end

      it "sets status to approved_2i removes reviewer_id and review_requester_id" do
        stub_user.permissions = required_permissions
        post :approve_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        step_by_step_page.reload

        expect(step_by_step_page.status).to eq("approved_2i")
        expect(step_by_step_page.reviewer_id).to be_nil
        expect(step_by_step_page.review_requester_id).to be_nil
      end

      it "creates an internal change note" do
        stub_user.permissions = required_permissions
        stub_user.name = "Firstname Lastname"

        expected_change_note = "Approved 2i by Firstname Lastname"

        post :approve_2i_review, params: { step_by_step_page_id: step_by_step_page.id }
        step_by_step_page.reload

        expect(step_by_step_page.internal_change_notes.first.description).to eq expected_change_note
      end
    end

    describe "POST request change after 2i review" do
      let(:user) { create(:user) }
      let(:reviewer_user) { create(:user) }

      let(:step_by_step_page) do
        create(
          :draft_step_by_step_page,
          review_requester_id: user.uid,
          status: "submitted_for_2i"
        )
      end

      before do
        step_by_step_page.update_attributes(:status => 'in_review', :reviewer_id => reviewer_user.uid)
      end

      required_permissions = ["signin", "GDS Editor", "Unreleased feature", "2i reviewer"]

      it "can be accessed by users with GDS editor, Unreleased feature and 2i reviewer permissions" do
        stub_user.permissions = required_permissions
        post :request_change_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response).to redirect_to step_by_step_page_path(step_by_step_page)
      end

      (required_permissions - %w(signin)).each do |required_permission|
        it "cannot be accessed by users without the #{required_permission} permission" do
          stub_user.permissions = required_permissions
          stub_user.permissions.delete(required_permission)
          post :request_change_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

          expect(response.status).to eq(403)
        end
      end

      it "sets status to draft, removes reviewer_id and review_requester_id" do
        stub_user.permissions = required_permissions
        post :request_change_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        step_by_step_page.reload

        expect(step_by_step_page.status).to eq("draft")
        expect(step_by_step_page.reviewer_id).to be_nil
        expect(step_by_step_page.review_requester_id).to be_nil
      end

      it "creates an internal change note" do
        stub_user.permissions = required_permissions
        stub_user.name = "Firstname Lastname"

        expected_change_note = "Changes requested by Firstname Lastname\n\nSome change request"

        post :request_change_2i_review, params: { step_by_step_page_id: step_by_step_page.id, requested_change: "Some change request" }
        step_by_step_page.reload

        expect(step_by_step_page.internal_change_notes.first.description).to eq expected_change_note
      end
    end

    describe "POST claim 2i review" do
      let(:user) { create(:user) }

      let(:step_by_step_page) do
        create(
          :draft_step_by_step_page,
          review_requester_id: user.uid,
          status: "submitted_for_2i"
        )
      end

      required_permissions = ["signin", "GDS Editor", "Unreleased feature", "2i reviewer"]

      it "can be accessed by users with GDS editor, Unreleased feature and 2i reviewer permissions" do
        stub_user.permissions = required_permissions
        post :claim_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        expect(response).to redirect_to step_by_step_page_path(step_by_step_page)
      end

      (required_permissions - %w(signin)).each do |required_permission|
        it "cannot be accessed by users without the #{required_permission} permission" do
          stub_user.permissions = required_permissions
          stub_user.permissions.delete(required_permission)
          post :claim_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

          expect(response.status).to eq(403)
        end
      end

      it "sets status to in_review" do
        stub_user.permissions = required_permissions
        post :claim_2i_review, params: { step_by_step_page_id: step_by_step_page.id }

        step_by_step_page.reload

        expect(step_by_step_page.status).to eq("in_review")
        expect(step_by_step_page.reviewer_id).to eq(stub_user.uid)
      end

      it "creates an internal change note" do
        stub_user.permissions = required_permissions
        stub_user.name = "Firstname Lastname"

        expected_change_note = "In review by Firstname Lastname"

        post :claim_2i_review, params: { step_by_step_page_id: step_by_step_page.id }
        step_by_step_page.reload

        expect(step_by_step_page.internal_change_notes.first.description).to eq expected_change_note
      end
    end
  end
end
