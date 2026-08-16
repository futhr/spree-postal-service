# frozen_string_literal: true

module SolidusWeightedShipping
  class TestPreviewController < ActionController::Base
    layout false

    def show
      order = Spree::Order.find(params[:order_id])
      shipment = order.shipments.first!
      contents = order.inventory_units.map { |unit| Spree::Stock::ContentItem.new(unit) }
      package = Spree::Stock::Package.new(shipment.stock_location, contents)
      package.shipment = package.to_shipment
      rates = Spree::Stock::Estimator.new.shipping_rates(package)

      render inline: TEMPLATE, locals: {order:, rates:}
    end

    TEMPLATE = <<~ERB
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <link rel="icon" href="data:,">
          <title>Shipping options</title>
          <style>
            :root { color-scheme: light; font-family: Inter, ui-sans-serif, system-ui, sans-serif; }
            body { background: #f4f5f7; color: #17212b; margin: 0; padding: 4rem; }
            main { background: white; border: 1px solid #d9dee5; border-radius: 14px; box-shadow: 0 12px 30px rgb(17 24 39 / 8%); margin: 0 auto; max-width: 760px; padding: 2.5rem; }
            h1 { font-size: 2rem; margin: 0 0 .5rem; }
            .order { color: #5b6573; margin-bottom: 2rem; }
            .rate { align-items: center; border: 2px solid #2f6fed; border-radius: 10px; display: flex; justify-content: space-between; padding: 1.25rem; }
            .name { font-size: 1.1rem; font-weight: 700; }
            .price { color: #174eae; font-size: 1.35rem; font-weight: 800; }
            .empty { background: #fff5f5; border: 1px solid #e58a8a; border-radius: 10px; color: #8d2525; padding: 1.25rem; }
          </style>
        </head>
        <body>
          <main>
            <h1>Shipping options</h1>
            <p class="order">Order <%= ERB::Util.html_escape(order.number) %></p>
            <% if rates.empty? %>
              <p class="empty">No shipping option is available for this package.</p>
            <% else %>
              <% rates.each do |rate| %>
                <section class="rate">
                  <span class="name"><%= ERB::Util.html_escape(rate.shipping_method.name) %></span>
                  <span class="price"><%= ERB::Util.html_escape(order.currency) %> <%= format("%.2f", rate.cost) %></span>
                </section>
              <% end %>
            <% end %>
          </main>
        </body>
      </html>
    ERB
  end
end
