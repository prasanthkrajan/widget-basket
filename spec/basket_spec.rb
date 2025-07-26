# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Basket do
  let(:product_catalogue) { { 'R01' => 32.95, 'G01' => 24.95, 'B01' => 7.95 } }
  let(:delivery_charge_rules) { DeliveryChargeRules.new }
  let(:offers) { [PairDiscountOffer.new('R01', 0.5)] }
  let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers) }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'initializes successfully with valid product_catalogue, delivery_charge_rules and offers' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.not_to raise_error
      end

      it 'initializes successfully with multiple offers' do
        multiple_offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('G01', 0.3)]
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: multiple_offers)
        }.not_to raise_error
      end

      it 'initializes successfully with custom delivery_charge_rules object' do
        custom_rules = Class.new do
          def calculate_cost(order_total)
            5.0
          end
        end.new
        
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: custom_rules, offers: offers)
        }.not_to raise_error
      end

      it 'initializes successfully with custom offer object' do
        custom_offer = Class.new do
          def calculate_discount(items, product_catalogue)
            0.0
          end
        end.new
        
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: [custom_offer])
        }.not_to raise_error
      end

      it 'initializes successfully with nil delivery_charge_rules' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: nil)
        }.not_to raise_error
      end

      it 'initializes successfully with empty offers' do
        expect {
          Basket.new(product_catalogue: product_catalogue, offers: [])
        }.not_to raise_error
      end

      it 'initializes successfully with nil delivery_charge_rules and empty offers' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: nil, offers: [])
        }.not_to raise_error
      end

      it 'initializes successfully with only product_catalogue' do
        expect {
          Basket.new(product_catalogue: product_catalogue)
        }.not_to raise_error
      end

      it 'initializes successfully with only product_catalogue and delivery_charge_rules' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules)
        }.not_to raise_error
      end

      it 'initializes successfully with only product_catalogue and offers' do
        expect {
          Basket.new(product_catalogue: product_catalogue, offers: offers)
        }.not_to raise_error
      end

      it 'raises error when initialized with conflicting pair offers' do
        conflicting_offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('R01', 0.7)]
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: conflicting_offers)
        }.to raise_error(ArgumentError, /Multiple pair offers found for product 'R01'/)
      end

      it 'raises error without product_catalogue' do
        expect {
          Basket.new(delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, /missing keyword/)
      end
    end

    context 'with invalid product_catalogue' do
      it 'raises error if product_catalogue is nil' do
        expect {
          Basket.new(product_catalogue: nil, delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, 'product_catalogue cannot be nil')
      end

      it 'raises error if product_catalogue is empty' do
        expect {
          Basket.new(product_catalogue: {}, delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, 'product_catalogue cannot be empty')
      end

      it 'raises error if product_catalogue is a string' do
        expect {
          Basket.new(product_catalogue: 'invalid', delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, 'product_catalogue must be a Hash')
      end

      it 'raises error if product_catalogue is an integer' do
        expect {
          Basket.new(product_catalogue: 123, delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, 'product_catalogue must be a Hash')
      end

      it 'raises error if product_catalogue is an array' do
        expect {
          Basket.new(product_catalogue: [], delivery_charge_rules: delivery_charge_rules, offers: offers)
        }.to raise_error(ArgumentError, 'product_catalogue must be a Hash')
      end

      context 'with invalid product prices' do
        it 'raises error if product price is negative' do
          invalid_catalogue = { 'R01' => -5.0, 'G01' => 24.95 }
          expect {
            Basket.new(product_catalogue: invalid_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
          }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
        end

        it 'raises error if product price is nil' do
          invalid_catalogue = { 'R01' => nil, 'G01' => 24.95 }
          expect {
            Basket.new(product_catalogue: invalid_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
          }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
        end

        it 'raises error if product price is a string' do
          invalid_catalogue = { 'R01' => '32.95', 'G01' => 24.95 }
          expect {
            Basket.new(product_catalogue: invalid_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
          }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
        end

        it 'raises error if product price is zero' do
          invalid_catalogue = { 'R01' => 0.0, 'G01' => 24.95 }
          expect {
            Basket.new(product_catalogue: invalid_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
          }.to raise_error(ArgumentError, 'product prices must be positive numbers')
        end
      end
    end

    context 'with invalid delivery_charge_rules' do
      it 'raises error if delivery_charge_rules does not respond to calculate_cost' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: Object.new, offers: offers)
        }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
      end

      it 'raises error if delivery_charge_rules is a string' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: 'invalid', offers: offers)
        }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
      end

      it 'raises error if delivery_charge_rules is an integer' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: 123, offers: offers)
        }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
      end

      it 'raises error if delivery_charge_rules is an array' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: [], offers: offers)
        }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
      end

      it 'raises error if delivery_charge_rules is a hash' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: {}, offers: offers)
        }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
      end
    end

    context 'with invalid offers' do
      it 'raises error if offers is nil' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: nil)
        }.to raise_error(ArgumentError, 'offers must be an Array')
      end

      it 'raises error if offers contains objects that do not respond to calculate_discount' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: [Object.new])
        }.to raise_error(ArgumentError, 'each offer must respond to calculate_discount')
      end

      it 'raises error if offers is a string' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: 'invalid')
        }.to raise_error(ArgumentError, 'offers must be an Array')
      end

      it 'raises error if offers is an integer' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: 123)
        }.to raise_error(ArgumentError, 'offers must be an Array')
      end

      it 'raises error if offers is a hash' do
        expect {
          Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: {})
        }.to raise_error(ArgumentError, 'offers must be an Array')
      end
    end
  end

  describe '#add' do
    context 'when basket is empty' do
      it 'adds first product to basket' do
        basket.add('R01')
        expect(basket.items.length).to eq(1)
      end
    end

    context 'when basket already has items' do
      before do
        basket.add('G01')
        basket.add('B01')
      end

      it 'adds additional product to basket' do
        basket.add('R01')
        expect(basket.items.length).to eq(3)
      end
    end

    context 'with invalid product code' do
      it 'raises ArgumentError' do
        expect { basket.add('INVALID') }.to raise_error(ArgumentError)
      end

      it 'raises descriptive error message' do
        expect { basket.add('INVALID') }.to raise_error(ArgumentError, "Product code 'INVALID' not found in catalogue")
      end
    end

    context 'with valid product codes' do
      it 'accepts R01' do
        expect { basket.add('R01') }.not_to raise_error
      end

      it 'accepts G01' do
        expect { basket.add('G01') }.not_to raise_error
      end

      it 'accepts B01' do
        expect { basket.add('B01') }.not_to raise_error
      end
    end

    context 'with invalid product code types' do
      it 'raises error if product_code is nil' do
        expect { basket.add(nil) }.to raise_error(ArgumentError, 'product_code must be a string')
      end

      it 'raises error if product_code is an integer' do
        expect { basket.add(123) }.to raise_error(ArgumentError, 'product_code must be a string')
      end

      it 'raises error if product_code is a symbol' do
        expect { basket.add(:R01) }.to raise_error(ArgumentError, 'product_code must be a string')
      end

      it 'raises error if product_code is an empty string' do
        expect { basket.add('') }.to raise_error(ArgumentError, 'product_code cannot be empty')
      end

      it 'raises error if product_code is whitespace only' do
        expect { basket.add('   ') }.to raise_error(ArgumentError, 'product_code cannot be empty')
      end
    end
  end

  describe '#total' do

    it 'calculates total for B01, G01 basket' do
      basket.add('B01')
      basket.add('G01')
      expect(basket.total).to eq(37.85)
    end

    it 'calculates total for R01, R01 basket' do
      basket.add('R01')
      basket.add('R01')
      expect(basket.total).to eq(54.37)
    end

    it 'calculates total for R01, G01 basket' do
      basket.add('R01')
      basket.add('G01')
      expect(basket.total).to eq(60.85)
    end

    it 'calculates total for B01, B01, R01, R01, R01 basket' do
      basket.add('B01')
      basket.add('B01')
      basket.add('R01')
      basket.add('R01')
      basket.add('R01')
      expect(basket.total).to eq(98.27)
    end

    context 'with nil delivery_charge_rules' do
      let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: nil, offers: offers) }

      it 'calculates total without delivery charges' do
        basket.add('R01')
        basket.add('G01')
        # R01 = 32.95, G01 = 24.95, subtotal = 57.90
        # Discount: 0 (no pairs), delivery: 0 (nil rules), total = 57.90
        expect(basket.total).to eq(57.90)
      end

      it 'calculates total with discounts but no delivery charges' do
        basket.add('R01')
        basket.add('R01')
        # R01 = 32.95 each, 1 pair, half price = 16.48 discount, subtotal = 49.42
        # Delivery: 0 (nil rules), total = 49.42
        expect(basket.total).to eq(49.42)
      end

      it 'calculates total for single product without delivery charges' do
        basket.add('R01')
        # R01 = 32.95, subtotal = 32.95
        # Discount: 0, delivery: 0 (nil rules), total = 32.95
        expect(basket.total).to eq(32.95)
      end
    end

    context 'with empty offers' do
      let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: []) }

      it 'calculates total without discounts' do
        basket.add('R01')
        basket.add('R01')
        # R01 = 32.95 each, subtotal = 65.90
        # Discount: 0 (empty offers), delivery: 2.95 (since 65.90 >= 50), total = 68.85
        expect(basket.total).to eq(68.85)
      end

      it 'calculates total for multiple products without discounts' do
        basket.add('B01')
        basket.add('G01')
        basket.add('R01')
        # B01 = 7.95, G01 = 24.95, R01 = 32.95, subtotal = 65.85
        # Discount: 0 (empty offers), delivery: 2.95 (since 65.85 >= 50), total = 68.80
        expect(basket.total).to eq(68.80)
      end

      it 'calculates total for small order without discounts' do
        basket.add('B01')
        # B01 = 7.95, subtotal = 7.95
        # Discount: 0 (empty offers), delivery: 4.95 (since 7.95 < 50), total = 12.90
        expect(basket.total).to eq(12.90)
      end
    end

    context 'with nil delivery_charge_rules and empty offers' do
      let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: nil, offers: []) }

      it 'calculates product-only total' do
        basket.add('R01')
        basket.add('G01')
        basket.add('B01')
        # R01 = 32.95, G01 = 24.95, B01 = 7.95, subtotal = 65.85
        # Discount: 0 (empty offers), delivery: 0 (nil rules), total = 65.85
        expect(basket.total).to eq(65.85)
      end

      it 'calculates total for single product' do
        basket.add('R01')
        # R01 = 32.95, subtotal = 32.95
        # Discount: 0 (empty offers), delivery: 0 (nil rules), total = 32.95
        expect(basket.total).to eq(32.95)
      end
    end

    context 'pair discount offer applies to any product code and discount' do
      it 'applies 50% discount to second R01' do
        basket.add('R01')
        basket.add('R01')
        # R01 = 32.95 each, 1 pair, half price = 16.48 discount, subtotal = 49.42
        # Delivery: 4.95, total = 54.37
        expect(basket.total).to eq(54.37)
      end

      it 'applies 30% discount to second G01 if configured' do
        offers = [PairDiscountOffer.new('G01', 0.3)]
        basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
        basket.add('G01')
        basket.add('G01')
        # G01 = 24.95 each, 1 pair, 30% off = 7.49 discount, subtotal = 42.41
        # Delivery: 4.95, total = 47.36
        expect(basket.total).to eq(47.36)
      end

      it 'applies both R01 and G01 discounts if both offers are present' do
        offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('G01', 0.3)]
        basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers)
        basket.add('R01')
        basket.add('R01')
        basket.add('G01')
        basket.add('G01')
        # R01 = 32.95 each, G01 = 24.95 each
        # R01 discount: 16.48, G01 discount: 7.49
        # Subtotal: 32.95*2 + 24.95*2 = 115.80
        # Discounts: 16.48 + 7.49 = 23.97
        # Subtotal after discounts: 91.83
        # Delivery: free (since 91.83 >= 90), total = 91.83
        expect(basket.total).to eq(91.83)
      end
    end

    context 'with simple constructor (only product_catalogue)' do
      let(:basket) { Basket.new(product_catalogue: product_catalogue) }

      it 'calculates product-only total' do
        basket.add('R01')
        basket.add('G01')
        basket.add('B01')
        # R01 = 32.95, G01 = 24.95, B01 = 7.95, subtotal = 65.85
        # Discount: 0 (default empty offers), delivery: 0 (default nil rules), total = 65.85
        expect(basket.total).to eq(65.85)
      end

      it 'calculates total for single product' do
        basket.add('R01')
        # R01 = 32.95, subtotal = 32.95
        # Discount: 0 (default empty offers), delivery: 0 (default nil rules), total = 32.95
        expect(basket.total).to eq(32.95)
      end

      it 'calculates total for multiple products' do
        basket.add('R01')
        basket.add('R01')
        basket.add('G01')
        # R01 = 32.95 each, G01 = 24.95, subtotal = 90.85
        # Discount: 0 (default empty offers), delivery: 0 (default nil rules), total = 90.85
        expect(basket.total).to eq(90.85)
      end
    end

    context 'with negative discount offers' do
      it 'raises error when offer returns negative discount' do
        negative_discount_offer = Class.new do
          def calculate_discount(items, product_catalogue)
            -10.0  # Negative discount
          end
        end.new

        basket_with_negative_offer = Basket.new(
          product_catalogue: product_catalogue,
          delivery_charge_rules: delivery_charge_rules,
          offers: [negative_discount_offer]
        )

        basket_with_negative_offer.add('R01')
        expect { basket_with_negative_offer.total }.to raise_error(ArgumentError, 'discounts cannot be negative')
      end

      it 'raises error when multiple offers result in negative total discount' do
        # First offer gives positive discount, second gives larger negative discount
        positive_offer = Class.new do
          def calculate_discount(items, product_catalogue)
            5.0
          end
        end.new

        negative_offer = Class.new do
          def calculate_discount(items, product_catalogue)
            -15.0  # Larger negative discount
          end
        end.new

        basket_with_mixed_offers = Basket.new(
          product_catalogue: product_catalogue,
          delivery_charge_rules: delivery_charge_rules,
          offers: [positive_offer, negative_offer]
        )

        basket_with_mixed_offers.add('R01')
        expect { basket_with_mixed_offers.total }.to raise_error(ArgumentError, 'discounts cannot be negative')
      end
    end
  end
end 