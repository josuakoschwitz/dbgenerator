Database = module.exports

### libraries ###
fs = require "fs"

### modules ###
Csv = require "./csv"
Products = require "./database/products"


Database.clear = (cb) ->
  fs.truncate "sales.db", 0, cb

Database.init = (cb) ->
  Products.createTable cb

Database.close = (cb) ->
  Products.closeDatabase cb

Database.ProductsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    console.log data
    Products.create data, (err) ->
      cb err

