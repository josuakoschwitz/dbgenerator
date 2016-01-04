#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # products 2 db / not used. just for me experimenting with sqlite
  (cb) -> Database.ProductsFromCsv "products.csv", cb
  (cb) -> Database.ProductsToCsv "output/products.csv", cb

  # generate customers
  (cb) -> Generate.customers cb
  (cb) -> Database.CustomersToCsv "output/customers.csv", cb
  (cb) -> console.log "helloooo"; cb null

  # statistics
  (cb) -> Database.ProductsCount cb

  ], (err) -> console.log err if err

