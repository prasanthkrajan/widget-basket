# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules:, offers: nil)
    @product_catalogue = product_catalogue
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers.nil? || offers.empty? ? [PairDiscountOffer.new('R01', 0.5)] : offers
    @items = []
    validate_pair_offers!
  end

  def add(product_code)
    raise ArgumentError unless @product_catalogue.key?(product_code)
    @items << product_code
  end

  def total
    validate_delivery_charge_rules!
    
    subtotal = @items.sum { |code| @product_catalogue[code] }
    discount = calculate_discounts
    delivery_cost = @delivery_charge_rules.calculate_cost(subtotal - discount)
    
    (subtotal - discount + delivery_cost).round(2)
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

  def calculate_discounts
    @offers.sum { |offer| offer.calculate_discount(@items, @product_catalogue) }
  end

  def validate_pair_offers!
    offers_by_product = @offers.group_by { |offer| offer.respond_to?(:product_code) ? offer.product_code : nil }
    offers_by_product.each do |product_code, product_offers|
      pair_offers = product_offers.select { |offer| offer.is_a?(PairDiscountOffer) }
      if pair_offers.size > 1
        offer_descriptions = pair_offers.map { |offer| "PairDiscountOffer(#{(offer.instance_variable_get(:@discount_percentage) * 100).to_i}%)" }
        raise ArgumentError, "Multiple pair offers found for product '#{product_code}': #{offer_descriptions.join(' and ')}. Only one pair offer per product is allowed."
      end
    end
  end
end 