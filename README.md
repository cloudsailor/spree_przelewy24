SpreePrzelewy24
====================

This is fork of matfiz/spree_przelewy24
Przelewy24 payment system for Spree (>= 1.0)

Install
=======

Add to your Gemfile:

    gem 'spree_przelewy24', github: 'cloudsailor/spree_przelewy24', branch: 'release-1.0.0'

and run

    bundle install

Przelewy24.pl Settings
========

You'll have to set the following parameters:
  * seller ID
  * CRC key
  * optionally: language and przelewy24 URLs

In Spree Admin zone you have to create new payment method and select *Spree::PaymentMethod::Przelewy24* as a provider.
I recommend to test it first - just select *test mode* in payment method settings and it will use sandbox platform instead of the production one.

This work is loosely based on https://github.com/pronix/spree-ebsin and https://github.com/espresse/spree_dotpay_pl_payment.git.

------------------------------------------------------------------------------
License
------------------------------------------------------------------------------

Copyright (c) 2011 - 2012 Grzegorz Brzezinka (@matfiz), released under the New BSD License All rights reserved.
