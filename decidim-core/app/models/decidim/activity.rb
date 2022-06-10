# frozen_string_literal: true

module Decidim
  # This class stores data of activities related with
  # creation of users, follows and resources.
  class Activity < ApplicationRecord
    self.table_name = "decidim_activities"

    belongs_to :organization, foreign_key: "decidim_organization_id", class_name: "Decidim::Organization"
  end
end
