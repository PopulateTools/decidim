# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      class ParticipatoryProcessStatsController < Decidim::Admin::ApplicationController
        include Concerns::ParticipatoryProcessAdmin

        def index
          enforce_permission_to :index, :stats

          @process_stats = ParticipatoryProcessStatsPresenter.new(
            participatory_process: current_participatory_process
          )
        end
      end
    end
  end
end
