# frozen_string_literal: true

module Decidim
  module Verifications
    # A command to authorize a user with an authorization handler.
    class AuthorizeUser < Rectify::Command
      # Public: Initializes the command.
      #
      # handler - An AuthorizationHandler object.
      def initialize(handler)
        @handler = handler
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid.
      # - :invalid if the handler wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        unless handler.valid?
          handler.log_failed_authorization
          return broadcast(:invalid)
        end

        Authorization.create_or_update_from(handler)

        handler.log_successful_authorization

        broadcast(:ok)
      end

      private

      attr_reader :handler
    end
  end
end
