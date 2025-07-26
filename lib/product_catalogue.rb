# frozen_string_literal: true

class ProductCatalogue
  def initialize(products = nil)
    @products = products || default_products
    validate_products!
  end

  def [](product_code)
    @products[product_code]
  end

  def key?(product_code)
    @products.key?(product_code)
  end

  def to_h
    @products.dup
  end

  private

  def validate_products!
    raise ArgumentError, 'products cannot be nil' if @products.nil?
    raise ArgumentError, 'products must be a Hash' unless @products.is_a?(Hash)
    raise ArgumentError, 'products cannot be empty' if @products.empty?
    
    @products.each do |product_code, price|
      unless price.is_a?(Numeric)
        raise ArgumentError, 'product prices must be non-negative numbers'
      end
      
      if price < 0
        raise ArgumentError, 'product prices must be non-negative numbers'
      end
      
      if price == 0
        raise ArgumentError, 'product prices must be positive numbers'
      end
    end
  end

  def default_products
    {
      'R01' => 32.95,
      'G01' => 24.95,
      'B01' => 7.95
    }
  end
end 