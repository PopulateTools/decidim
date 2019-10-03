# frozen_string_literal: true

module Decidim
  module AdminLog
    # This class holds the logic to present a `Decidim::User`
    # for the `AdminLog` log.
    #
    # Usage should be automatic and you shouldn't need to call this class
    # directly, but here's an example:
    #
    #    action_log = Decidim::ActionLog.last
    #    view_helpers # => this comes from the views
    #    UserPresenter.new(action_log, view_helpers).present
    class UserPresenter < Decidim::Log::BasePresenter
      private

      def action_string
        case action
        when "grant_id_documents_offline_verification", "invite", "officialize", "remove_from_admin", "unofficialize", "create_authorization_success", "create_authorization_error"
          "decidim.admin_log.user.#{action}"
        else
          super
        end
      end

      def i18n_params
        super.merge(
          role: I18n.t("models.user.fields.roles.#{user_role}", scope: "decidim.admin")
        )
      end

      def user_role
        action_log.extra.dig("extra", "invited_user_role")
      end

      def user_badge
        action_log.extra.dig("extra", "officialized_user_badge") || Hash.new("")
      end

      def previous_user_badge
        action_log.extra.dig("extra", "officialized_user_badge_previous") || Hash.new("")
      end

      # Fake the changeset for officialization and authorization actions.
      def changeset
        case action
        when "create_authorization_success", "create_authorization_error"
          original_changeset, fields_mapping = authorization_changeset
        else
          original_changeset = { badge: [previous_user_badge, user_badge] }
          fields_mapping = { badge: :i18n }
        end

        Decidim::Log::DiffChangesetCalculator.new(
          original_changeset,
          fields_mapping,
          i18n_labels_scope
        ).changeset
      end

      # Show the diff if the action is officialization or authorization.
      def has_diff?
        %w(officialize unofficialize create_authorization_success create_authorization_error).include?(action)
      end

      def authorization_changeset
        changeset_list = action_log.extra.symbolize_keys
                                   .except(:component, :participatory_space, :resource, :user) # Don't display extra_data added by ActionLogger
                                   .map { |k, v| [k, [nil, v]] }
        original_changeset = Hash[changeset_list]
        fields_mapping = Hash[original_changeset.keys.map { |k| [k, :string] }]

        [original_changeset, fields_mapping]
      end

      def show_previous_value_in_diff?
        super && %w(create_authorization_success create_authorization_error).exclude?(action)
      end
    end
  end
end
