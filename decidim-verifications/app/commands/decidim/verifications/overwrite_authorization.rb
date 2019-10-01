# frozen_string_literal: true

module Decidim
  module Verifications
    # A command to overwrite an existing authorization for another user.
    class OverwriteAuthorization < Rectify::Command
      # Public: Initializes the command.
      #
      # authorization_id - The id of the authorization that will be replaced
      # new_user - The user that will be authorized with the existing data
      def initialize(authorization_id, new_user)
        @authorization_id = authorization_id
        @new_user = new_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      #
      # Returns nothing.
      def call
        authorization = Decidim::Authorization.find(@authorization_id)

        Authorization.replace_authorization!(authorization, @new_user)

        broadcast(:ok)
      end
    end
  end
end
