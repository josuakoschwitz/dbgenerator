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

Database.count = (cb) ->
  Products.count (err, amount) ->
    console.log "Products: #{amount}"
    cb err

Database.close = (cb) ->
  Products.closeDatabase cb

Database.ProductsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    Products.create data, (err) ->
      cb err

Database.ProductsToCsv = (path, cb) ->
  Products.all (err, data) ->
    return cb err if err
    Csv.writeFile path, data, 'utf8', (err) -> cb err

