# frozen_string_literal: true

class DeliveryChargeRules
  def initialize(rules = nil)
    @rules = rules || default_rules
    validate_rules!
  end

  def calculate_cost(order_total)
    validate_order_total!(order_total)
    
    # Find the rule with the highest threshold that the order total meets or exceeds
    rule = @rules.select { |r| order_total >= r[:minimum_order_amount] }
                 .max_by { |r| r[:minimum_order_amount] }
    rule ? rule[:delivery_cost] : 0.0
  end

  private

  def validate_order_total!(order_total)
    raise ArgumentError, 'order_total cannot be nil' if order_total.nil?
    raise ArgumentError, 'order_total must be numeric' unless order_total.is_a?(Numeric)
    raise ArgumentError, 'order_total cannot be negative' if order_total < 0
  end

  def validate_rules!
    raise ArgumentError, 'rules cannot be nil' if @rules.nil?
    raise ArgumentError, 'rules must be an Array' unless @rules.is_a?(Array)
    raise ArgumentError, 'rules cannot be empty' if @rules.empty?
    
    @rules.each_with_index do |rule, index|
      validate_rule!(rule, index)
    end
  end

  def validate_rule!(rule, index)
    unless rule.is_a?(Hash)
      raise ArgumentError, "rule at index #{index} must be a Hash"
    end
    
    required_keys = [:minimum_order_amount, :delivery_cost]
    missing_keys = required_keys - rule.keys
    if missing_keys.any?
      raise ArgumentError, "rule at index #{index} missing required keys: #{missing_keys.join(', ')}"
    end
    
    unless rule[:minimum_order_amount].is_a?(Numeric)
      raise ArgumentError, "rule at index #{index} minimum_order_amount must be numeric"
    end
    
    unless rule[:delivery_cost].is_a?(Numeric)
      raise ArgumentError, "rule at index #{index} delivery_cost must be numeric"
    end
    
    if rule[:minimum_order_amount] < 0
      raise ArgumentError, "rule at index #{index} minimum_order_amount cannot be negative"
    end
    
    if rule[:delivery_cost] < 0
      raise ArgumentError, "rule at index #{index} delivery_cost cannot be negative"
    end
  end

  def default_rules
    [
      { minimum_order_amount: 90.0, delivery_cost: 0.0 },
      { minimum_order_amount: 50.0, delivery_cost: 2.95 },
      { minimum_order_amount: 0.0, delivery_cost: 4.95 }
    ]
  end
end 