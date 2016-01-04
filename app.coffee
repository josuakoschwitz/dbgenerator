#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # preparing database
  (cb) -> Database.clear cb
  (cb) -> Database.init cb

  # products 2 db / not used. just for me experimenting with sqlite
  (cb) -> Database.ProductsFromCsv "products.csv", cb
  (cb) -> Database.ProductsToCsv "products_new.csv", cb

  # statistics
  (cb) -> Database.count cb

  ], (err) ->
    console.log err if err
    Database.close

