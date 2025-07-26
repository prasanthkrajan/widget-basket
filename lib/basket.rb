# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules:, offers:)
    @product_catalogue = {
      'R01' => 32.95,
      'G01' => 24.95,
      'B01' => 7.95
    }
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers
    @items = []
  end

  def add(product_code)
    raise ArgumentError unless @product_catalogue.key?(product_code)
    @items << product_code
  end
end 