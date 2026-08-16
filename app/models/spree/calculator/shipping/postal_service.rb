# frozen_string_literal: true

module Spree
  module Calculator::Shipping
    class PostalService < WeightedShipping
      def self.description
        Spree.t(:postal_service)
      end
    end
  end
end
