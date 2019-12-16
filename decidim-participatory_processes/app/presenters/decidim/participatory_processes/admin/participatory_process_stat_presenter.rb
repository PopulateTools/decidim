# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      class ParticipatoryProcessStatPresenter < Rectify::Presenter
        attribute :name, String
        attribute :count, Integer
        attribute :percentage, Integer
        attribute :relative_percentage, Integer

        def present
          content_tag(:tr, id: "process-stat-#{name}") do
            content_tag(:td, I18n.t(name, scope: "decidim.stats.participatory_processes")) +
              content_tag(:td, number_with_delimiter(count)) +
              percentage_content +
              relative_percentage_content
          end
        end

        private

        def percentage_content
          percentage ? content_tag(:td, "#{percentage} %") : content_tag(:td, "-")
        end

        def relative_percentage_content
          relative_percentage ? content_tag(:td, "#{relative_percentage} %") : content_tag(:td, "-")
        end
      end
    end
  end
end
