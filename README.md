# Spree Postal Service

[![Build Status](https://api.travis-ci.org/dancinglightning/spree-postal-service.png?branch=master)](https://travis-ci.org/dancinglightning/spree-postal-service)
[![Code Climate](https://codeclimate.com/github/dancinglightning/spree-postal-service.png)](https://codeclimate.com/github/dancinglightning/spree-postal-service)

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
gem 'spree_postal_service',  github: 'dancinglightning/spree-postal-service', branch: 'master'
```

Go to admin interface

`http://localhost:3000/admin/shipping_methods/new`

and use _Postal Service_ as calculator.

The size/weight _table_ must have the same amount of (space separated) entries.

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

- Any items weighs more than 18 Kg
- Any item is longer than 90 cm
- Any items second longest side (width) is over 60cm. Eg a 70x70x20 item.

## Costs

- Items weighing 10 kg of worth 100 Euros will cost 15 Euros
- Items weighing 10 kg of worth 40 Euros will cost 25 Euros (15 + 10 handling)
- Items weighing less than 1 kg of worth 60 Euros will cost 6 Euros
- Items weighing less than 1 kg of worth 40 Euros will cost 16 Euros (6 + 10)
- Items weighing 25 kg of worth 200 Euros will cost 30 Euros (2 packages, 18 + 12 euro)
- 3 items without weight information of worth 100 euros will cost 12 Euro
- Any amount of items costing more than the max_price will cost 0 Euro

## Contributing

In the spirit of [free software][1], **everyone** is encouraged to help improve this project.

Here are some ways *you* can contribute:

* by using prerelease versions
* by reporting [bugs][2]
* by suggesting new features
* by writing translations
* by writing or editing documentation
* by writing specifications
* by writing code (*no patch is too small*: fix typos, add comments, clean up inconsistent whitespace)
* by refactoring code
* by resolving [issues][2]
* by reviewing patches

Starting point:

* Fork the repo
* Clone your repo
* Run `bundle install`
* Run `bundle exec rake test_app` to create the test application in `spec/test_app`
* Make your changes
* Ensure specs pass by running `bundle exec rspec spec`
* Submit your pull request

Copyright (c) 2014 [Torsten Rüger][3] and [contributors][4], released under the [New BSD License][5]

[1]: http://www.fsf.org/licensing/essays/free-sw.html
[2]: https://github.com/dancinglightning/spree-postal-service/issues
[3]: https://github.com/dancinglightning
[4]: https://github.com/dancinglightning/spree-postal-service/graphs/contributors
[5]: https://github.com/dancinglightning/spree-postal-service/blob/master/LICENSE.md
