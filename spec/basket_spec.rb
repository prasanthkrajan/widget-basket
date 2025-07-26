# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Basket do
  let(:product_catalogue) { ['R01', 'G01', 'B01'] }
  let(:delivery_charge_rules) { DeliveryRules.new }
  let(:offers) { [] }
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
        basket.add('R01')
        basket.add('G01')
      end

      it 'adds additional product to basket' do
        basket.add('B01')
        expect(basket.items.length).to eq(3)
      end
    end

    context 'with invalid product code' do
      it 'raises error for invalid product code' do
        expect { basket.add('INVALID') }.to raise_error(ArgumentError)
      end
    end

    context 'with valid product codes' do
      it 'accepts R01 product code' do
        expect { basket.add('R01') }.not_to raise_error
      end

      it 'accepts G01 product code' do
        expect { basket.add('G01') }.not_to raise_error
      end

      it 'accepts B01 product code' do
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
      basket = Basket.new(product_catalogue: product_catalogue, delivery_charge_rules: DeliveryRules.new, offers: offers)
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
  end
end 