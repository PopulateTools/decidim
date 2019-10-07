# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AttributeObfuscator do
    let(:obfuscator) { AttributeObfuscator }

    describe "#email_hint" do
      subject { obfuscator.email_hint(email) }

      context "with invalid emails" do
        let(:email) { "invalid" }

        it { is_expected.to be_nil }
      end

      context "with blank emails" do
        let(:email) { "" }

        it { is_expected.to be_nil }
      end

      context "with very short emails" do
        let(:email) { "ab@email.com" }

        it { is_expected.to eq("**@email.com") }
      end

      context "with short emails" do
        let(:email) { "peter@email.com" }

        it { is_expected.to eq("p***r@email.com") }
      end

      context "with medium emails" do
        let(:email) { "stephen@email.com" }

        it { is_expected.to eq("st***en@email.com") }
      end

      context "with long emails" do
        let(:email) { "name-surname@email.com" }

        it { is_expected.to eq("nam******ame@email.com") }
      end
    end

    describe "#name_hint" do
      subject { obfuscator.name_hint(name) }

      context "with blank names" do
        let(:name) { "" }

        it { is_expected.to be_nil }
      end

      context "with very short names" do
        let(:name) { "Al" }

        it { is_expected.to eq("**") }
      end

      context "with short names" do
        let(:name) { "Ann" }

        it { is_expected.to eq("A*n") }
      end

      context "with regular names" do
        let(:name) { "Harry Potter" }

        it { is_expected.to eq("Har******ter") }
      end
    end

    describe "#secret_attribute_hint" do
      subject { obfuscator.secret_attribute_hint(attribute_value) }

      context "with blank attributes" do
        let(:attribute_value) { "" }

        it { is_expected.to be_nil }
      end

      context "with short attributes" do
        let(:attribute_value) { "abc" }

        it { is_expected.to eq("***") }
      end

      context "with long attributes" do
        let(:attribute_value) { "12345678X" }

        it { is_expected.to eq("1*******X") }
      end
    end
  end
end
