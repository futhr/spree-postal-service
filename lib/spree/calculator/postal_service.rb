class Spree::Calculator::PostalService < Spree::Calculator
  preference :weight_table,    :string,  :default => '1 2 5 10 20'
  preference :price_table,     :string,  :default => '6 9 12 15 18'
  preference :max_item_weight, :decimal, :default => 18
  preference :max_item_width,  :decimal, :default => 60
  preference :max_item_length, :decimal, :default => 120
  preference :max_price,       :decimal, :default => 120
  preference :handling_max,    :decimal, :default => 50
  preference :handling_fee,    :decimal, :default => 10
  preference :default_weight,  :decimal, :default => 1

  attr_accessible :preferred_weight_table,
                  :preferred_price_table,
                  :preferred_max_item_weight,
                  :preferred_max_item_width,
                  :preferred_max_item_length,
                  :preferred_max_price,
                  :preferred_handling_max,
                  :preferred_handling_fee,
                  :preferred_default_weight

  def self.description
    Spree.t(:postal_service)
  end

  def self.register
    super
  end

  def item_oversized?(variant)
    sizes = [
      variant.width  ? variant.width  : 0,
      variant.depth  ? variant.depth  : 0,
      variant.height ? variant.height : 0
    ].sort.reverse

    return true if sizes[0] > self.preferred_max_item_length # longest side
    return true if sizes[0] > self.preferred_max_item_width  # second longest side
    return false
  end

  def available?(shipment)
    variants = shipment.line_items.map(&:variant)
    variants.each do |variant| # determine if weight or size goes over bounds
      return false if variant.weight && variant.weight > self.preferred_max_item_weight # 18
      return false if item_oversized? variant
    end
    return true
  end

  # as order_or_line_items we always get line items, as calculable we have Coupon, ShippingMethod or ShippingRate
  def compute(shipment)
    order = shipment.order

    total_price, total_weight, shipping = 0, 0, 0
    prices = self.preferred_price_table.split.map { |price| price.to_f }

    order.line_items.each do |item| # determine total price and weight
      total_weight += item.quantity * (item.variant.weight || self.preferred_default_weight)
      total_price  += item.price * item.quantity
    end

    return 0.0 if total_price > self.preferred_max_price

    # determine handling fee
    handling_fee = self.preferred_handling_max < total_price ? 0 : self.preferred_handling_fee
    weights      = self.preferred_weight_table.split.map { |weight| weight.to_f }

    while total_weight > weights.last # in several packages if need be
      total_weight -= weights.last
      shipping += prices.last
    end

    index = weights.length - 2
    while index >= 0
      break if total_weight > weights[index]
      index -= 1
    end

    shipping += prices[index + 1]
    return shipping + handling_fee
  end
end
