# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductCatalogue do
  let(:default_products) do
    {
      'R01' => 32.95,
      'G01' => 24.95,
      'B01' => 7.95
    }
  end

  describe '#initialize' do
    context 'with no arguments' do
      it 'initializes with default products' do
        catalogue = ProductCatalogue.new
        expect(catalogue).to be_a(ProductCatalogue)
      end

      it 'uses default products when no products provided' do
        catalogue = ProductCatalogue.new
        expect(catalogue['R01']).to eq(32.95)
        expect(catalogue['G01']).to eq(24.95)
        expect(catalogue['B01']).to eq(7.95)
      end
    end

    context 'with custom products' do
      let(:custom_products) do
        {
          'A01' => 10.0,
          'B02' => 20.0,
          'C03' => 30.0
        }
      end

      it 'initializes with custom products' do
        catalogue = ProductCatalogue.new(custom_products)
        expect(catalogue).to be_a(ProductCatalogue)
      end

      it 'uses custom products for lookup' do
        catalogue = ProductCatalogue.new(custom_products)
        expect(catalogue['A01']).to eq(10.0)
        expect(catalogue['B02']).to eq(20.0)
        expect(catalogue['C03']).to eq(30.0)
      end
    end

    context 'with nil products' do
      it 'uses default products when nil provided' do
        catalogue = ProductCatalogue.new(nil)
        expect(catalogue['R01']).to eq(32.95)
        expect(catalogue['G01']).to eq(24.95)
        expect(catalogue['B01']).to eq(7.95)
      end
    end
  end

  describe '#[]' do
    let(:catalogue) { ProductCatalogue.new }

    it 'returns product price for valid product code' do
      expect(catalogue['R01']).to eq(32.95)
      expect(catalogue['G01']).to eq(24.95)
      expect(catalogue['B01']).to eq(7.95)
    end

    it 'returns nil for invalid product code' do
      expect(catalogue['INVALID']).to be_nil
      expect(catalogue['']).to be_nil
      expect(catalogue[nil]).to be_nil
    end
  end

  describe '#key?' do
    let(:catalogue) { ProductCatalogue.new }

    it 'returns true for valid product codes' do
      expect(catalogue.key?('R01')).to be true
      expect(catalogue.key?('G01')).to be true
      expect(catalogue.key?('B01')).to be true
    end

    it 'returns false for invalid product codes' do
      expect(catalogue.key?('INVALID')).to be false
      expect(catalogue.key?('')).to be false
      expect(catalogue.key?(nil)).to be false
    end
  end

  describe '#to_h' do
    let(:catalogue) { ProductCatalogue.new }

    it 'returns a copy of the products hash' do
      products_hash = catalogue.to_h
      expect(products_hash).to eq(default_products)
      expect(products_hash).not_to be(catalogue.instance_variable_get(:@products))
    end

    it 'returns immutable copy' do
      products_hash = catalogue.to_h
      products_hash['NEW'] = 100.0
      expect(catalogue['NEW']).to be_nil
    end
  end

  describe 'validation' do
    context 'with invalid products' do
      it 'raises error if products is nil' do
        expect {
          ProductCatalogue.new(nil)
        }.not_to raise_error  # nil uses defaults
      end

      it 'raises error if products is empty' do
        expect {
          ProductCatalogue.new({})
        }.to raise_error(ArgumentError, 'products cannot be empty')
      end

      it 'raises error if products is not a hash' do
        expect {
          ProductCatalogue.new('invalid')
        }.to raise_error(ArgumentError, 'products must be a Hash')
      end

      it 'raises error if products is an array' do
        expect {
          ProductCatalogue.new([])
        }.to raise_error(ArgumentError, 'products must be a Hash')
      end

      it 'raises error if products is an integer' do
        expect {
          ProductCatalogue.new(123)
        }.to raise_error(ArgumentError, 'products must be a Hash')
      end
    end

    context 'with invalid product prices' do
      it 'raises error if product price is negative' do
        expect {
          ProductCatalogue.new({ 'R01' => -5.0 })
        }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
      end

      it 'raises error if product price is nil' do
        expect {
          ProductCatalogue.new({ 'R01' => nil })
        }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
      end

      it 'raises error if product price is a string' do
        expect {
          ProductCatalogue.new({ 'R01' => '32.95' })
        }.to raise_error(ArgumentError, 'product prices must be non-negative numbers')
      end

      it 'raises error if product price is zero' do
        expect {
          ProductCatalogue.new({ 'R01' => 0.0 })
        }.to raise_error(ArgumentError, 'product prices must be positive numbers')
      end
    end
  end

  describe 'integration with Basket' do
    it 'works correctly with Basket.new' do
      catalogue = ProductCatalogue.new
      basket = Basket.new(
        product_catalogue: catalogue,
        delivery_charge_rules: DeliveryChargeRules.new,
        offers: Offers.new
      )
      
      basket.add('R01')
      basket.add('G01')
      
      # R01 = 32.95, G01 = 24.95, subtotal = 57.90
      # Discount: 0 (no pairs), delivery: 2.95 (since 57.90 >= 50), total = 60.85
      expect(basket.total).to eq(60.85)
    end

    it 'works correctly with custom products in Basket' do
      custom_catalogue = ProductCatalogue.new({
        'A01' => 10.0,
        'B02' => 20.0
      })
      
      basket = Basket.new(
        product_catalogue: custom_catalogue,
        delivery_charge_rules: DeliveryChargeRules.new,
        offers: []
      )
      
      basket.add('A01')
      basket.add('B02')
      
      # A01 = 10.0, B02 = 20.0, subtotal = 30.0
      # Discount: 0 (no offers), delivery: 4.95 (since 30.0 < 50), total = 34.95
      expect(basket.total).to eq(34.95)
    end
  end
end 