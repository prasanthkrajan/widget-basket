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