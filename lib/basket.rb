# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules:, offers:)
    @product_catalogue =  product_catalogue || default_product_catalogue
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers
    @items = []
  end

  def add(product_code)
    raise ArgumentError unless @product_catalogue.key?(product_code)
    @items << product_code
  end

  def total
    subtotal = @items.sum { |code| @product_catalogue[code] }
    delivery_cost = calculate_delivery_cost(subtotal)
    
    (subtotal + delivery_cost).round(2)
  end

  private

  def calculate_delivery_cost(order_total)
    if order_total >= 90.0
      0.0
    elsif order_total >= 50.0
      2.95
    else
      4.95
    end
  end

  def default_product_catalogue
    {
      'R01' => 32.95,
      'G01' => 24.95,
      'B01' => 7.95
    }
  end
end 