SpreePostalService
==================

A postal service is delivers based on weight only(*). Like most post services in europe will.

This spree extension adds a spree-calculator to model this.

Other features:
  - size and weight restrictions can be specified
  - you specify a weight/price table 
  - handling fee may be added ( with a maximum when it won't be applied anymore)
  - multi-parcel shipments are automatically created
  - you can specify a maximum order price, orders over this will not be charged

Off course this relies on your weight data to be correct (and if you want the restrictions to work, the size data too).
Use the same measurements as in the product info page.

(*) you may install several ShippingMethods for (usually) different countries.

Usage
=======

Add to your gemfile

gem "spree_postal_service",  :git => "git@github.com:dancinglightning/spree-postal-service.git"

Go to admin interface

http://localhost:3000/admin/shipping_methods/new

and use "Postal" as calculator.

The size/weight "table" must have the same amount of (space separated) entries.

Optionally add your own locale to config/locales/  (and if you do, send it to me)

Example:
=======

With the default settings (measurements in kg and cm):

- Max weight of one item: 18
- Max width of one item: 60
- Max length of one item: 90
- Default weight: 1kg  (applies when product weight is 0)
- Handling fee: 10
- Amount, over which handling fee won't be applied: 50
- Max total of the order: 120.0
- Weights (space separated): 1 2 5 10 20
- Prices (space separated):  6 9 12 15 18

Applies?
-------
The Shipping method does not apply to the order if:

- Any items weighs more than 18 Kg
- Any item is longer than 90 cm
- Any items second longest side (width) is over 60cm. Eg a 70x70x20 item.
 
Costs
-----
- items weighing 10 kg of worth 100 Euros will cost 15 Euros
- items weighing 10 kg of worth 40 Euros will cost 25 Euros (15 + 10 handling)
- items weighing less than 1 kg of worth 60 Euros will cost 6 Euros 
- items weighing less than 1 kg of worth 40 Euros will cost 16 Euros (6 + 10) 
- items weighing 25 kg of worth 200 Euros will cost 30 Euros (2 packages, 18 + 12 euro)
- 3 items without weight information of worth 100 euros will cost 12 Euro
- any amount of items costing more than the max_price will cost 0 Euro

Copyright (c) 2011 [Torsten], released under the New BSD License
