# frozen_string_literal: true

module Spree
  module Calculator::Shipping
    class PostalService < WeightedShipping
      def self.description
        I18n.t("spree.postal_service", default: "Postal Service")
      end
    end
  end
end
