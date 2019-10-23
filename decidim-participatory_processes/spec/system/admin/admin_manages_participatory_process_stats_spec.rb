# frozen_string_literal: true

require "spec_helper"

describe "Admin manages participatory process stats", type: :system do
  include_context "when admin administrating a participatory process"

  let(:active) { false }
  let(:total_users) { 100 }
  let(:verified_users) { total_users / 2 }
  let(:active_users) { verified_users / 2 }
  let(:voting_users) { total_users / 10 }

  before do
    # rubocop:disable RSpec/AnyInstance
    allow_any_instance_of(Decidim::ParticipatoryProcesses::Admin::ParticipationStats).to receive(:total_users_count).and_return(total_users)
    allow_any_instance_of(Decidim::ParticipatoryProcesses::Admin::ParticipationStats).to receive(:verified_users_count).and_return(verified_users)
    allow_any_instance_of(Decidim::ParticipatoryProcesses::Admin::ParticipationStats).to receive(:active_users_count).and_return(25)
    allow_any_instance_of(Decidim::ParticipatoryProcesses::Admin::ParticipationStats).to receive(:proposals_voters_count).and_return(voting_users)
    # rubocop:enable RSpec/AnyInstance

    switch_to_host(organization.host)
    login_as user, scope: :user
    visit decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
    click_link "Statistics"
  end

  describe "registration stats" do
    it "shows a summary" do
      within("#process-stat-total_registered") do
        expect(page).to have_content("Total registered users")
        expect(page).to have_content("#{total_users} %")
        expect(page).to have_content("-")
      end
    end
  end

  describe "verification stats" do
    it "shows a summary" do
      within("#process-stat-total_verified") do
        expect(page).to have_content("Total verified users")
        expect(page).to have_content("#{verified_users} %")
        expect(page).to have_content("-")
      end
    end
  end

  describe "participation stats" do
    it "shows a summary" do
      within("#process-stat-active_users") do
        expect(page).to have_content("Active users in process")
        expect(page).to have_content("#{active_users} %")
        expect(page).to have_content("100")
      end
    end
  end

  describe "voting stats" do
    it "shows a summary" do
      within("#process-stat-voting_users") do
        expect(page).to have_content("Users that have voted")
        expect(page).to have_content("#{voting_users} %")
        expect(page).to have_content("40")
      end
    end
  end

  describe "abstention stats" do
    it "shows a summary" do
      within("#process-stat-not_voting_users") do
        expect(page).to have_content("Users that have not voted")
        expect(page).to have_content("90 %")
        expect(page).to have_content("60")
      end
    end
  end
end
