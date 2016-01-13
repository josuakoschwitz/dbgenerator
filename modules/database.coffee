Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"

### private variables ###
product = new Array()
customer = new Array()
order = new Array()
orderDetail = new Array()


#––– Helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––




#––– Product –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.product = {}

Database.product.count = (cb) ->
  cb null, product.length

Database.product.importCsv = (path, cb) ->
  Csv.readFile path, 'utf8', ';', (err, data) ->
    return cb err if err
    product = data
    return cb null

Database.product.get = (productId) ->
  _.clone product[productId-1]

Database.product.exportCsv = (path, cb) ->
  Csv.writeFile path, product, 'utf8', (err) -> cb err


#––– Customer ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.customer = {}

Database.customer.create = (data, cb) ->
  customer = customer.concat data
  cb null

Database.customer.get = (customerId) ->
  _.clone customer[customerId-1]

Database.customer.exportCsv = (path, cb) ->
  Csv.writeFile path, customer, 'utf8', (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.order = {}

Database.order.create = (data, cb) ->
  order = order.concat data
  cb null

Database.order.exportCsv = (path, cb) ->
  Csv.writeFile path, order, 'utf8', (err) -> cb err


#––– Order Detail ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.orderDetail = {}

Database.orderDetail.create = (data, cb) ->
  # make a single OrderDetail to an array
  data = [data] unless _.isArray data
  # manage IDs automatically inside this function
  nextID = orderDetail[orderDetail.length-1]?.OrderDetailID + 1 or 1
  row.OrderDetailID = nextID + i for row, i in data
  # save
  orderDetail = orderDetail.concat _.extend data
  cb null

Database.orderDetail.exportCsv = (path, cb) ->
  Csv.writeFile path, orderDetail, 'utf8', (err) -> cb err
