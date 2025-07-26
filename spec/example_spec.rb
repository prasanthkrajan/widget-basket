# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Acme Widget Co' do
  it 'can create a basket' do
    basket = AcmeWidgetCo.create_basket
    expect(basket).to be_a(Basket)
  end

  it 'can add products to basket' do
    basket = AcmeWidgetCo.create_basket
    basket.add('R01')
    expect(basket.items.length).to eq(1)
  end

  it 'calculates correct total for B01, G01' do
    basket = AcmeWidgetCo.create_basket
    basket.add('B01')
    basket.add('G01')
    expect(basket.total).to eq(37.85)
  end
end 