# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules: nil, offers: [])
    validate_product_catalogue!(product_catalogue)
    validate_delivery_charge_rules!(delivery_charge_rules)
    validate_offers!(offers)
    
    @product_catalogue = product_catalogue
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers
    @items = []
  end

  def add(product_code)
    raise ArgumentError, "Product code '#{product_code}' not found in catalogue" unless @product_catalogue.key?(product_code)
    @items << product_code
  end

  def total
    subtotal = @items.sum { |code| @product_catalogue[code] }
    discount = calculate_discounts
    delivery_cost = @delivery_charge_rules&.calculate_cost(subtotal - discount) || 0.0

    (subtotal - discount + delivery_cost).round(2)
  end

  private

  def validate_product_catalogue!(product_catalogue)
    raise ArgumentError, 'product_catalogue cannot be nil' if product_catalogue.nil?
    raise ArgumentError, 'product_catalogue must be a Hash' unless product_catalogue.is_a?(Hash)
    raise ArgumentError, 'product_catalogue cannot be empty' if product_catalogue.empty?
  end

  def validate_delivery_charge_rules!(delivery_charge_rules)
    return if delivery_charge_rules.nil?
    
    unless delivery_charge_rules.respond_to?(:calculate_cost)
      raise ArgumentError, 'delivery_charge_rules must respond to calculate_cost'
    end
  end

  def validate_offers!(offers)
    raise ArgumentError, 'offers must be an Array' unless offers.is_a?(Array)
    
    unless offers.all? { |offer| offer.respond_to?(:calculate_discount) }
      raise ArgumentError, 'each offer must respond to calculate_discount'
    end

    PairDiscountOffer.validate_collection!(offers)
  end

  def calculate_discounts
    @offers.sum { |offer| offer.calculate_discount(@items, @product_catalogue) }
  end
end 