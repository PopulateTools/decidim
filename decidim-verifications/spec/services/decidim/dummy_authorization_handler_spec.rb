# frozen_string_literal: true

require "spec_helper"
require "decidim/dev/test/authorization_shared_examples"

module Decidim
  describe DummyAuthorizationHandler do
    let(:handler) { described_class.new(params.merge(extra_params)) }
    let(:params) { { user: create(:user, :confirmed) } }
    let(:extra_params) { {} }

    it_behaves_like "an authorization handler"

    describe "metadata" do
      subject { handler.metadata }

      let(:extra_params) { { document_number: "123456", postal_code: "123456" } }

      it { is_expected.to eq(document_number: "123456", postal_code: "123456") }
    end

    describe "valid?" do
      subject { handler.valid? }

      let(:extra_params) { { document_number: document_number, postal_code: "123456" } }

      context "when no document number" do
        let(:document_number) { nil }

        it { is_expected.to eq(false) }
      end

      context "when document number is not valid" do
        let(:document_number) { "123456" }

        it { is_expected.to eq(false) }
      end

      context "when document number is valid" do
        let(:document_number) { "123456X" }

        it { is_expected.to eq(true) }
      end
    end

    describe "logging" do
      let(:logged_attributes) { ActionLog.last.extra }
      let(:extra_params) { { document_number: "12345678X", postal_code: "1" } }

      before { handler.log_successful_authorization }

      it "logs inherited attributes" do
        expect(logged_attributes["handler_name"]).to eq("dummy_authorization_handler")
      end

      it "logs obfuscated custom attributes" do
        expect(logged_attributes["document_number"]).to eq("1*******X")
        expect(logged_attributes["postal_code"]).to eq("*")
      end
    end
  end
end
