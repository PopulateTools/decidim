# frozen_string_literal: true

module Decidim
  module Log
    module ValueTypes
      class BooleanPresenter < DefaultPresenter
        include Decidim::HumanizeBooleansHelper

        def present
          humanize_boolean(value)
        end
      end
    end
  end
end
