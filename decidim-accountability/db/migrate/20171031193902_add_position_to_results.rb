# frozen_string_literal: true

class AddPositionToResults < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_accountability_results, :position, :integer, null: true, index: true
  end
end
