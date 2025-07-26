# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Basket do
  let(:basket) { Basket.new }

  describe '#add' do
    it 'adds a product to the basket' do
      basket.add('R01')
      expect(basket.items.length).to eq(1)
    end

    it 'raises error for invalid product code' do
      expect { basket.add('INVALID') }.to raise_error(ArgumentError)
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
  end
end 