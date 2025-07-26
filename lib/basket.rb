# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules:, offers:)
    raise ArgumentError, 'product_catalogue cannot be nil' if product_catalogue.nil?
    raise ArgumentError, 'delivery_charge_rules cannot be nil' if delivery_charge_rules.nil?
    raise ArgumentError, 'offers cannot be nil' if offers.nil?
    raise ArgumentError, 'product_catalogue cannot be empty' if product_catalogue.empty?
    raise ArgumentError, 'offers cannot be empty' if offers.empty?
    raise ArgumentError, 'delivery_charge_rules must respond to calculate_cost' unless delivery_charge_rules.respond_to?(:calculate_cost)
    
    @product_catalogue = product_catalogue
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
    discount = calculate_discounts
    delivery_cost = @delivery_charge_rules.calculate_cost(subtotal - discount)

    (subtotal - discount + delivery_cost).round(2)
  end

  private

  def calculate_discounts
    @offers.sum { |offer| offer.calculate_discount(@items, @product_catalogue) }
  end
end 