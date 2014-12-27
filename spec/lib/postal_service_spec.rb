RSpec.describe Spree::Calculator::Shipping::PostalService do
  subject { described_class.new }

  context 'returns description' do
    %w(en pt sv).each do |locale|
      it "in supported language: #{locale}" do
        I18n.with_locale(locale.to_sym) do
          expect(described_class.description).to eq Spree.t(:postal_service)
        end
      end
    end
  end

  describe 'using the default weight-price table: [1 2 5 10 20] => [6 9 12 15 18]' do
    context '.compute(package)' do
      it 'gives 15.0 when total price is 100 and weight is 10kg' do
        create_our_package(weight: 10.0, price: 100.0, quantity: 1)
        result = subject.compute(@package)
        expect(result).to eq(15.0)
      end

      it 'gives 25.0 when total price is 40 and weight is 10kg' do
        create_our_package(weight: 10.0, price: 40.0, quantity: 1)
        result = subject.compute(@package)
        expect(result).to eq(25.0)
      end

      it 'gives 6 when total price is 60 and weight is less than 1kg' do
        create_our_package(weight: 0.5, price: 60.0, quantity: 1)
        result = subject.compute(@package)
        expect(result).to eq(6.0)
      end

      it 'gives 16 when total price is 40 and weight is less than 1kg' do
        create_our_package(weight: 0.5, price: 40.0, quantity: 1)
        result = subject.compute(@package)
        expect(result).to eq(16.0)
      end

      it 'gives 30 when total price is 200 and weight is 25kg (split into two)' do
        create_our_package(weight: 25.0, price: 200.0, quantity: 1)
        subject.preferred_max_price = 250
        result = subject.compute(@package)
        expect(result).to eq(30.0)
      end

      it 'gives 12 when total price is 100, there are three items and their weight is unknown' do
        order   = create(:order)
        variant = create(:base_variant, weight: nil)
        [30.0, 40.0, 30.0].each { |price| create_line_item(order, variant, price: price) }
        order.line_items.reload
        package = create(:shipment, order: order)
        result  = subject.compute(package)
        expect(result).to eq(12.0)
      end

      it 'gives 0 when total price is more than the MAX, for any number of items' do
        create_our_package(weight: 25.0, price: 350.0, quantity: 1)
        subject.preferred_max_price = 300
        result = subject.compute(@package)
        expect(result).to eq(0.0)
      end
    end
  end

  describe 'when preferred max weight, length and width are 18 kg, 120 cm and 60 cm' do
    context '.available?(package)' do
      it 'is false when item weighs more than 18kg' do
        create_our_package(weight: 20, height: 70, width: 30, depth: 30)
        expect(subject.available?(@package)).to be(false)
      end

      it 'is false when item is longer than 120cm' do
        create_our_package(weight: 10, height: 130, width: 30, depth: 30)
        expect(subject.available?(@package)).to be(false)
      end

      it 'is false when item is wider than 60cm' do
        create_our_package(weight: 10, height: 80, width: 70, depth: 30)
        expect(subject.available?(@package)).to be(false)
      end
    end

    context '.item_oversized?(variant)' do
      it 'is true if the longest side is more than 120cm' do
        create_our_package(weight: 10, height: 130, width: 40, depth: 30)
        expect(subject.item_oversized?(@variant)).to be(true)
      end

      it 'is true if the second longest side is more than 60cm' do
        create_our_package(weight: 10, height: 80, width: 70, depth: 30)
        expect(subject.item_oversized?(@variant)).to be(true)
      end
    end
  end

  def create_our_package(args = {})
    @variant = create :base_variant, args.except!(:quantity)
    order = create :order
    create_line_item(order, @variant, args)
    order.line_items.reload
    @package = create :shipment, order: order
  end

  def create_line_item(order, variant, args = {})
    create(
      :line_item,
      price:    args[:price] || BigDecimal.new('10.00'),
      quantity: args[:quantity] || 1,
      order:    order,
      variant:  variant
    )
  end
end
