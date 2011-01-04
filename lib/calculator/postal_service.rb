
class Calculator::PostalService < Calculator
  preference :weight_table, :string, :default => "1 2 5 10 20"
  preference :price_table, :string, :default => "6 9 12 15 18"
  preference :max_item_weight, :float, :default => 18
  preference :max_item_width, :float, :default => 60
  preference :max_item_length, :float, :default => 120
  preference :min_price, :float, :default => 10
  preference :handling_max, :float, :default => 50
  preference :handling_fee, :float, :default => 10
  preference :default_weight, :float, :default => 1
  
  def self.description
    "Postal"
#    I18n.t("postal_service")
  end
    
  def self.register
    super
    ShippingMethod.register_calculator(self)
  end
  
  def item_oversized? item
    variant = item.variant
    sizes = [ variant.width ? variant.width : 0 , variant.depth ? variant.depth : 0 , variant.height ? variant.height : 0 ].sort!
    #puts "Sizes " + sizes.join(" ")
    return true if sizes[0] > self.preferred_max_item_length
    return true if sizes[0] > self.preferred_max_item_width
    return false
  end
  
  def available?(order)
    return false if order.total < self.preferred_min_price
    order.line_items.each do |item| # determine if weight or size goes over bounds
      return false if item.variant.weight and item.variant.weight > self.preferred_max_item_weight
      return false if item_oversized?( item )
    end
    return true
  end
  
  # as order_or_line_items we always get line items, as calculable we have Coupon, ShippingMethod or ShippingRate
  def compute(order)
    debug = false
    puts order if debug
    
    total_price , total_weight , shipping  = 0 , 0 , 0 
    prices = self.preferred_price_table.split.map {|price| price.to_f }
    puts prices.join(" ")  if debug
    
    order.line_items.each do |item| # determine total price and weight
      total_weight += item.quantity * (item.variant.weight  || self.preferred_default_weight)
      total_price += item.price * item.quantity
    end
    puts "Weight " + total_weight.to_s  if debug
    puts "Price " + total_price.to_s if debug
    # determine handling fee
    puts "Handling max  " + self.preferred_handling_max.to_s  if debug
    handling_fee = self.preferred_handling_max < total_price  ? 0 : self.preferred_handling_fee
    puts "Handling  " + handling_fee.to_s  if debug
    weights = self.preferred_weight_table.split.map {|weight| weight.to_f} 
    puts weights.join(" ")  if debug
    while total_weight > weights.last  # in several packages if need be
      total_weight -= weights.last
      shipping += prices.last
    end
    puts "Shipping  " + shipping.to_s  if debug
    index = weights.length - 2
    while index >= 0
      break if total_weight > weights[index] 
      index -= 1
    end
    shipping +=  prices[index + 1] 
    puts "Shipping  " + shipping.to_s  if debug

    return shipping + handling_fee 
  end
end
