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

    describe 'validation methods' do
      let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers) }

      describe '#validate_product_catalogue!' do
        it 'raises error for nil product_catalogue' do
          expect {
            basket.send(:validate_product_catalogue!, nil)
          }.to raise_error(ArgumentError, 'product_catalogue cannot be nil')
        end

        it 'raises error for non-hash product_catalogue' do
          expect {
            basket.send(:validate_product_catalogue!, 'invalid')
          }.to raise_error(ArgumentError, 'product_catalogue must be a Hash')
        end

        it 'raises error for empty product_catalogue' do
          expect {
            basket.send(:validate_product_catalogue!, {})
          }.to raise_error(ArgumentError, 'product_catalogue cannot be empty')
        end

        it 'does not raise error for valid product_catalogue' do
          expect {
            basket.send(:validate_product_catalogue!, product_catalogue)
          }.not_to raise_error
        end
      end

      describe '#validate_delivery_charge_rules!' do
        it 'does not raise error for nil delivery_charge_rules' do
          expect {
            basket.send(:validate_delivery_charge_rules!, nil)
          }.not_to raise_error
        end

        it 'does not raise error for valid delivery_charge_rules' do
          expect {
            basket.send(:validate_delivery_charge_rules!, delivery_charge_rules)
          }.not_to raise_error
        end

        it 'raises error for invalid delivery_charge_rules' do
          expect {
            basket.send(:validate_delivery_charge_rules!, Object.new)
          }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
        end
      end

      describe '#validate_offers!' do
        it 'raises error for non-array offers' do
          expect {
            basket.send(:validate_offers!, 'invalid')
          }.to raise_error(ArgumentError, 'offers must be an Array')
        end

        it 'does not raise error for empty offers' do
          expect {
            basket.send(:validate_offers!, [])
          }.not_to raise_error
        end

        it 'does not raise error for valid offers' do
          expect {
            basket.send(:validate_offers!, offers)
          }.not_to raise_error
        end

        it 'raises error for offers with invalid objects' do
          expect {
            basket.send(:validate_offers!, [Object.new])
          }.to raise_error(ArgumentError, 'each offer must respond to calculate_discount')
        end

        it 'raises error for multiple pair offers on same product' do
          conflicting_offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('R01', 0.7)]
          expect {
            basket.send(:validate_offers!, conflicting_offers)
          }.to raise_error(ArgumentError, /Multiple pair offers found for product 'R01'/)
        end

        it 'does not raise error for pair offers on different products' do
          valid_offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('G01', 0.3)]
          expect {
            basket.send(:validate_offers!, valid_offers)
          }.not_to raise_error
        end
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
        # Discount: 0, delivery: 0, total = 32.95
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
  end
end 