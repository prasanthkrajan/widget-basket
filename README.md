# Widget Basket

A Ruby application that implements a shopping basket system with product catalog, delivery charge rules, and discount offers. The application calculates the total cost of items including subtotal, discounts, and delivery charges.

## Overview

The Widget Basket application consists of several key components:

- **Basket**: Main shopping cart that manages items and calculates totals
- **ProductCatalogue**: Manages product information and pricing
- **DeliveryChargeRules**: Handles delivery cost calculation based on order value
- **Offer**: Implements discount offers (currently supports pair discounts)

## Features

- **Product Management**: Add products to basket using product codes
- **Automatic Discounts**: Apply pair-based discounts (e.g., buy one get one 50% off)
- **Dynamic Delivery Charges**: Calculate delivery costs based on order total
- **Comprehensive Validation**: Robust input validation and error handling
- **Test Coverage**: Extensive test suite with 182 test cases

## Default Configuration

### Products
- **R01**: Red Widget - $32.95
- **G01**: Green Widget - $24.95  
- **B01**: Blue Widget - $7.95

### Delivery Charges
- **Orders ≥ $90**: Free delivery
- **Orders ≥ $50**: $2.95 delivery
- **Orders < $50**: $4.95 delivery

### Offers
- **R01 Pair Discount**: Buy one R01, get the second R01 at 50% off
- **Multiple Offers**: Support for multiple pair discounts on different products
- **Conflict Prevention**: Only one offer per product code allowed

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd widget-basket
```

2. Install dependencies:
```bash
bundle install
```

## Usage

### Offer Initialization Options

The basket can be initialized with offers in several ways:

1. **Using `Offers.new`** (creates default R01 pair discount):
```ruby
offers = Offers.new
```

2. **Single `PairDiscountOffer`** (default R01, 50% off):
```ruby
offers = [PairDiscountOffer.new]
```

3. **Multiple `PairDiscountOffer` instances** with different product codes:
```ruby
offers = [
  PairDiscountOffer.new('R01', 0.5),  # R01: buy one get one 50% off
  PairDiscountOffer.new('G01', 0.3),  # G01: buy one get one 30% off
  PairDiscountOffer.new('B01', 0.25)  # B01: buy one get one 25% off
]
```

**Note:** Only one offer per product code is allowed to prevent conflicts.

### Basic Usage

```ruby
require_relative 'lib/basket'
require_relative 'lib/product_catalogue'
require_relative 'lib/delivery_charge_rules'
require_relative 'lib/offer'

# Create components with default values
product_catalogue = ProductCatalogue.new
delivery_rules = DeliveryChargeRules.new

# Option 1: Single offer using Offers.new
offers = Offers.new

# Option 2: Single PairDiscountOffer (default R01, 50% off)
offers = [PairDiscountOffer.new]

# Option 3: Multiple PairDiscountOffer with different product codes
offers = [
  PairDiscountOffer.new('R01', 0.5),  # R01: buy one get one 50% off
  PairDiscountOffer.new('G01', 0.3)   # G01: buy one get one 30% off
]

# Create basket
basket = Basket.new(
  product_catalogue: product_catalogue,
  delivery_charge_rules: delivery_rules,
  offers: offers
)

# Add items
basket.add('B01')
basket.add('G01')

# Get total
puts "Total: $#{basket.total}"
```

### Example Scenarios

#### Scenario 1: B01, G01
```ruby
basket = Basket.new(
  product_catalogue: ProductCatalogue.new,
  delivery_charge_rules: DeliveryChargeRules.new,
  offers: Offers.new  # or [PairDiscountOffer.new]
)

basket.add('B01')  # $7.95
basket.add('G01')  # $24.95
# Subtotal: $32.90
# Delivery: $2.95 (≥ $50)
# Total: $35.85
```

#### Scenario 2: R01, R01
```ruby
basket = Basket.new(
  product_catalogue: ProductCatalogue.new,
  delivery_charge_rules: DeliveryChargeRules.new,
  offers: [PairDiscountOffer.new]  # R01 pair discount
)

basket.add('R01')  # $32.95
basket.add('R01')  # $32.95 (50% off = $16.48)
# Subtotal: $49.43
# Delivery: $4.95 (< $50)
# Total: $54.38
```

#### Scenario 3: B01, B01, R01
```ruby
basket = Basket.new(
  product_catalogue: ProductCatalogue.new,
  delivery_charge_rules: DeliveryChargeRules.new,
  offers: [PairDiscountOffer.new]  # R01 pair discount
)

basket.add('B01')  # $7.95
basket.add('B01')  # $7.95
basket.add('R01')  # $32.95
# Subtotal: $48.85
# Delivery: $4.95 (< $50)
# Total: $53.80
```

#### Scenario 4: B01, G01, R01, R01, R01
```ruby
basket = Basket.new(
  product_catalogue: ProductCatalogue.new,
  delivery_charge_rules: DeliveryChargeRules.new,
  offers: [PairDiscountOffer.new]  # R01 pair discount
)

basket.add('B01')  # $7.95
basket.add('G01')  # $24.95
basket.add('R01')  # $32.95
basket.add('R01')  # $32.95 (50% off = $16.48)
basket.add('R01')  # $32.95
# Subtotal: $115.28
# Delivery: $0.00 (≥ $90)
# Total: $115.28
```

## Testing

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test Files
```bash
bundle exec rspec spec/basket_spec.rb
bundle exec rspec spec/product_catalogue_spec.rb
bundle exec rspec spec/delivery_charge_rules_spec.rb
bundle exec rspec spec/offer_spec.rb
```

### Test Coverage
The application includes comprehensive test coverage:
- **182 test cases** across all components
- **Basket**: 34 tests covering all functionality
- **ProductCatalogue**: 34 tests for product management
- **DeliveryChargeRules**: 34 tests for delivery calculations
- **Offer**: 34 tests for discount logic

## API Reference

### Basket

#### `Basket.new(product_catalogue:, delivery_charge_rules:, offers:)`
Creates a new basket instance.

**Parameters:**
- `product_catalogue`: ProductCatalogue instance
- `delivery_charge_rules`: DeliveryChargeRules instance  
- `offers`: Array of Offer instances or single Offer

#### `basket.add(product_code)`
Adds a product to the basket.

**Parameters:**
- `product_code`: String product code (e.g., 'R01', 'G01', 'B01')

**Returns:** The product code that was added

#### `basket.clear`
Removes all items from the basket.

#### `basket.total`
Calculates the total cost including subtotal, discounts, and delivery.

**Returns:** Float representing the total cost

#### `basket.items`
Returns the array of product codes in the basket.

### ProductCatalogue

#### `ProductCatalogue.new(products = nil)`
Creates a product catalogue with default or custom products.

**Parameters:**
- `products`: Optional hash of product codes to prices

#### `catalogue[product_code]`
Gets the price for a product code.

#### `catalogue.key?(product_code)`
Checks if a product code exists in the catalogue.

### DeliveryChargeRules

#### `DeliveryChargeRules.new(rules = nil)`
Creates delivery charge rules with default or custom rules.

**Parameters:**
- `rules`: Optional array of rule hashes with `minimum_order_amount` and `delivery_cost`

#### `rules.calculate_cost(order_total)`
Calculates delivery cost for an order total.

**Parameters:**
- `order_total`: Numeric order total

**Returns:** Float representing delivery cost

### Offer

#### `Offers.new`
Creates a default offer (equivalent to `PairDiscountOffer.new`).

#### `PairDiscountOffer.new(product_code = 'R01', discount_percentage = 0.5)`
Creates a pair discount offer.

**Parameters:**
- `product_code`: Product code for the discount (default: 'R01')
- `discount_percentage`: Discount percentage as decimal (default: 0.5)

**Note:** Multiple PairDiscountOffer instances can be used together, but only one offer per product code is allowed to prevent conflicts.

#### `offer.calculate_discount(items, product_catalogue)`
Calculates discount amount for given items.

**Parameters:**
- `items`: Array of product codes
- `product_catalogue`: ProductCatalogue instance

**Returns:** Float representing discount amount

## Error Handling

The application includes comprehensive error handling:

- **Invalid product codes**: Raises ArgumentError for non-existent products
- **Invalid input types**: Validates parameter types and raises appropriate errors
- **Negative values**: Prevents negative prices, discounts, or delivery costs
- **Empty inputs**: Validates against empty or nil inputs
- **Conflicting offers**: Prevents multiple offers for the same product

## Architecture

The application follows a modular design with clear separation of concerns:

```
lib/
├── basket.rb                 # Main shopping cart logic
├── product_catalogue.rb      # Product and pricing management
├── delivery_charge_rules.rb  # Delivery cost calculation
└── offer.rb                 # Discount offer implementations
```

Each component is self-contained with its own validation and can be used independently or together.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is open source and available under the [MIT License](LICENSE).
