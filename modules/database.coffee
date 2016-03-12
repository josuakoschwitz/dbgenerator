Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"


#––– Product –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Database.product = {}
tableProduct = new Array()

Database.product.importCsv = (path, cb) ->
  Csv.readFile path:path, (err, data) ->
    return cb err if err
    tableProduct = data
    return cb null

Database.product.get = (productId) ->
  _.clone tableProduct[productId-1]

Database.product.count = (cb) ->
  cb null, tableProduct.length

Database.product.exportCsv = (path, cb) ->
  Csv.writeFile tableProduct, path:path, (err) -> cb err


#––– Location ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableLocation = new Array()
indexLocation = LocationID: new Array() # Index-like Structure
Database.location = {}

updateIndex = (data) ->
  for row in data
    indexLocation.LocationID[ Number(row.LocationID) ] = row

Database.location.importCsv = (path, cb) ->
  Csv.readFile path:path, (err, data) ->
    return cb err if err
    tableLocation = data
    updateIndex tableLocation
    return cb null

Database.location.get = (LocationID) ->
  _.clone indexLocation.LocationID[ Number(LocationID) ]

Database.location.all = ->
  _.clone tableLocation

Database.location.selection = (cb) ->
  for key of tableLocation
    delete tableLocation[key].PostalCode
    delete tableLocation[key].Population
  cb null

Database.location.exportCsv = (path, cb) ->
  Csv.writeFile tableLocation, path:path, (err) -> cb err


#––– Customer ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableCustomer = new Array()
Database.customer = {}

Database.customer.create = (data, cb) ->
  tableCustomer.push.apply tableCustomer, data
  cb null

Database.customer.get = (customerId) ->
  _.clone tableCustomer[customerId-1]

Database.customer.exportCsv = (path, cb) ->
  Csv.writeFile tableCustomer, path:path, (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableOrder = new Array()
Database.order = {}

Database.order.create = (data, cb) ->
  tableOrder.push data
  cb null

Database.order.exportCsv = (path, cb) ->
  Csv.writeFile tableOrder, path:path, (err) -> cb err


#––– Order Detail ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableOrderDetail = new Array()
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


#––– Customer Joined –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableCustomerJoined = new Array()
Database.customerJoined = {}

Database.customerJoined.create = (cb) ->
  tableCustomerJoined = tableCustomerJoined.concat _.map tableCustomer, (customerRow) ->
    customerRow.PlzZone = customerRow.PostalCode[0]
    customerRow.Country = "Deutschland"
    locationRow = Database.location.get customerRow.LocationID
    locationRow.Coordinate = "#{locationRow.Longitude};#{locationRow.Latitude};0"
    _.pick _.extend( customerRow, locationRow ), "CustomerID", "Title", "Name", "FirstName", "Birthday", "PostalCode", "City", "State", "PlzZone", "Country", "Coordinate"
  cb null

Database.customerJoined.exportCsv = (path, cb) ->
  Csv.writeFile tableCustomerJoined, path:path, (err) -> cb err


#––– Order Joined ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

tableOrderJoined = new Array()
Database.orderJoined = {}

Database.orderJoined.create = (cb) ->
  tableOrderJoined = tableOrderJoined.concat _.map tableOrderDetail, (orderDetailRow) ->
    orderDetailRow.UnitOfMeasure = "ST"
    orderDetailRow.CURRENCY = "EUR"
    orderRow = _.clone tableOrder[ orderDetailRow.OrderID - 1 ]
    _.pick _.extend( orderRow, orderDetailRow ), "OrderDetailID", "OrderID", "CustomerID","DistributionChannelID","OrderDate","OrderDiscount","ProductID","Quantity","UnitPrice","Discount","UnitOfMeasure","CURRENCY"
  cb null

Database.orderJoined.exportCsv = (path, cb) ->
  Csv.writeFile tableOrderJoined, path:path, (err) -> cb err
