# frozen_string_literal: true

class DeliveryChargeRules
  def initialize(rules = nil)
    @rules = rules || default_rules
  end

  def calculate_cost(order_total)
    validate_order_total!(order_total)
    
    rule = @rules.find { |r| order_total >= r[:minimum_order_amount] }
    rule ? rule[:delivery_cost] : 0.0
  end

  private

  def validate_order_total!(order_total)
    raise ArgumentError, 'order_total cannot be nil' if order_total.nil?
    raise ArgumentError, 'order_total must be numeric' unless order_total.is_a?(Numeric)
    raise ArgumentError, 'order_total cannot be negative' if order_total < 0
  end

  def default_rules
    [
      { minimum_order_amount: 90.0, delivery_cost: 0.0 },
      { minimum_order_amount: 50.0, delivery_cost: 2.95 },
      { minimum_order_amount: 0.0, delivery_cost: 4.95 }
    ]
  end
end 