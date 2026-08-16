# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Solidus weighted shipping integration" do
  def create_line_item(order:, price:, weight:, dimensions: %w[10 10 10])
    variant = create(
      :variant,
      weight:,
      width: dimensions.fetch(0),
      depth: dimensions.fetch(1),
      height: dimensions.fetch(2)
    )
    create(:line_item, order:, variant:, price:, quantity: 1)
  end

  def package_for(order:, line_items:, stock_location: nil)
    contents = line_items.map do |line_item|
      inventory_unit = Spree::InventoryUnit.new(variant: line_item.variant, line_item:)
      Spree::Stock::ContentItem.new(inventory_unit)
    end

    Spree::Stock::Package.new(stock_location || create(:stock_location), contents).tap do |package|
      package.shipment = Spree::Shipment.new(order:, stock_location: package.stock_location)
    end
  end

  def recalculate(order)
    order.recalculate
    order.reload
  end

  let(:calculator) { Spree::Calculator::Shipping::WeightedShipping.new }

  it "keeps handling package-scoped and free shipping order-scoped across packages" do
    order = create(:order, currency: "USD")
    inexpensive = create_line_item(order:, price: "40", weight: "1")
    expensive = create_line_item(order:, price: "80", weight: "1")
    recalculate(order)
    first_package = package_for(order:, line_items: [inexpensive])
    second_package = package_for(order:, line_items: [expensive])

    expect(order.item_total).to eq(decimal("120"))
    expect(calculator.quote_package(first_package).amount).to eq(decimal("16"))
    expect(calculator.quote_package(first_package).handling_fee).to eq(decimal("10"))
    expect(calculator.quote_package(second_package).amount).to eq(decimal("6"))
    expect(calculator.quote_package(second_package).handling_fee).to eq(decimal("0"))

    expensive.update_column(:price, decimal("80.01"))
    recalculate(order)

    expect(order.item_total).to eq(decimal("120.01"))
    expect(calculator.quote_package(first_package)).to be_free_shipping
    expect(calculator.quote_package(second_package)).to be_free_shipping
  end

  it "checks only variants contained in the quoted package" do
    order = create(:order, currency: "USD")
    allowed = create_line_item(order:, price: "10", weight: "1")
    oversized = create_line_item(order:, price: "10", weight: "1", dimensions: %w[121 10 10])
    recalculate(order)

    allowed_package = package_for(order:, line_items: [allowed])
    oversized_package = package_for(order:, line_items: [oversized])

    expect(calculator.available?(allowed_package)).to be(true)
    expect(calculator.available?(oversized_package)).to be(false)
    expect(calculator.quote_package(oversized_package).reason).to eq(:maximum_item_length_exceeded)
  end

  it "rates through the current Solidus stock estimator" do
    variant = create(:variant, weight: "10", width: "10", depth: "10", height: "10")
    shipping_method = create(:shipping_method, calculator:)
    order = create(
      :order_with_line_items,
      currency: "USD",
      shipping_method:,
      shipment_cost: 0,
      line_items_attributes: [{variant:, price: decimal("100")}]
    )
    shipping_method.zones.first.members.create!(zoneable: order.ship_address.country)
    package = build(
      :stock_package,
      stock_location: order.shipments.first.stock_location,
      contents: order.inventory_units.map { |unit| Spree::Stock::ContentItem.new(unit) }
    )
    package.shipment = package.to_shipment

    rates = Spree::Stock::Estimator.new.shipping_rates(package)

    expect(rates.map(&:shipping_method)).to include(shipping_method)
    weighted_rate = rates.find { |rate| rate.shipping_method == shipping_method }
    expect(weighted_rate.cost).to eq(decimal("15"))
    expect(weighted_rate).to be_selected
  end

  it "persists canonical preferences through a shipping method" do
    calculator.preferred_rate_table = "2: 4\n10: 7"
    calculator.preferred_free_shipping_threshold = "250"
    shipping_method = create(:shipping_method, calculator:)

    persisted = shipping_method.reload.calculator

    expect(persisted).to be_a(Spree::Calculator::Shipping::WeightedShipping)
    expect(persisted.preferred_rate_table).to eq("2: 4\n10: 7")
    expect(persisted.preferred_free_shipping_threshold).to eq(decimal("250"))
    expect(persisted).to be_valid
  end

  it "treats amounts as decimal values in the order currency without minor-unit conversion" do
    %w[JPY KWD].each do |currency|
      order = create(:order, currency:)
      line_item = create_line_item(order:, price: "100", weight: "10")
      recalculate(order)
      package = package_for(order:, line_items: [line_item])

      quote = calculator.quote_package(package)
      expect(quote.currency).to eq(currency)
      expect(quote.amount).to eq(decimal("15"))
    end
  end

  it "does not mutate Solidus records, package contents, or preferences while previewing" do
    order = create(:order, currency: "USD")
    line_item = create_line_item(order:, price: "40", weight: "2")
    recalculate(order)
    package = package_for(order:, line_items: [line_item])
    snapshots = {
      order: order.attributes.deep_dup,
      line_item: line_item.reload.attributes.deep_dup,
      variant: line_item.variant.reload.attributes.deep_dup,
      preferences: calculator.preferences.deep_dup,
      contents: package.contents.dup
    }
    writes = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      writes << payload[:sql] if payload[:sql].match?(/\A\s*(?:INSERT|UPDATE|DELETE)\b/i)
    end

    begin
      first_quote = calculator.quote_package(package)
      second_quote = calculator.quote_package(package)
      calculator.available?(package)
      calculator.compute_package(package)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    expect(second_quote).to eq(first_quote)
    expect(writes).to be_empty
    expect(order.reload.attributes).to eq(snapshots[:order])
    expect(line_item.reload.attributes).to eq(snapshots[:line_item])
    expect(line_item.variant.reload.attributes).to eq(snapshots[:variant])
    expect(calculator.preferences).to eq(snapshots[:preferences])
    expect(package.contents).to eq(snapshots[:contents])
  end
end
