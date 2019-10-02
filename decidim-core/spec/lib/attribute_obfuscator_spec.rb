# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe AttributeObfuscator do
    let(:obfuscator) { AttributeObfuscator }

    describe "#email_hint" do
      subject { obfuscator.email_hint(email) }

      context "for regular emails" do
        let(:email) { "name-surname@email.com" }

        it { is_expected.to eq("nam*********@******com") }
      end

      context "for short emails" do
        let(:email) { "foo@bar.es" }

        it { is_expected.to eq("f**@***.es") }
      end

      context "for invalid emails" do
        let(:email) { "invalid" }

        it { is_expected.to be_nil }
      end

      context "for blank emails" do
        let(:email) { "" }

        it { is_expected.to be_nil }
      end
    end

    describe "#name_hint" do
      subject { obfuscator.name_hint(name) }

      context "for blank names" do
        let(:name) { "" }

        it { is_expected.to be_nil }
      end

      context "for short names" do
        let(:name) { "Ann" }

        it { is_expected.to eq("A*n") }
      end

      context "for regular names" do
        let(:name) { "Harry Potter" }

        it { is_expected.to eq("Har******ter") }
      end
    end

    describe "#census_attribute_hint" do
      subject { obfuscator.census_attribute_hint(attribute_value) }

      context "for blank attributes" do
        let(:attribute_value) { "" }

        it { is_expected.to be_nil }
      end

      context "for short attributes" do
        let(:attribute_value) { "abc" }

        it { is_expected.to eq("abc") }
      end

      context "for long attributes" do
        let(:attribute_value) { "12345678A" }

        it { is_expected.to eq("1*****78A") }
      end
    end
  end
end
