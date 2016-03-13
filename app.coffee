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
  (cb) -> Database.location.importCsv "data/input/de.csv", cb

  # generate
  (cb) -> Generate.prepare cb
  (cb) -> Generate.customers cb
  (cb) -> Generate.orders cb

  # print statistics
  (cb) -> Database.orderDetail.statistic cb
  (cb) -> Database.customer.statistic cb

  # write before ETL
  (cb) -> Database.location.selection cb
  (cb) -> Database.location.exportCsv "data/output/locations.csv", cb
  (cb) -> Database.customer.exportCsv "data/output/customers.csv", cb
  (cb) -> Database.order.exportCsv "data/output/orders.csv", cb
  (cb) -> Database.orderDetail.exportCsv "data/output/orderdetails.csv", cb

  # ETL
  (cb) -> Database.customerJoined.create cb
  (cb) -> Database.orderJoined.create cb

  # write after ETL
  (cb) -> Database.product.exportCsv "data/output_etl/products.csv", cb
  (cb) -> Database.customerJoined.exportCsv "data/output_etl/customers.csv", cb
  (cb) -> Database.orderJoined.exportCsv "data/output_etl/orderdetails.csv", cb

  ], (err) -> console.log err if err
