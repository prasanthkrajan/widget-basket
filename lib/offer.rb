# frozen_string_literal: true

class Offer
  def calculate_discount(items, product_catalogue)
    raise NotImplementedError, "#{self.class} must implement calculate_discount"
  end

  def conflicts_with?(other_offer)
    false
  end
end

class Offers
  def self.new
    PairDiscountOffer.new
  end
end

class PairDiscountOffer < Offer
  attr_reader :product_code, :discount_percentage

  def initialize(product_code = 'R01', discount_percentage = 0.5)
    validate_parameters!(product_code, discount_percentage)
    @product_code = product_code
    @discount_percentage = discount_percentage
  end

  def calculate_discount(items, product_catalogue)
    target_items = items.count(@product_code)
    pairs = target_items / 2
    (pairs * (product_catalogue[@product_code] * @discount_percentage)).round(2)
  end

  def conflicts_with?(other_offer)
    other_offer.is_a?(PairDiscountOffer) && other_offer.product_code == product_code
  end

  private

  def validate_parameters!(product_code, discount_percentage)
    raise ArgumentError, 'product_code cannot be nil' if product_code.nil?
    raise ArgumentError, 'product_code must be a string' unless product_code.is_a?(String)
    raise ArgumentError, 'product_code cannot be empty' if product_code.strip.empty?
    
    raise ArgumentError, 'discount_percentage cannot be nil' if discount_percentage.nil?
    raise ArgumentError, 'discount_percentage must be numeric' unless discount_percentage.is_a?(Numeric)
    raise ArgumentError, 'discount_percentage must be between 0 and 1' if discount_percentage < 0 || discount_percentage > 1
  end

  def self.validate_collection!(offers)
    pair_offers = offers.select { |offer| offer.is_a?(PairDiscountOffer) }
    pair_offers.group_by(&:product_code).each do |product_code, product_pair_offers|
      if product_pair_offers.size > 1
        offer_descriptions = product_pair_offers.map { |offer| "PairDiscountOffer(#{(offer.discount_percentage * 100).to_i}%)" }
        raise ArgumentError, "Multiple pair offers found for product '#{product_code}': #{offer_descriptions.join(' and ')}. Only one pair offer per product is allowed."
      end
    end
  end
end 