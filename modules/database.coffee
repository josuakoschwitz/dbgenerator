Database = module.exports

### libraries ###
_ = require "underscore"
sugar = require "sugar"

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

Database.customer.statistic = (cb) ->
  console.log "\nSTATISTICS of customer groups"
  console.log "-> total amount of customers: #{ tableCustomer.length }"

  groupCount = {}
  groupCount[customer._group] = (groupCount[customer._group] or 0) + 1 for customer in tableCustomer
  console.log "-> interes groups: ", groupCount

  ageGroupCount = {}
  ageGroupCount[customer._agegroup] = (ageGroupCount[customer._agegroup] or 0) + 1 for customer in tableCustomer
  console.log "-> age groups: ", ageGroupCount

  titleCount = {}
  titleCount[customer.Title] = (titleCount[customer.Title] or 0) + 1 for customer in tableCustomer
  console.log "-> title: ", titleCount

  cb null


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

Database.order.statistic = (cb) ->
  years = _.groupBy tableOrder, (order) -> order.OrderDate.getFullYear()
  console.log "\nSTATISTICS amount of orders per year"
  for year, orders of years
    # calculation
    amount = orders.length
    retail = Math.round(1000 * orders.filter((order) -> order.DistributionChannelID is 1).length / amount) / 10
    eshop = 100 - retail
    # padding
    amount = amount.toString().padLeft(7)
    retail = retail.toString().padLeft(6) + "%"
    eshop = eshop.toString().padLeft(6) + "%"
    # print out
    console.log "#{year}: #{amount} orders #{retail} Retail #{eshop} eShop"
  cb null

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

Database.orderDetail.statistic = (cb) ->
  products = _.clone tableProduct
  products = products.map (product) -> product.amount = 0; product.amountCs = 0; product
  statistics = tableOrderDetail
    .reduce ((memo, oDetail) ->
      memo[oDetail.ProductID-1].amount += oDetail.Quantity - oDetail._crossSelling
      memo[oDetail.ProductID-1].amountCs += oDetail._crossSelling
      return memo), products
    .sort (p1, p2) ->
      p2.amount + p2.amountCs - p1.amount - p1.amountCs
  console.log "\nSTATISTICS of all bought products"
  statistics.forEach (p) -> console.log "#{p.amount.toString().padLeft(4)} + #{p.amountCs.toString().padLeft(4)} = #{(p.amount+p.amountCs).toString().padLeft(5)} ⨉ #{p.ProductID.padLeft(2)} #{p.ProductName} (#{p.ProductDescription})"

  # statistics
  count = statistics.map((p) -> p.amount + p.amountCs).reduce((a,b) -> a+b)
  mean = tableOrderDetail.length / 64
  stdDev = Math.sqrt( statistics
    .map (p) -> Math.pow (mean - p.amount - p.amountCs), 2
    .reduce (a, b) -> a + b )
  console.log "\nSTATISTICS amount of bought products (all)"
  console.log "-> count = #{count}"
  console.log "-> arithmetic mean = #{mean}"
  console.log "-> standard deviation (all) = #{stdDev}"
  count1 = statistics.map((p) -> p.amount).reduce((a,b) -> a+b)
  mean1 = count1 / 64
  stdDev1 = Math.sqrt( statistics
    .map (p) -> Math.pow (mean - p.amount), 2
    .reduce (a, b) -> a + b )
  console.log "\nSTATISTICS amount of bought products (without cross selling)"
  console.log "-> count = #{count1}"
  console.log "-> arithmetic mean = #{mean1}"
  console.log "-> standard deviation = #{stdDev1}"
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
