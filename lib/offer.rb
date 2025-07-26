# frozen_string_literal: true

class Offer
  def calculate_discount(items, product_catalogue)
    raise NotImplementedError, "#{self.class} must implement calculate_discount"
  end
end

class PairDiscountOffer < Offer
  def initialize(product_code, discount_percentage)
    @product_code = product_code
    @discount_percentage = discount_percentage
  end

  def calculate_discount(items, product_catalogue)
    target_items = items.count(@product_code)
    pairs = target_items / 2
    (pairs * (product_catalogue[@product_code] * @discount_percentage)).round(2)
  end
end 