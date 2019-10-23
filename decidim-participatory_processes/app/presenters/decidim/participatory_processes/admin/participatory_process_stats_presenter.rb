# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      # A presenter to render statistics in the process admin page.
      class ParticipatoryProcessStatsPresenter < Rectify::Presenter
        attribute :participatory_process, Decidim::ParticipatoryProcess

        def headers
          content_tag(:tr) do
            safe_join(
              stats_headers.map do |column|
                content_tag(:th) { column }
              end
            )
          end
        end

        def values
          safe_join(
            process_stats.map do |stat|
              ParticipatoryProcessStatPresenter.new(stat).present
            end
          )
        end

        private

        def process_stats
          ParticipationStats.new(participatory_process).stats
        end

        def stats_headers
          %w(metric value total_percentage active_percentage).map do |key|
            I18n.t(key, scope: "decidim.stats.participatory_processes")
          end
        end
      end
    end
  end
end
