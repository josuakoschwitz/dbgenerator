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
  # (cb) -> Database.location.importCsv "input/location.csv", cb

  # generate
  (cb) -> Generate.prepare(); cb null
  (cb) -> Generate.customers cb
  (cb) -> Generate.orders cb

  # write before ETL
  # (cb) -> Database.customer.exportCsv "output/customers.csv", cb
  (cb) -> Database.order.exportCsv "output/oders.csv", cb
  (cb) -> Database.orderDetail.exportCsv "output/oderdetails.csv", cb

  # ETL
  (cb) -> Database.orderComplete.createFromJoin cb
  # (cb) -> Database.orderDetail.splitDate cb null

  # write after ETL
  (cb) -> Database.customer.exportCsv "output_etl/customers.csv", cb
  (cb) -> Database.orderComplete.exportCsv "output_etl/oderscomplete.csv", cb

  ], (err) -> console.log err if err

