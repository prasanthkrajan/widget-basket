# frozen_string_literal: true

class Offer
  def calculate_discount(items, product_catalogue)
    raise NotImplementedError, "#{self.class} must implement calculate_discount"
  end
end

class HalfPriceOffer < Offer
  def initialize(target_product_code)
    raise ArgumentError, "HalfPriceOffer can only be applied to 'R01'" unless target_product_code == 'R01'
    @target_product_code = target_product_code
  end

  def calculate_discount(items, product_catalogue)
    target_items = items.count(@target_product_code)
    pairs = target_items / 2
    (pairs * (product_catalogue[@target_product_code] * 0.5)).round(2)
  end
end 