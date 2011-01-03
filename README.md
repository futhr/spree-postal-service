SpreePostalService
==================

A Postal service is delivers based on weight only(*). Like most post services in europe will.

This spree extension adds a spree-calculator to model this.

Other features:
  - size and weight restrictions can be specified
  - you specify a weight/price table 
  - handling fee may be added ( with a maximum when it won't be applied anymore)
  - multi-parcel shipments are automatically created

Off course this relies on your weight data to be correct (and if you want the restrictions to work, the size data too)


Example
=======

Add to your gemfile

gem "spree_postal_service",  :git => "git@github.com:dancinglightning/spree-postal-service.git"

Go to admin interface

http://localhost:3000/admin/shipping_methods/new

and use "Postal"

as calculator.

Optionally add your own locale to config/locales/  (and if you do, send it to me)

Copyright (c) 2011 [name of extension creator], released under the New BSD License
