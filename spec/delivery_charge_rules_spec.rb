# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeliveryChargeRules do
  let(:default_rules) do
    [
      { minimum_order_amount: 90.0, delivery_cost: 0.0 },
      { minimum_order_amount: 50.0, delivery_cost: 2.95 },
      { minimum_order_amount: 0.0, delivery_cost: 4.95 }
    ]
  end

  describe '#initialize' do
    context 'with no arguments' do
      it 'initializes with default rules' do
        rules = DeliveryChargeRules.new
        expect(rules).to be_a(DeliveryChargeRules)
      end

      it 'uses default rules when no rules provided' do
        rules = DeliveryChargeRules.new
        # Test that default rules are used by checking calculation
        expect(rules.calculate_cost(100.0)).to eq(0.0)  # Should be free for orders >= 90
        expect(rules.calculate_cost(75.0)).to eq(2.95)  # Should be 2.95 for orders >= 50
        expect(rules.calculate_cost(25.0)).to eq(4.95)  # Should be 4.95 for orders < 50
      end
    end

    context 'with custom rules' do
      let(:custom_rules) do
        [
          { minimum_order_amount: 100.0, delivery_cost: 0.0 },
          { minimum_order_amount: 25.0, delivery_cost: 5.0 },
          { minimum_order_amount: 0.0, delivery_cost: 10.0 }
        ]
      end

      it 'initializes with custom rules' do
        rules = DeliveryChargeRules.new(custom_rules)
        expect(rules).to be_a(DeliveryChargeRules)
      end

      it 'uses custom rules for calculation' do
        rules = DeliveryChargeRules.new(custom_rules)
        expect(rules.calculate_cost(150.0)).to eq(0.0)   # Free for orders >= 100
        expect(rules.calculate_cost(50.0)).to eq(5.0)    # 5.0 for orders >= 25
        expect(rules.calculate_cost(10.0)).to eq(10.0)   # 10.0 for orders < 25
      end
    end

    context 'with nil rules' do
      it 'uses default rules when nil provided' do
        rules = DeliveryChargeRules.new(nil)
        expect(rules.calculate_cost(100.0)).to eq(0.0)
        expect(rules.calculate_cost(75.0)).to eq(2.95)
        expect(rules.calculate_cost(25.0)).to eq(4.95)
      end
    end
  end

  describe '#calculate_cost' do
    let(:rules) { DeliveryChargeRules.new }

    context 'with default rules' do
      it 'returns free delivery for orders >= 90' do
        expect(rules.calculate_cost(90.0)).to eq(0.0)
        expect(rules.calculate_cost(100.0)).to eq(0.0)
        expect(rules.calculate_cost(150.0)).to eq(0.0)
      end

      it 'returns 2.95 delivery for orders >= 50 and < 90' do
        expect(rules.calculate_cost(50.0)).to eq(2.95)
        expect(rules.calculate_cost(75.0)).to eq(2.95)
        expect(rules.calculate_cost(89.99)).to eq(2.95)
      end

      it 'returns 4.95 delivery for orders < 50' do
        expect(rules.calculate_cost(0.0)).to eq(4.95)
        expect(rules.calculate_cost(25.0)).to eq(4.95)
        expect(rules.calculate_cost(49.99)).to eq(4.95)
      end
    end

    context 'with custom rules' do
      let(:custom_rules) do
        [
          { minimum_order_amount: 200.0, delivery_cost: 0.0 },
          { minimum_order_amount: 100.0, delivery_cost: 3.0 },
          { minimum_order_amount: 50.0, delivery_cost: 7.0 },
          { minimum_order_amount: 0.0, delivery_cost: 15.0 }
        ]
      end

      let(:custom_rules_instance) { DeliveryChargeRules.new(custom_rules) }

      it 'applies custom delivery costs correctly' do
        expect(custom_rules_instance.calculate_cost(250.0)).to eq(0.0)   # Free
        expect(custom_rules_instance.calculate_cost(150.0)).to eq(3.0)    # 3.0
        expect(custom_rules_instance.calculate_cost(75.0)).to eq(7.0)     # 7.0
        expect(custom_rules_instance.calculate_cost(25.0)).to eq(15.0)    # 15.0
      end

      it 'handles edge cases at threshold boundaries' do
        expect(custom_rules_instance.calculate_cost(200.0)).to eq(0.0)    # At threshold
        expect(custom_rules_instance.calculate_cost(199.99)).to eq(3.0)    # Just below
        expect(custom_rules_instance.calculate_cost(100.0)).to eq(3.0)     # At threshold
        expect(custom_rules_instance.calculate_cost(99.99)).to eq(7.0)     # Just below
      end
    end

    context 'with single rule' do
      let(:single_rule) { [{ minimum_order_amount: 0.0, delivery_cost: 5.0 }] }
      let(:single_rule_instance) { DeliveryChargeRules.new(single_rule) }

      it 'applies single rule correctly' do
        expect(single_rule_instance.calculate_cost(0.0)).to eq(5.0)
        expect(single_rule_instance.calculate_cost(100.0)).to eq(5.0)
        expect(single_rule_instance.calculate_cost(1000.0)).to eq(5.0)
      end
    end

    context 'with decimal amounts' do
      it 'handles decimal order amounts correctly' do
        expect(rules.calculate_cost(89.99)).to eq(2.95)
        expect(rules.calculate_cost(90.01)).to eq(0.0)
        expect(rules.calculate_cost(49.99)).to eq(4.95)
        expect(rules.calculate_cost(50.01)).to eq(2.95)
      end
    end

    context 'with zero and negative amounts' do
      it 'handles zero order amount' do
        expect(rules.calculate_cost(0.0)).to eq(4.95)
      end

      it 'raises error for negative order amount' do
        expect { rules.calculate_cost(-10.0) }.to raise_error(ArgumentError, 'order_total cannot be negative')
      end
    end

    context 'with invalid inputs' do
      it 'raises error for nil order total' do
        expect { rules.calculate_cost(nil) }.to raise_error(ArgumentError, 'order_total cannot be nil')
      end

      it 'raises error for non-numeric order total' do
        expect { rules.calculate_cost('invalid') }.to raise_error(ArgumentError, 'order_total must be numeric')
        expect { rules.calculate_cost('100') }.to raise_error(ArgumentError, 'order_total must be numeric')
        expect { rules.calculate_cost([]) }.to raise_error(ArgumentError, 'order_total must be numeric')
        expect { rules.calculate_cost({}) }.to raise_error(ArgumentError, 'order_total must be numeric')
      end
    end
  end

  describe 'rule ordering' do
    context 'with unordered rules' do
      let(:unordered_rules) do
        [
          { minimum_order_amount: 50.0, delivery_cost: 2.95 },
          { minimum_order_amount: 90.0, delivery_cost: 0.0 },
          { minimum_order_amount: 0.0, delivery_cost: 4.95 }
        ]
      end

      it 'finds the rule with the highest threshold that the order total meets or exceeds' do
        rules = DeliveryChargeRules.new(unordered_rules)
        # Should find the rule with highest threshold that order total >= threshold
        expect(rules.calculate_cost(100.0)).to eq(0.0)   # Should find 90.0 rule (highest threshold met)
        expect(rules.calculate_cost(75.0)).to eq(2.95)    # Should find 50.0 rule (highest threshold met)
        expect(rules.calculate_cost(25.0)).to eq(4.95)    # Should find 0.0 rule (highest threshold met)
      end
    end

    context 'with properly ordered rules' do
      let(:ordered_rules) do
        [
          { minimum_order_amount: 90.0, delivery_cost: 0.0 },
          { minimum_order_amount: 50.0, delivery_cost: 2.95 },
          { minimum_order_amount: 0.0, delivery_cost: 4.95 }
        ]
      end

      it 'finds the correct rule when properly ordered' do
        rules = DeliveryChargeRules.new(ordered_rules)
        expect(rules.calculate_cost(100.0)).to eq(0.0)   # Should find 90.0 rule
        expect(rules.calculate_cost(75.0)).to eq(2.95)    # Should find 50.0 rule
        expect(rules.calculate_cost(25.0)).to eq(4.95)    # Should find 0.0 rule
      end
    end

    context 'with complex threshold scenarios' do
      let(:complex_rules) do
        [
          { minimum_order_amount: 200.0, delivery_cost: 0.0 },
          { minimum_order_amount: 150.0, delivery_cost: 1.0 },
          { minimum_order_amount: 100.0, delivery_cost: 2.0 },
          { minimum_order_amount: 50.0, delivery_cost: 3.0 },
          { minimum_order_amount: 25.0, delivery_cost: 4.0 },
          { minimum_order_amount: 0.0, delivery_cost: 5.0 }
        ]
      end

      it 'finds the highest applicable threshold correctly' do
        rules = DeliveryChargeRules.new(complex_rules)
        expect(rules.calculate_cost(250.0)).to eq(0.0)   # Should find 200.0 rule
        expect(rules.calculate_cost(175.0)).to eq(1.0)    # Should find 150.0 rule
        expect(rules.calculate_cost(125.0)).to eq(2.0)    # Should find 100.0 rule
        expect(rules.calculate_cost(75.0)).to eq(3.0)     # Should find 50.0 rule
        expect(rules.calculate_cost(30.0)).to eq(4.0)     # Should find 25.0 rule
        expect(rules.calculate_cost(10.0)).to eq(5.0)     # Should find 0.0 rule
      end

      it 'handles exact threshold matches correctly' do
        rules = DeliveryChargeRules.new(complex_rules)
        expect(rules.calculate_cost(200.0)).to eq(0.0)    # Exact match for highest threshold
        expect(rules.calculate_cost(150.0)).to eq(1.0)    # Exact match for 150.0
        expect(rules.calculate_cost(100.0)).to eq(2.0)    # Exact match for 100.0
        expect(rules.calculate_cost(50.0)).to eq(3.0)     # Exact match for 50.0
        expect(rules.calculate_cost(25.0)).to eq(4.0)     # Exact match for 25.0
        expect(rules.calculate_cost(0.0)).to eq(5.0)      # Exact match for 0.0
      end
    end
  end

  describe 'edge cases' do
    let(:rules) { DeliveryChargeRules.new }

    context 'with very large order amounts' do
      it 'handles large amounts correctly' do
        expect(rules.calculate_cost(1000000.0)).to eq(0.0)
        expect(rules.calculate_cost(999999.99)).to eq(0.0)
      end
    end

    context 'with very small order amounts' do
      it 'handles small amounts correctly' do
        expect(rules.calculate_cost(0.01)).to eq(4.95)
        expect(rules.calculate_cost(0.001)).to eq(4.95)
      end
    end

    context 'with exact threshold amounts' do
      it 'handles exact threshold amounts correctly' do
        expect(rules.calculate_cost(90.0)).to eq(0.0)
        expect(rules.calculate_cost(50.0)).to eq(2.95)
        expect(rules.calculate_cost(0.0)).to eq(4.95)
      end
    end
  end

  describe 'integration scenarios' do
    let(:rules) { DeliveryChargeRules.new }

    context 'real-world order scenarios' do
      it 'calculates delivery for small orders' do
        expect(rules.calculate_cost(7.95)).to eq(4.95)   # Single B01
        expect(rules.calculate_cost(24.95)).to eq(4.95)  # Single G01
        expect(rules.calculate_cost(32.95)).to eq(4.95)  # Single R01
      end

      it 'calculates delivery for medium orders' do
        expect(rules.calculate_cost(65.85)).to eq(2.95)  # B01 + G01 + R01
        expect(rules.calculate_cost(57.90)).to eq(2.95)  # R01 + G01
        expect(rules.calculate_cost(49.42)).to eq(4.95)  # R01 pair with discount
      end

      it 'calculates delivery for large orders' do
        expect(rules.calculate_cost(115.80)).to eq(0.0)  # R01 + R01 + G01 + G01
        expect(rules.calculate_cost(99.32)).to eq(0.0)   # Large order with discounts
        expect(rules.calculate_cost(91.83)).to eq(0.0)   # Multiple items with discounts
      end
    end
  end
end 