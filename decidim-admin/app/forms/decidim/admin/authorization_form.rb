# frozen_string_literal: true

module Decidim
  module Admin
    # A form object used to search users authorizations with their verification
    # data from the admin dashboard.
    #
    # This form will contain a dynamic attribute for the user authorization.
    # This authorization will be selected by the admin user if more than one exists.
    class AuthorizationForm < Form
      attribute :name, String
      attribute :authorization, Decidim::AuthorizationHandler
      attribute :handler_name, String

      def disable_submit?
        true
      end
    end
  end
end
