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

  def total
    validate_delivery_charge_rules!
    
    subtotal = @items.sum { |code| @product_catalogue[code] }
    delivery_cost = @delivery_charge_rules.calculate_cost(subtotal)
    
    (subtotal + delivery_cost).round(2)
  end

  private

  def validate_delivery_charge_rules!
    if @delivery_charge_rules.nil?
      raise ArgumentError, 'delivery_charge_rules cannot be nil'
    end
    
    unless @delivery_charge_rules.respond_to?(:calculate_cost)
      raise ArgumentError, 'delivery_charge_rules must respond to calculate_cost'
    end
  end
end 