# frozen_string_literal: true

module Decidim
  module Admin
    # A command with all the business logic to find an authorization by its
    # verification data and delete it.
    #
    class DestroyAuthorization < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - The form with the authorization info
      def initialize(form)
        @form = form
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when the authorization is found and deleted
      # - :not_found if the authorization couldn't be found
      #
      # Returns nothing.
      def call
        return broadcast(:not_found) if authorization.blank?

        destroy_authorization

        broadcast(:ok)
      end

      private

      attr_reader :form

      def user
        authorization.user
      end

      def authorization
        @authorization ||= Authorization.find_by(unique_id: form.authorization.unique_id)
      end

      def destroy_authorization
        Decidim.traceability.perform_action!(
          "delete",
          authorization,
          current_user,
          extra: {
            authorization_owner: user
          }
        ) do
          authorization.destroy
        end
      end
    end
  end
end
