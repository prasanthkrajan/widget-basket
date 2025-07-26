# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PairDiscountOffer do
  describe '#conflicts_with?' do
    it 'returns true for another PairDiscountOffer with the same product code' do
      offer1 = PairDiscountOffer.new('R01', 0.5)
      offer2 = PairDiscountOffer.new('R01', 0.7)
      expect(offer1.conflicts_with?(offer2)).to be true
    end

    it 'returns false for another PairDiscountOffer with different product code' do
      offer1 = PairDiscountOffer.new('R01', 0.5)
      offer2 = PairDiscountOffer.new('G01', 0.3)
      expect(offer1.conflicts_with?(offer2)).to be false
    end

    it 'returns false for non-PairDiscountOffer offers' do
      class DummyOffer < Offer
        def initialize(product_code); @product_code = product_code; end
        def calculate_discount(*); 0; end
        def product_code; @product_code; end
      end
      
      pair_offer = PairDiscountOffer.new('R01', 0.5)
      dummy_offer = DummyOffer.new('R01')
      expect(pair_offer.conflicts_with?(dummy_offer)).to be false
    end
  end

  describe '.validate_collection!' do
    it 'raises ArgumentError if multiple pair offers are present for the same product' do
      offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('R01', 0.7)]
      expect {
        PairDiscountOffer.validate_collection!(offers)
      }.to raise_error(ArgumentError, /Multiple pair offers found for product 'R01'/)
    end

    it 'does not raise error if pair offers are for different products' do
      offers = [PairDiscountOffer.new('R01', 0.5), PairDiscountOffer.new('G01', 0.3)]
      expect {
        PairDiscountOffer.validate_collection!(offers)
      }.not_to raise_error
    end

    it 'does not raise error if only one pair offer per product' do
      offers = [PairDiscountOffer.new('R01', 0.5)]
      expect {
        PairDiscountOffer.validate_collection!(offers)
      }.not_to raise_error
    end

    it 'does not raise error if no pair offers are present' do
      offers = []
      expect {
        PairDiscountOffer.validate_collection!(offers)
      }.not_to raise_error
    end

    it 'does not raise error if other offer types are present with pair offers' do
      class DummyOffer < Offer
        def initialize(product_code); @product_code = product_code; end
        def calculate_discount(*); 0; end
        def product_code; @product_code; end
      end
      
      offers = [PairDiscountOffer.new('R01', 0.5), DummyOffer.new('R01')]
      expect {
        PairDiscountOffer.validate_collection!(offers)
      }.not_to raise_error
    end
  end

  describe '#initialize' do
    context 'with valid parameters' do
      it 'initializes with default parameters' do
        offer = PairDiscountOffer.new
        expect(offer.product_code).to eq('R01')
        expect(offer.discount_percentage).to eq(0.5)
      end

      it 'initializes with custom parameters' do
        offer = PairDiscountOffer.new('G01', 0.3)
        expect(offer.product_code).to eq('G01')
        expect(offer.discount_percentage).to eq(0.3)
      end
    end

    context 'with invalid parameters' do
      it 'raises error for nil product_code' do
        expect { PairDiscountOffer.new(nil, 0.5) }.to raise_error(ArgumentError, 'product_code cannot be nil')
      end

      it 'raises error for non-string product_code' do
        expect { PairDiscountOffer.new(123, 0.5) }.to raise_error(ArgumentError, 'product_code must be a string')
        expect { PairDiscountOffer.new([], 0.5) }.to raise_error(ArgumentError, 'product_code must be a string')
        expect { PairDiscountOffer.new({}, 0.5) }.to raise_error(ArgumentError, 'product_code must be a string')
      end

      it 'raises error for empty product_code' do
        expect { PairDiscountOffer.new('', 0.5) }.to raise_error(ArgumentError, 'product_code cannot be empty')
        expect { PairDiscountOffer.new('   ', 0.5) }.to raise_error(ArgumentError, 'product_code cannot be empty')
      end

      it 'raises error for nil discount_percentage' do
        expect { PairDiscountOffer.new('R01', nil) }.to raise_error(ArgumentError, 'discount_percentage cannot be nil')
      end

      it 'raises error for non-numeric discount_percentage' do
        expect { PairDiscountOffer.new('R01', 'invalid') }.to raise_error(ArgumentError, 'discount_percentage must be numeric')
        expect { PairDiscountOffer.new('R01', []) }.to raise_error(ArgumentError, 'discount_percentage must be numeric')
        expect { PairDiscountOffer.new('R01', {}) }.to raise_error(ArgumentError, 'discount_percentage must be numeric')
      end

      it 'raises error for discount_percentage less than 0' do
        expect { PairDiscountOffer.new('R01', -0.1) }.to raise_error(ArgumentError, 'discount_percentage must be between 0 and 1')
      end

      it 'raises error for discount_percentage greater than 1' do
        expect { PairDiscountOffer.new('R01', 1.1) }.to raise_error(ArgumentError, 'discount_percentage must be between 0 and 1')
      end

      it 'accepts discount_percentage of 0' do
        offer = PairDiscountOffer.new('R01', 0)
        expect(offer.discount_percentage).to eq(0)
      end

      it 'accepts discount_percentage of 1' do
        offer = PairDiscountOffer.new('R01', 1)
        expect(offer.discount_percentage).to eq(1)
      end
    end
  end

  describe '#calculate_discount' do
    let(:offer) { PairDiscountOffer.new('R01', 0.5) }
    let(:product_catalogue) { ProductCatalogue.new }

    it 'calculates discount for one pair' do
      items = ['R01', 'R01']
      discount = offer.calculate_discount(items, product_catalogue)
      expect(discount).to eq(16.48)
    end

    it 'calculates discount for multiple pairs' do
      items = ['R01', 'R01', 'R01', 'R01']
      discount = offer.calculate_discount(items, product_catalogue)
      expect(discount).to eq(32.95)
    end

    it 'returns zero discount for odd number of items' do
      items = ['R01', 'R01', 'R01']
      discount = offer.calculate_discount(items, product_catalogue)
      expect(discount).to eq(16.48)
    end

    it 'returns zero discount for single item' do
      items = ['R01']
      discount = offer.calculate_discount(items, product_catalogue)
      expect(discount).to eq(0.0)
    end
  end
end 