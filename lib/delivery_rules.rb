# frozen_string_literal: true

class DeliveryRules
  def initialize(rules = nil)
    @rules = rules || default_rules
  end

  def calculate_cost(order_total)
    raise ArgumentError, 'order_total cannot be nil' if order_total.nil?
    raise ArgumentError, 'order_total must be numeric' unless order_total.is_a?(Numeric)
    raise ArgumentError, 'order_total cannot be negative' if order_total < 0
    
    rule = @rules.find { |r| order_total >= r[:threshold] }
    rule ? rule[:cost] : 0.0
  end

  private

  def default_rules
    [
      { threshold: 90.0, cost: 0.0 },
      { threshold: 50.0, cost: 2.95 },
      { threshold: 0.0, cost: 4.95 }
    ]
  end
end 