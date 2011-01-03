require 'shipping_method'

class Calculator::PostalService < Calculator
  preference :weight_table, :string, :default => "1 2 5 10 20"
  preference :price_table, :string, :default => "6 9 12 15 18"
  preference :max_item_weight, :float, :default => 18
  preference :max_item_width, :float, :default => 60
  preference :max_item_length, :float, :default => 120
  preference :min_price, :float, :default => 10
  preference :handling_max, :float, :default => 50
  preference :handling_fee, :float, :default => 10
  
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
  
  # as order_or_line_items we always get line items, as calculable we have Coupon, ShippingMethod or ShippingRate
  def compute(order)
    debug = false
    puts order if debug
    line_items = order.line_items

    pain = 1
    
    total_price , total_weight , shipping  = 0 , 0 , 0 
    prices = self.preferred_price_table.split.map {|price| price.to_f }
    puts prices.join(" ")  if debug
    pain = 0 
    
    line_items.each do |item| # determine total price and weight
      total_weight += item.variant.weight ? item.variant.weight * item.quantity : 3 * item.quantity
      total_price += item.price * item.quantity
      if item.variant.weight and item.variant.weight > self.preferred_max_item_weight
          pain +=  prices.last * 2 * self.preferred_max_item_weight / item.variant.weight  
      end
      if item_oversized?( item )
        pain +=  prices.last * 2 * self.preferred_max_item_weight / item.variant.weight  
      end
    end
    puts "Weight " + total_weight.to_s  if debug
    puts "Price " + total_price.to_s if debug
    # determine handling fee
    handling_fee = self.preferred_handling_max < total_price  ? 0 : self.preferred_handling_fee
    puts "Handling max  " + self.preferred_handling_max.to_s  if debug
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
      if weights[index] < total_weight
        break
      end
      index -= 1
    end
    shipping +=  prices[index + 1] 
    puts "Shipping  " + shipping.to_s  if debug

    return shipping + handling_fee + pain
  end
end
