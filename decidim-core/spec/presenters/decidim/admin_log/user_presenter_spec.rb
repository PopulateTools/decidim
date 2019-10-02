# frozen_string_literal: true

require "spec_helper"

describe Decidim::AdminLog::UserPresenter, type: :helper do
  subject { presenter }

  let(:organization) { create(:organization, available_authorizations: available_authorizations) }
  let(:authorization_handler) { "dummy_authorization_handler" }
  let(:available_authorizations) { [authorization_handler] }

  let(:user) { create :user, name: "Harry Potter" }
  let(:obfuscated_document_number) { "1*****78X" }

  let(:presenter) { described_class.new(action_log, helper) }
  let(:action_log) { Decidim::ActionLog.last }
  let(:action_log_extras) do
    { handler_name: authorization_handler, document_number: obfuscated_document_number }
  end

  before do
    helper.extend(Decidim::TranslationsHelper)
  end

  describe "#present" do
    context "when user was authorized" do
      before do
        Decidim::ActionLogger.log("create_authorization_success", user, user, 0, action_log_extras)
      end

      it "shows the authorization details" do
        expect(subject.present).to match(%r{Harry Potter.*has authorized his\/her account})

        expect(subject.present).to include("Handler name")
        expect(subject.present).to include(authorization_handler)

        expect(subject.present).to include("Document number")
        expect(subject.present).to include(obfuscated_document_number)
      end
    end

    context "when user failed to authorize" do
      before do
        Decidim::ActionLogger.log("create_authorization_error", user, user, 0, action_log_extras)
      end

      it "shows the authorization details" do
        expect(subject.present).to match(%r{Harry Potter.*could not authorize his\/her account})

        expect(subject.present).to include("Handler name")
        expect(subject.present).to include(authorization_handler)

        expect(subject.present).to include("Document number")
        expect(subject.present).to include(obfuscated_document_number)
      end
    end
  end
end
