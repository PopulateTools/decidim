# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      class ParticipationStats
        attr_accessor :participatory_process, :organization

        def initialize(participatory_process)
          @participatory_process = participatory_process
          @organization = participatory_process.organization
        end

        def stats
          [
            {
              name: "total_registered",
              count: total_users_count,
              percentage: percentage(total_users_count, total_users_count)
            },
            {
              name: "total_verified",
              count: verified_users_count,
              percentage: percentage(verified_users_count, total_users_count)
            },
            {
              name: "active_users",
              count: active_users_count,
              percentage: percentage(active_users_count, total_users_count),
              relative_percentage: percentage(active_users_count, active_users_count)
            },
            {
              name: "voting_users",
              count: proposals_voters_count,
              percentage: percentage(proposals_voters_count, total_users_count),
              relative_percentage: percentage(proposals_voters_count, active_users_count)
            },
            {
              name: "not_voting_users",
              count: proposals_not_voters_count,
              percentage: percentage(proposals_not_voters_count, total_users_count),
              relative_percentage: percentage(active_users_count - proposals_voters_count, active_users_count)
            }
          ]
        end

        private

        def total_users_count
          @total_users_count ||= metric_last_value("users")
        end

        def verified_users_count
          @verified_users_count ||= organization.authorizations.count
        end

        def active_users_count
          @active_users_count ||= metric_last_value("participants", participatory_process: participatory_process)
        end

        def proposals_voters_count
          @proposals_voters_count ||= begin
            proposals = ::Decidim::Proposals::Proposal.where(decidim_component_id: participatory_process.components.pluck(:id))
            votes = ::Decidim::Proposals::ProposalVote.where(decidim_proposal_id: proposals.pluck(:id))
            votes.pluck(:decidim_author_id).uniq.size
          end
        end

        def proposals_not_voters_count
          @proposals_not_voters_count ||= total_users_count - proposals_voters_count
        end

        def metric_last_value(metric_type, params = {})
          metric_attrs = {
            organization: organization,
            metric_type: metric_type
          }

          metric_attrs[:participatory_space] = participatory_process if params[:participatory_process]

          Decidim::Metric.where(metric_attrs).order(day: :desc).first&.cumulative || 0
        end

        def percentage(part_count, total_count)
          return nil unless part_count && total_count&.positive?

          ((part_count * 100.0) / total_count).round
        end
      end
    end
  end
end
