#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # load needed tables
  (cb) -> Database.product.importCsv "input/products.csv", cb

  # generate
  (cb) -> Generate.prepare(); cb null
  (cb) -> Generate.customers cb
  (cb) -> Generate.orders cb

  # write
  (cb) -> Database.customer.exportCsv "output/customers.csv", cb
  (cb) -> Database.order.exportCsv "output/oders.csv", cb
  (cb) -> Database.orderDetail.exportCsv "output/oderdetails.csv", cb

  ], (err) -> console.log err if err

