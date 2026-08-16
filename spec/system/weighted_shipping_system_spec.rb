# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Weighted shipping browser flows", type: :system, js: true do
  stub_authorization!

  before do
    driven_by :solidus_chrome_headless
  end

  def capture_screenshot(name)
    directory = File.expand_path("../../tmp/screenshots", __dir__)
    FileUtils.mkdir_p(directory)
    # rubocop:disable Lint/Debugger -- screenshots are retained CI evidence
    page.save_screenshot(File.join(directory, "#{name}.png"))
    # rubocop:enable Lint/Debugger
  end

  def create_preview_order(line_items_attributes:, shipping_method: nil)
    shipping_method ||= create(
      :shipping_method,
      name: "Weighted Shipping",
      calculator: Spree::Calculator::Shipping::WeightedShipping.new
    )
    order = create(
      :order_with_line_items,
      currency: "USD",
      shipping_method:,
      shipment_cost: 0,
      line_items_attributes:
    )
    shipping_method.zones.first.members.create!(zoneable: order.ship_address.country)
    [order, shipping_method]
  end

  it "shows, validates, and persists the canonical admin preferences" do
    shipping_method = create(
      :shipping_method,
      name: "Weighted Shipping",
      calculator: Spree::Calculator::Shipping::WeightedShipping.new
    )

    visit spree.edit_admin_shipping_method_path(shipping_method)

    expect(page).to have_select("Base Calculator", selected: "Weighted Shipping")
    expect(page).to have_field(
      "Rate table (maximum weight: price, one band per line)",
      with: Spree::Calculator::Shipping::WeightedShipping::DEFAULT_RATE_TABLE
    )
    expect(page).to have_field("Maximum weight of one item", with: "18")

    fill_in "Rate table (maximum weight: price, one band per line)", with: "2: 4\n10: 7"
    fill_in "Order merchandise total above which shipping is free", with: "250"
    click_button "Update"

    expect(page).to have_content("successfully updated")
    expect(shipping_method.reload.calculator.preferred_rate_table).to eq("2: 4\n10: 7")
    expect(shipping_method.calculator.preferred_free_shipping_threshold).to eq(decimal("250"))
    capture_screenshot("01-admin-calculator-config")

    fill_in "Rate table (maximum weight: price, one band per line)", with: "2: 4\n1: 7"
    click_button "Update"

    expect(page).to have_content("weight thresholds must be strictly increasing")
    expect(shipping_method.reload.calculator.preferred_rate_table).to eq("2: 4\n10: 7")
    capture_screenshot("08-admin-invalid-config")
  end

  it "shows normal, threshold-crossing, and unavailable customer estimates" do
    variant = create(:variant, weight: "1", width: "10", depth: "10", height: "10")
    order, = create_preview_order(
      line_items_attributes: [{variant:, price: decimal("100")}]
    )

    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("Shipping options")
    expect(page).to have_content("Package 1")
    expect(page).to have_content("Weighted Shipping")
    expect(page).to have_content("USD 6.00")
    capture_screenshot("02-checkout-normal-rate")

    variant.update!(weight: decimal("1.01"))
    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("Weighted Shipping")
    expect(page).to have_content("USD 9.00")
    expect(page).not_to have_content("USD 6.00")
    capture_screenshot("03-checkout-threshold-rate")

    variant.update!(weight: decimal("20"))
    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("No shipping option is available for this package.")
    capture_screenshot("04-checkout-oversized-unavailable")
  end

  it "shows free shipping from the order-scoped threshold" do
    variant = create(:variant, weight: "10", width: "10", depth: "10", height: "10")
    order, = create_preview_order(
      line_items_attributes: [{variant:, price: decimal("120.01")}]
    )

    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("Weighted Shipping")
    expect(page).to have_content("USD 0.00")
    capture_screenshot("05-checkout-free-shipping")
  end

  it "shows one independently calculated rate for each Solidus package" do
    light = create(:variant, weight: "1", width: "10", depth: "10", height: "10")
    heavier = create(:variant, weight: "2", width: "10", depth: "10", height: "10")
    order, = create_preview_order(
      line_items_attributes: [
        {variant: light, price: decimal("40")},
        {variant: heavier, price: decimal("80")}
      ]
    )
    first_shipment = order.shipments.first!
    second_shipment = order.shipments.create!(
      stock_location: create(:stock_location),
      state: "pending",
      cost: 0
    )
    first_shipment.inventory_units.order(:id).last!.update!(shipment: second_shipment)

    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("Package 1")
    expect(page).to have_content("Package 2")
    expect(page).to have_content("USD 16.00")
    expect(page).to have_content("USD 9.00")
    capture_screenshot("06-checkout-multi-package")
  end

  it "shows the selected weighted rate on a completed order in Solidus admin" do
    shipping_method = create(
      :shipping_method,
      name: "Weighted Shipping",
      calculator: Spree::Calculator::Shipping::WeightedShipping.new
    )
    variant = create(:variant, weight: "10", width: "10", depth: "10", height: "10")
    order = create(
      :completed_order_with_totals,
      currency: "USD",
      shipping_method:,
      shipment_cost: decimal("15"),
      line_items_attributes: [{variant:, price: decimal("100")}]
    )

    visit spree.edit_admin_order_path(order)

    expect(page).to have_content(order.number)
    expect(page).to have_content("Weighted Shipping")
    expect(page).to have_content("$15.00")
    capture_screenshot("07-admin-completed-order-rate")
  end
end
