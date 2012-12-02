SpreePostalService
==================

A postal service is delivers based on weight only(*). Like most post services in europe will.

This spree extension adds a spree-calculator to model this.

Other features:
  - size and weight restrictions by item and by order can be specified
  - you can also add zip code restrictions
  - you specify a weight/price table 
  - prices in the price table can be by weight unit (kg)
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

The price/weight "table" must have the same amount of (space separated) entries.

Optionally add your own locale to config/locales/  (and if you do, send it to me)

Settings:
========

Weights "table": A space separated list of weights (must have the same amount of entries as the Prices "table")
Prices "table": A space separated list of prices (must have the same amount of entries as the Weights "table")
Price by weight unit?: Indicates if the prices in the price list are by weight unit. If true, then the weight of the order will be multiplied by the price setted for that weight value.
	Ex: Weights: "1 2 5"; Prices: "5 3 2"; Price By Weight Unit? true. If we have a order with a weight of 2.5kg then the total price will be 7,5. If the "Price By Weight Unit?" was setted to false, the total price would be 3.
Max weight of one item enable?: Enables the "Max weight of one item" verification.
Max weight of one item: Max weight of any item in the order may have to enable the shipping method.
Max width of one item enabled?: Enables the "Max width of one item" verification.
Max width of one item: Max width that any item in the order may have to enable the shipping method.
Max length of one item enabled?: Enables the "Max length of one item" verification.
Max length of one item: Max length that any item in the order may have to enable the shipping method.
Max total weight enabled?: Enables the "Max total weight" verification.
Max total weight: Max total weight of the order to enable the shipping method.
Min total weight enabled?: Enables the "Min total weight" verification.
Min total weight: Min total weight of the order to enable the shipping method.
Maximum total of the order enabled?: Enables the "Maximum total of the order" verification.
Maximum total of the order: Order price after which the shipping cost will be 0.
Amount, over which handling fee won't be applied: Self explained.
Handling fee: The handling fee.
Default weight: The default weight to be used on any product that doesn't have a weight value defined.
Zipcode handling (empty field - does not apply, exact, starts, ends, contains): When the value is one of "exact", "starts", "ends" or "contains", it will validate the zipcode of the shipping adress and enable the shipping method.
	- When the value is "starts", the shipping adress zipcode must equal to any of the defined zipcodes in the Zipcode(s) field;
	- When the value is "starts", the shipping adress zipcode must start with any of the defined zipcode "parts" in the Zipcode(s) field;
	- When the value is "ends", the shipping adress zipcode must end with any of the defined zipcode "parts" in the Zipcode(s) field;
	- When the value is "contains", the shipping adress zipcode must contains any of the defined zipcode "parts" in the Zipcode(s) field;
Zipcode separator: The separator to be used when specifying several zipcodes in the "Zipcode(s)" field.
Zipcode(s): Zipcode(s), or parts of them, to be used to check if the shipping method is available. When using several zipcodes, the separator must be the one indicated in the "Zipcode separator field".

Example:
=======

With the default settings (measurements in kg and cm):

- Max weight of one item enabled: true
- Max weight of one item: 18
- Max width of one item enabled: true
- Max width of one item: 60
- Max length of one item enabled: true
- Max length of one item: 90
- Default weight: 1kg  (applies when product weight is 0)
- Handling fee: 10
- Amount, over which handling fee won't be applied: 50
- Max total of the order: 120.0
- Max total weight of the order enabled: false
- Max total weight of the order: 120.0
- Min total weight of the order enabled: false
- Min total weight the order: 0
- Weights (space separated): 1 2 5 10 20
- Prices (space separated):  6 9 12 15 18
- Price by weight unit?: false
- Zipcode handling:
- Zipcode separator: |
- Zipcode:

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
