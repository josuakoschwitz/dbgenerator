#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # products 2 db / not used. just for me experimenting with sqlite
  # (cb) -> Database.productsFromCsv "products.csv", cb
  # (cb) -> Database.productsToCsv "output/products.csv", cb

  # generate
  (cb) -> Generate.prepare(); cb null
  (cb) -> Generate.customers cb
  (cb) -> Generate.orders cb

  # write
  (cb) -> Database.customersToCsv "output/customers.csv", cb
  (cb) -> Database.ordersToCsv "output/oders.csv", cb
  (cb) -> Database.orderDetailsToCsv "output/oderdetails.csv", cb

  ], (err) -> console.log err if err

