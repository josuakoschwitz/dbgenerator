Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"

### private variables ###
products = new Object()
customers = new Object()
orders = new Object()
orderDetails = new Object()


#––– Products –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.ProductsCount = (cb) ->
  console.log "Products: #{products.length}"

Database.ProductsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    products = data
    return cb null

Database.ProductsToCsv = (path, cb) ->
  Csv.writeFile path, products, 'utf8', (err) -> cb err


#––– Customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addCustomers = (data, cb) ->
  customers = data
  cb null

Database.CustomersToCsv = (path, cb) ->
  Csv.writeFile path, customers, 'utf8', (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addOrders = (data, cb) ->
  orders = data
  cb null

Database.OrdersToCsv = (path, cb) ->
  Csv.writeFile path, orders, 'utf8', (err) -> cb err


#––– Order Details –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addOrderDetails = (data, cb) ->
  orderDetails = data
  cb null

Database.OrderDetailsToCsv = (path, cb) ->
  Csv.writeFile path, orderDetails, 'utf8', (err) -> cb err
