# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AuthorizationHandler do
    let(:organization) { create(:organization) }
    let(:user) { create(:user, organization: organization) }

    let(:handler) { described_class.new(params) }
    let(:params) { { user: user, organization: organization } }

    let(:action_log) { ActionLog.last }

    describe "form_attributes" do
      subject { handler.form_attributes }

      it { is_expected.to match_array([:handler_name]) }
      it { is_expected.not_to match_array([:id, :user]) }
    end

    describe "to_partial_path" do
      subject { handler.to_partial_path }

      it { is_expected.to eq("authorization/form") }
    end

    describe "handler_name" do
      subject { handler.handler_name }

      it { is_expected.to eq("authorization_handler") }
    end

    describe "user" do
      subject { handler.user }

      it { is_expected.to eq(user) }
    end

    describe "metadata" do
      subject { handler.metadata }

      it { is_expected.to be_kind_of(Hash) }
    end

    describe "handler_for" do
      subject { described_class.handler_for(name, params) }

      context "when the handler does not exist" do
        let(:name) { "decidim/foo" }

        it { is_expected.to eq(nil) }
      end

      context "when the handler exists" do
        context "when the handler is not valid" do
          let(:name) { "decidim/authorization_handler" }

          it { is_expected.to eq(nil) }
        end

        context "when the handler is valid" do
          let(:name) { "dummy_authorization_handler" }

          context "when the handler is not configured", with_authorization_workflows: [] do
            it { is_expected.to eq(nil) }
          end

          context "when the handler is configured" do
            it { is_expected.to be_kind_of(described_class) }
          end
        end
      end
    end

    describe "log_successful_authorization" do
      before { handler.log_successful_authorization }

      it "creates a log entry" do
        expect(action_log.action).to eq("create_authorization_success")
        expect(action_log.user).to eq(user)
        expect(action_log.resource).to eq(user)

        expect(action_log.extra["handler_name"]).to eq("authorization_handler")
      end
    end

    describe "log_failed_authorization" do
      before { handler.log_failed_authorization }

      it "creates a log entry" do
        expect(action_log.action).to eq("create_authorization_error")
        expect(action_log.user).to eq(user)
        expect(action_log.resource).to eq(user)

        expect(action_log.extra["handler_name"]).to eq("authorization_handler")
      end
    end
  end
end
