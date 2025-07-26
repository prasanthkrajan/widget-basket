# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Basket do
  let(:product_catalogue) { ['R01', 'G01', 'B01'] }
  let(:delivery_charge_rules) { DeliveryChargeRules.new }
  let(:offers) { [HalfPriceOffer.new('R01')] }
  let(:basket) { Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: delivery_charge_rules, offers: offers) }

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
    it 'raises error if delivery_charge_rules is nil' do
      basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: nil, offers: offers)
      basket.add('R01')
      expect { basket.total }.to raise_error(ArgumentError, 'delivery_charge_rules cannot be nil')
    end

    it 'raises error if delivery_charge_rules does not respond to calculate_cost' do
      basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: Object.new, offers: offers)
      basket.add('R01')
      expect { basket.total }.to raise_error(ArgumentError, 'delivery_charge_rules must respond to calculate_cost')
    end

    it 'does not raise error if delivery_charge_rules responds to calculate_cost' do
      basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: DeliveryChargeRules.new, offers: offers)
      basket.add('R01')
      expect { basket.total }.not_to raise_error
    end

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

    context 'half-price offer only applies to R01' do
      it 'does not apply discount to G01, G01 basket' do
        basket.add('G01')
        basket.add('G01')
        # G01 = 24.95 each, total = 49.90, delivery = 4.95, total = 54.85
        expect(basket.total).to eq(54.85)
      end

      it 'does not apply discount to B01, B01 basket' do
        basket.add('B01')
        basket.add('B01')
        # B01 = 7.95 each, total = 15.90, delivery = 4.95, total = 20.85
        expect(basket.total).to eq(20.85)
      end

      it 'does not apply discount to G01, B01 basket' do
        basket.add('G01')
        basket.add('B01')
        # G01 = 24.95, B01 = 7.95, total = 32.90, delivery = 4.95, total = 37.85
        expect(basket.total).to eq(37.85)
      end

      it 'applies discount only to R01 pairs, not mixed products' do
        basket.add('R01')
        basket.add('G01')
        basket.add('R01')
        # R01 = 32.95, G01 = 24.95, R01 = 32.95, total = 90.85
        # Discount: 1 pair of R01 = 16.475 → 16.48, subtotal after discount = 74.37
        # Delivery: $2.95 (since 74.37 >= 50 but < 90), total = 77.32
        expect(basket.total).to eq(77.32)
      end

      it 'applies discount to multiple R01 pairs' do
        basket.add('R01')
        basket.add('R01')
        basket.add('R01')
        basket.add('R01')
        # 4 R01 = 131.80, 2 pairs = 32.95 discount, subtotal = 98.85
        # Delivery: free (98.85 >= 90), total = 98.85
        expect(basket.total).to eq(98.85)
      end
    end

    context 'half-price offer does not apply to any product except R01' do
      it 'raises ArgumentError if initialized with a code other than R01' do
        expect { HalfPriceOffer.new('G01') }.to raise_error(ArgumentError, /only be applied to 'R01'/)
        expect { HalfPriceOffer.new('B01') }.to raise_error(ArgumentError, /only be applied to 'R01'/)
      end
    end
  end
end 