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
    capture_screenshot("admin-weighted-shipping")

    fill_in "Rate table (maximum weight: price, one band per line)", with: "2: 4\n1: 7"
    click_button "Update"

    expect(page).to have_content("weight thresholds must be strictly increasing")
    expect(shipping_method.reload.calculator.preferred_rate_table).to eq("2: 4\n10: 7")
    capture_screenshot("admin-weighted-shipping-invalid")
  end

  it "renders customer-visible available and unavailable estimates" do
    variant = create(:variant, weight: "10", width: "10", depth: "10", height: "10")
    calculator = Spree::Calculator::Shipping::WeightedShipping.new
    shipping_method = create(:shipping_method, name: "Weighted Shipping", calculator:)
    order = create(
      :order_with_line_items,
      currency: "USD",
      shipping_method:,
      shipment_cost: 0,
      line_items_attributes: [{variant:, price: decimal("100")}]
    )
    shipping_method.zones.first.members.create!(zoneable: order.ship_address.country)

    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("Shipping options")
    expect(page).to have_content("Weighted Shipping")
    expect(page).to have_content("USD 15.00")
    capture_screenshot("customer-weighted-shipping-rate")

    variant.update!(weight: decimal("20"))
    visit "/weighted-shipping-preview/#{order.id}"

    expect(page).to have_content("No shipping option is available for this package.")
    capture_screenshot("customer-weighted-shipping-unavailable")
  end
end
