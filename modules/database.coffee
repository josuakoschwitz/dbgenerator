Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"

### private variables ###
products = new Array()
customers = new Array()
orders = new Array()
orderDetails = new Array()


#––– Products –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.productsCount = (cb) ->
  console.log "Products: #{products.length}"

Database.productsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    products = data
    return cb null

Database.productsToCsv = (path, cb) ->
  Csv.writeFile path, products, 'utf8', (err) -> cb err


#––– Customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addCustomers = (data, cb) ->
  customers = customers.concat data
  cb null

Database.getCustomer = (customerId) ->
  _.clone customers[customerId-1]

Database.customersToCsv = (path, cb) ->
  Csv.writeFile path, customers, 'utf8', (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addOrders = (data, cb) ->
  orders = orders.concat data
  cb null

Database.ordersToCsv = (path, cb) ->
  Csv.writeFile path, orders, 'utf8', (err) -> cb err


#––– Order Details –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.addOrderDetails = (data, cb) ->
  # make a single OrderDetail to an array
  data = [data] unless _.isArray data
  # manage IDs automatically inside this function
  nextId = orderDetails[orderDetails.length-1]?.OrderDetailId + 1 or 1
  row.OrderDetailId = nextId + i for row, i in data
  # save
  orderDetails = orderDetails.concat _.extend data
  cb null

Database.orderDetailsToCsv = (path, cb) ->
  # console.log orderDetails
  Csv.writeFile path, orderDetails, 'utf8', (err) -> cb err
