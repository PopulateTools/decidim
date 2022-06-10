# frozen_string_literal: true

class CreateDecidimActivities < ActiveRecord::Migration[6.1]
  def change
    create_table :decidim_activities do |t|
      t.datetime :timestamp
      t.string :item_type
      t.integer :item_id
      t.string :target_type
      t.integer :target_id
      t.integer :decidim_user_id
      t.string :participatory_space_type
      t.integer :participatory_space_id
      t.integer :decidim_organization_id
      t.string :item_url
      t.string :target_url
      t.string :participatory_space_url
    end
  end
end
