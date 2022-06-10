# frozen_string_literal: true

require "csv"

module Decidim
  # The controller to display Decidim activity
  class ActivityBrowserController < Decidim::ApplicationController

    def index
      @activity_data = activity_data
    end

    def data
      send_data activity_data, type: Mime[:csv], filename: "activity.csv"
    end

    private

    def activity_data
      # return File.read('/Users/fernando/Desktop/decidim_activities_report.csv')
      return Decidim::Exporters::CSV.new(Decidim::Activity.where(organization: current_organization).map(&:attributes)).export(",").read

      headers = %w(timestamp item_type item_id target_type target_id decidim_user_id participatory_space_id participatory_space_type)

      CSV.generate do |csv|
        # Header
        csv << headers
        # Data
        1000.times do
          item_type_target_type.each do |item_type, target_types|
            if target_types.empty?
              csv << [generate_timestamp, item_type, generate_id, nil, nil, generate_id, generate_participatory_space_type]
            else
              target_types.each do |target_type|
                csv << [generate_timestamp, item_type, generate_id, target_type, generate_id, generate_id, generate_participatory_space_type]
              end
            end
          end
        end
      end
    end

    def generate_timestamp
      year = [2020, 2021, 2022].sample
      month = rand(12) + 1
      day = rand(30) + 1
      hour = rand(23) + 1
      minute = rand(59) + 1

      # Time.parse("#{year}-#{month}-#{day} #{hour}:#{minute}:00")
      Date.new(year, month, day) rescue nil
    end

    def item_type_target_type
      {
        comment: [:proposal, :debate, :meeting, :initiative],
        comment_vote: [:comment],
        proposal: [],
        endorsement: [:proposal, :debate, :meeting, :initiative],
        following: [:user],
        meeting: [],
        meeting_registration: [:meeting],
        debate: [],
        initiative: [],
        initiative_vote: [:initiative]
      }
    end

    # 1..30 random
    def generate_id
      rand(30)+1
    end

    # 1..4 random
    def generate_participatory_space_id
      rand(3)+1
    end

    def generate_participatory_space_type
      [:participatory_process, :assembly].sample
    end

  end
end
