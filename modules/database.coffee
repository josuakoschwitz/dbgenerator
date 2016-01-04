Database = module.exports

### libraries ###
fs = require "fs"
async = require "async"

### modules ###
Csv = require "./csv"
Customers = require "./database/customers"
Distribution = require "./database/distribution"
Orders = require "./database/orders"
OrderDetails = require "./database/orderdetails"
Products = require "./database/products"


#––– general database operations –––––––––––––––––––––––––––––––––––––––––––––––

Database.clear = (cb) ->
  fs.truncate "sales.db", 0, cb

Database.init = (cb) ->
  # use async.js only to collect errors
  async.series [
    (cb) -> Customers.createTable cb
    (cb) -> Distribution.createTable cb
    (cb) -> Orders.createTable cb
    (cb) -> OrderDetails.createTable cb
    (cb) -> Products.createTable cb
  ], (err) -> cb err

Database.count = (cb) ->
  Products.count (err, amount) ->
    console.log "Products: #{amount}"
    cb err

Database.close = (cb) ->
  # use async.js only to collect errors
  async.series [
    (cb) -> Customers.closeDatabase cb
    (cb) -> Distribution.closeDatabase cb
    (cb) -> Orders.closeDatabase cb
    (cb) -> OrderDetails.closeDatabase cb
    (cb) -> Products.closeDatabase cb
  ], (err) -> cb err


#––– Products ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.ProductsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    Products.create data, (err) ->
      cb err

Database.ProductsToCsv = (path, cb) ->
  Products.all (err, data) ->
    return cb err if err
    Csv.writeFile path, data, 'utf8', (err) -> cb err


#––– Customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.CustomersToCsv = (path, cb) ->
  Customers.allExport (err, data) ->
    return cb err if err
    Csv.writeFile path, data, 'utf8', (err) -> cb err
