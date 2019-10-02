# frozen_string_literal: true

module Decidim
  module Admin
    # Controller that allows searching and destroy authorizations by passing
    # the user verification data used to generate the authorization
    #
    class AuthorizationsController < Decidim::Admin::ApplicationController
      layout "decidim/admin/users"

      helper_method :available_authorization_handlers,
                    :other_available_authorizations

      def index
        enforce_permission_to :index, :authorizations

        @form = form(AuthorizationForm).from_params(
          handler_name: handler_name,
          authorization: Decidim::AuthorizationHandler.handler_for(
            handler_name,
            user: user
          )
        )
      end

      def delete
        enforce_permission_to :delete, :authorizations

        @form = form(AuthorizationForm).from_params(
          handler_name: handler_name,
          authorization: Decidim::AuthorizationHandler.handler_for(
            handler_name,
            params[:authorization][:authorization].merge(user: user)
          )
        )

        DestroyAuthorization.call(@form) do
          on(:ok) do
            flash[:notice] = I18n.t("authorizations.delete.success", scope: "decidim.admin")
            redirect_to authorizations_path
          end

          on(:not_found) do
            flash.now[:alert] = I18n.t("authorizations.delete.not_found", scope: "decidim.admin")
            render :index
          end
        end
      end

      private

      def user
        @user ||= Decidim::User.new(
          organization: current_organization,
          admin: false,
          managed: true
        )
      end

      def handler_name
        authorization = params.dig(:impersonate_user, :authorization)
        return available_authorization_handlers.first.name unless authorization

        authorization[:handler_name]
      end

      def other_available_authorizations
        return [] if available_authorization_handlers.size == 1

        other_available_authorization_handlers.map do |authorization_handler|
          Decidim::AuthorizationHandler.handler_for(authorization_handler.name)
        end
      end

      def other_available_authorization_handlers
        Decidim::Verifications::Adapter.from_collection(
          current_organization.available_authorization_handlers - [handler_name]
        )
      end

      def available_authorization_handlers
        Decidim::Verifications::Adapter.from_collection(
          current_organization.available_authorization_handlers
        )
      end
    end
  end
end
