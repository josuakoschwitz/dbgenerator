Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"

### private variables ###
tableProduct = new Array()
tableCustomer = new Array()
tableOrder = new Array()
tableOrderDetail = new Array()
tableOrderComplete = new Array()


#––– Helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––




#––– Product –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.product = {}

Database.product.count = (cb) ->
  cb null, tableProduct.length

Database.product.importCsv = (path, cb) ->
  Csv.readFile path:path, (err, data) ->
    return cb err if err
    tableProduct = data
    return cb null

Database.product.get = (productId) ->
  _.clone tableProduct[productId-1]

Database.product.exportCsv = (path, cb) ->
  Csv.writeFile tableProduct, path:path, (err) -> cb err


#––– Customer ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.customer = {}

Database.customer.create = (data, cb) ->
  tableCustomer.push.apply tableCustomer, data
  cb null

Database.customer.get = (customerId) ->
  _.clone tableCustomer[customerId-1]

Database.customer.exportCsv = (path, cb) ->
  Csv.writeFile tableCustomer, path:path, (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.order = {}

Database.order.create = (data, cb) ->
  tableOrder.push data
  cb null

Database.order.exportCsv = (path, cb) ->
  Csv.writeFile tableOrder, path:path, (err) -> cb err


#––– Order Detail ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.orderDetail = {}

Database.orderDetail.create = (data, cb) ->
  # make a single OrderDetail to an array
  data = [data] unless _.isArray data
  # manage IDs automatically inside this function
  nextID = tableOrderDetail[tableOrderDetail.length-1]?.OrderDetailID + 1 or 1
  row.OrderDetailID = nextID + i for row, i in data
  # save
  tableOrderDetail.push.apply tableOrderDetail, data
  cb null

Database.orderDetail.exportCsv = (path, cb) ->
  Csv.writeFile tableOrderDetail, path:path, (err) -> cb err


#––– Order Complete ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.orderComplete = {}

Database.orderComplete.createFromJoin = (cb) ->
  tableOrderComplete = tableOrderComplete.concat _.map tableOrderDetail, (orderDetailRow) ->
    orderRow = _.clone tableOrder[ orderDetailRow.OrderID - 1 ]
    _.pick _.extend( orderRow, orderDetailRow ), "OrderDetailID","CustomerID","DistributionChannelID","OrderDate","ProductID","Quantity","UnitPrice","Discount","UnitOfMeasure","CURRENCY"
  cb null

Database.orderComplete.exportCsv = (path, cb) ->
  Csv.writeFile tableOrderComplete, path:path, splitDate:true, (err) -> cb err
