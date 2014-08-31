# Spree Postal Service

[![Build Status](https://travis-ci.org/futhr/spree-postal-service.svg?branch=master)](https://travis-ci.org/futhr/spree-postal-service)
[![Coverage Status](https://img.shields.io/coveralls/futhr/spree-postal-service.svg)](https://coveralls.io/r/futhr/spree-postal-service?branch=master)
[![Code Climate](https://codeclimate.com/github/futhr/spree-postal-service/badges/gpa.svg)](https://codeclimate.com/github/futhr/spree-postal-service)
[![Gem Version](https://badge.fury.io/rb/spree_postal_service.svg)](http://badge.fury.io/rb/spree_postal_service)

A postal service is delivers based on weight only(*). Like most post services in europe will.

This spree extension adds a spree-calculator to model this.

**Other features:**

- Size and weight restrictions can be specified
- You specify a weight/price table
- Handling fee may be added ( with a maximum when it won't be applied anymore)
- Multi-parcel shipments are automatically created
- You can specify a maximum order price, orders over this will not be charged

Off course this relies on your weight data to be correct (and if you want the restrictions to work, the size data too).
Use the same measurements as in the product info page.

(*) You may install several ShippingMethods for (usually) different countries.

## Usage

Add to your `Gemfile`:
```ruby
gem 'spree_postal_service', github: 'futhr/spree-postal-service', branch: 'master'
```

Go to admin interface

`http://localhost:3000/admin/shipping_methods/new`

and use _Postal Service_ as calculator.

The size/weight _table_ must have the same amount of (space separated) entries.

---

## Example

With the default settings (measurements in kg and cm):

- Max weight of one item: 18
- Max width of one item: 60
- Max length of one item: 90
- Default weight: 1kg (applies when product weight is 0)
- Handling fee: 10
- Amount, over which handling fee won't be applied: 50
- Max total of the order: 120.0
- Weights (space separated): 1 2 5 10 20
- Prices (space separated):  6 9 12 15 18

## Applies?

The Shipping method does not apply to the order if:

- Any items weighs more than 18 kg
- Any item is longer than 90 cm
- Any items second longest side (width) is over 60 cm. Eg a 70x70x20 item.

## Costs

- Items weighing 10 kg of worth 100 Euros will cost 15 Euros
- Items weighing 10 kg of worth 40 Euros will cost 25 Euros (15 + 10 handling)
- Items weighing less than 1 kg of worth 60 Euros will cost 6 Euros
- Items weighing less than 1 kg of worth 40 Euros will cost 16 Euros (6 + 10)
- Items weighing 25 kg of worth 200 Euros will cost 30 Euros (2 packages, 18 + 12 euro)
- 3 items without weight information of worth 100 euros will cost 12 Euro
- Any amount of items costing more than the max_price will cost 0 Euro

---

## Contributing

See corresponding [contributing guidelines][1].

---

## License

Copyright (c) 2011-2014 [Torsten Rüger][2], [Tobias Bohwalli][3] and other [contributors][4], released under the [New BSD License][5].

[1]: https://github.com/futhr/spree-postal-service/blob/master/CONTRIBUTING.md
[2]: https://github.com/dancinglightning
[3]: https://github.com/futhr
[4]: https://github.com/futhr/spree-postal-service/graphs/contributors
[5]: https://github.com/futhr/spree-postal-service/blob/master/LICENSE.md
