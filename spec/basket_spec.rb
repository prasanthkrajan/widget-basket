# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Basket do
  let(:product_catalogue) { { 'R01' => 32.95, 'G01' => 24.95, 'B01' => 7.95 } }
  let(:delivery_charge_rules) { DeliveryChargeRules.new }
  let(:offers) { [PairDiscountOffer.new('R01', 0.5)] }
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