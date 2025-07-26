# frozen_string_literal: true

class Basket
  attr_reader :items

  def initialize(product_catalogue:, delivery_charge_rules: nil, offers: [])
    @product_catalogue = product_catalogue
    validate_product_catalogue!(@product_catalogue)
    validate_delivery_charge_rules!(delivery_charge_rules)
    validate_offers!(offers)

    offers_array = offers.is_a?(Array) ? offers : [offers]
    
    @delivery_charge_rules = delivery_charge_rules
    @offers = offers_array
    @items = []
  end

  def add(product_code)
    raise ArgumentError, 'product_code must be a string' unless product_code.is_a?(String)
    raise ArgumentError, 'product_code cannot be empty' if product_code.strip.empty?
    
    raise ArgumentError, "Product code '#{product_code}' not found in catalogue" unless @product_catalogue.key?(product_code)
    @items << product_code
    reset_cart
  end

  def clear
    @items.clear
    reset_cart
  end

  def total
    (subtotal - discounts + delivery_cost).round(2)
  end

  private

  def subtotal
    @subtotal ||= @items.sum { |code| @product_catalogue[code] }
  end

  def discounts
    @discounts ||= calculate_discounts
  end

  def delivery_cost
    return 0.0 if @items.empty?
    
    @delivery_cost ||= @delivery_charge_rules&.calculate_cost(subtotal - discounts) || 0.0
  end

  def calculate_discounts
    total_discount = @offers.sum { |offer| offer.calculate_discount(@items, @product_catalogue) }
    
    if total_discount < 0
      raise ArgumentError, 'discounts cannot be negative'
    end
    
    total_discount
  end

  def reset_cart
    @subtotal = nil
    @discounts = nil
    @delivery_cost = nil
  end

  def validate_product_catalogue!(product_catalogue)
    raise ArgumentError, 'product_catalogue cannot be nil' if product_catalogue.nil?
    raise ArgumentError, 'product_catalogue must be a ProductCatalogue' unless product_catalogue.is_a?(ProductCatalogue)
  end

  def validate_delivery_charge_rules!(delivery_charge_rules)
    return if delivery_charge_rules.nil?
    
    unless delivery_charge_rules.respond_to?(:calculate_cost)
      raise ArgumentError, 'delivery_charge_rules must respond to calculate_cost'
    end
  end

  def validate_offers!(offers)
    if offers.nil?
      raise ArgumentError, 'offers must be an Array'
    end
    
    if offers.is_a?(Array)
      unless offers.all? { |offer| offer.respond_to?(:calculate_discount) }
        raise ArgumentError, 'each offer must respond to calculate_discount'
      end
      PairDiscountOffer.validate_collection!(offers)
    else
      unless offers.respond_to?(:calculate_discount)
        raise ArgumentError, 'offers must be an Array'
      end
      PairDiscountOffer.validate_collection!([offers])
    end
  end
end 