# frozen_string_literal: true

require "spec_helper"

def create_metric(type, value, organization, day = Time.zone.yesterday, participatory_process = nil)
  attrs = {
    metric_type: type,
    day: day,
    cumulative: value,
    quantity: value,
    organization: organization
  }
  attrs[:participatory_space] = participatory_process if participatory_process

  create(:metric, attrs)
end

module Decidim::ParticipatoryProcesses
  describe Admin::ParticipationStats do
    let(:participation_stats) { described_class.new(participatory_process) }

    let(:organization) { create :organization }
    let(:other_organization) { create :organization }

    let(:user) { create :user, organization: organization }
    let(:other_user) { create :user, organization: other_organization }

    let(:participatory_process) { create :participatory_process, organization: organization }

    let(:day) { Time.zone.yesterday }

    describe "stats" do
      describe "total_registered" do
        subject { participation_stats.stats.first }

        context "when none" do
          it { is_expected.to eq(name: "total_registered", count: 0, percentage: nil) }
        end

        context "when any" do
          before do
            create_metric("users", 100, organization)
            create_metric("users", 10, organization, day - 1.day)
          end

          it { is_expected.to eq(name: "total_registered", count: 100, percentage: 100) }
        end
      end

      describe "total_verified" do
        subject { participation_stats.stats.second }

        context "when none" do
          it { is_expected.to eq(name: "total_verified", count: 0, percentage: nil) }
        end

        context "when any" do
          before do
            create(:authorization, user: user)
            create(:authorization, user: other_user)
          end

          it { is_expected.to eq(name: "total_verified", count: 1, percentage: nil) }
        end
      end

      describe "active_users" do
        subject { participation_stats.stats.third }

        context "when none" do
          it { is_expected.to eq(name: "active_users", count: 0, percentage: nil, relative_percentage: nil) }
        end

        context "when any" do
          before do
            create_metric("users", 100, organization)
            create_metric("participants", 50, organization, day, participatory_process)
            create_metric("participants", 1, organization, day - 1.day, participatory_process)
          end

          it { is_expected.to eq(name: "active_users", count: 50, percentage: 50, relative_percentage: 100) }
        end
      end

      describe "voting_users" do
        subject { participation_stats.stats.fourth }

        let(:component) { create(:component, participatory_space: participatory_process, manifest_name: :proposals) }
        let(:proposal) { create(:proposal, component: component) }

        before do
          create_metric("users", 100, organization)
          create_metric("participants", 50, organization, day, participatory_process)
        end

        context "when none" do
          it { is_expected.to eq(name: "voting_users", count: 0, percentage: 0, relative_percentage: 0) }
        end

        context "when one" do
          before { create(:proposal_vote, proposal: proposal, author: user) }

          it { is_expected.to eq(name: "voting_users", count: 1, percentage: 1, relative_percentage: 2) }
        end

        context "when user votes many times" do
          let(:proposal_2) { create(:proposal, component: component) }

          before do
            create(:proposal_vote, proposal: proposal, author: user)
            create(:proposal_vote, proposal: proposal_2, author: user)
          end

          it { is_expected.to eq(name: "voting_users", count: 1, percentage: 1, relative_percentage: 2) }
        end

        context "when several voters" do
          let(:user_2) { create :user, organization: organization }

          before do
            create(:proposal_vote, proposal: proposal, author: user)
            create(:proposal_vote, proposal: proposal, author: user_2)
          end

          it { is_expected.to eq(name: "voting_users", count: 2, percentage: 2, relative_percentage: 4) }
        end
      end

      describe "not_voting_users" do
        subject { participation_stats.stats.fifth }

        before do
          create_metric("users", 100, organization)
          create_metric("participants", 50, organization, day, participatory_process)
        end

        context "when nobody voted" do
          it { is_expected.to eq(name: "not_voting_users", count: 100, percentage: 100, relative_percentage: 100) }
        end

        context "when some voted" do
          before { allow(participation_stats).to receive(:proposals_voters_count).and_return(25) }

          it { is_expected.to eq(name: "not_voting_users", count: 75, percentage: 75, relative_percentage: 50) }
        end
      end
    end
  end
end
