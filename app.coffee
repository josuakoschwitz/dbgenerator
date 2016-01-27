#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # load needed tables
  (cb) -> Database.product.importCsv "data/input/products.csv", cb
  # (cb) -> Database.location.importCsv "data/input/location.csv", cb

  # generate
  (cb) -> Generate.prepare(); cb null
  (cb) -> Generate.customers cb
  (cb) -> Generate.orders cb

  # write before ETL
  # (cb) -> Database.product.exportCsv "data/output/products.csv", cb
  # (cb) -> Database.customer.exportCsv "data/output/customers.csv", cb
  (cb) -> Database.order.exportCsv "data/output/oders.csv", cb
  (cb) -> Database.orderDetail.exportCsv "data/output/oderdetails.csv", cb

  # ETL
  (cb) -> Database.orderComplete.createFromJoin cb

  # write after ETL
  (cb) -> Database.customer.exportCsv "data/output_etl/customers.csv", cb
  (cb) -> Database.orderComplete.exportCsv "data/output_etl/oderscomplete.csv", cb

  ], (err) -> console.log err if err
