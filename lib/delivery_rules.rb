# frozen_string_literal: true

class DeliveryRules
  def calculate_cost(order_total)
    if order_total >= 90.0
      0.0
    elsif order_total >= 50.0
      2.95
    else
      4.95
    end
  end
end 