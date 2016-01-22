Generate = module.exports

### libraries ###
_ = require "underscore"
sugar = require "sugar"
async = require "async"
ProgressBar = require "progress"

### modules ###
Database = require "./database"


#––– data –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

### configs ###
config =
  customers: require "../config/customers.json"
  orders: require "../config/orders.json"
  products: require "../config/products.json"

### names ###
# copyright by Deron Meranda
# source: http://deron.meranda.us/data/census-dist-2500-last.txt
# source: http://deron.meranda.us/data/census-dist-female-first.txt
# source: http://deron.meranda.us/data/census-dist-male-first.txt
names =
  family: require "../input/names/family.json"
  female: require "../input/names/female.json"
  male:   require "../input/names/male.json"

### locations ###
# source: http://www.fa-technik.adfc.de/code/opengeodb/DE.tab
locations =
  state: undefined
  city: undefined


#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

normalizeProbability = (obj) ->
  sum = 0
  obj = _.mapObject obj, (val, key) -> sum += val
  obj = _.mapObject obj, (val, key) -> val / sum

Generate.prepare = ->
  names.family = normalizeProbability names.family
  names.female = normalizeProbability names.female
  names.male = normalizeProbability names.male
  config.customers.age15to80 = normalizeProbability config.customers.age15to80
  config.orders.buy_amount = normalizeProbability config.orders.buy_amount
  config.orders.add_amount = normalizeProbability config.orders.add_amount

choseByProbability = (data) ->
  rand = Math.random()
  _.findKey data, (value) -> value > rand




#––– customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

randomBirthday = () ->
  # age range
  index = choseByProbability config.customers.age15to80
  fromAge = index * 5 + 20
  # random date
  randomDays = Math.floor( Math.random() * 365 * 5 + 1 )
  return Date.create().beginningOfYear().addYears(-fromAge).addDays(randomDays)

setAgeGroup = (birthday) ->
  age = Date.create().yearsSince birthday
  return "51-70" if age > 50
  return "31-50" if age > 30
  return "14-30"

randomInterestGroup = ->
   group = choseByProbability config.customers.group

retailByDistance = (lat1, lon1) ->
  distances = _.mapObject config.customers.retail_stores, (coordinate, city) ->
    lat2 = coordinate[0]
    lon2 = coordinate[1]
    dx = 111.3 * Math.cos( (lat1+lat2) / 2 / 180 * Math.PI ) * Math.abs( lon1 - lon2 )
    dy = 111.3 * Math.abs( lat1 - lat2 )
    Math.sqrt( dx * dx + dy * dy )
  distance = _.values(distances).reduce (prev, curr) ->
    if prev < curr then prev else curr
  # just linear and clamped
  return 0.8 if distance < 10
  return 0.1 if distance > 80
  return 0.9 - 0.01 * distance # if between 10 km and 80 km

createOneCustomer = (id, cb) ->
  # name
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  name = choseByProbability names.family
  firstName = choseByProbability names.female if title is "Frau"
  firstName = choseByProbability names.male if title is "Herr"
  birthday = randomBirthday()

  # location
  # TODO customer location distribution by: https://www.bmvit.gv.at/service/publikationen/verkehr/fuss_radverkehr/downloads/riz201503.pdf)
  postalCode = '09126'
  city = 'Chemnitz'
  state = 'Sachen'
  country = 'Deutschland'
  latitude = 50.8333
  longitude = 12.9167

  # grouping customers
  _agegroup = setAgeGroup(birthday)  # "51-70", "31-50", "14-30"
  _group = randomInterestGroup()        # "family", "athletic", "outdoor"

  # probability that this customer buys in a retail store rather than in an eShop
  # dependig on distance to retail stores
  _retail = retailByDistance latitude, longitude
  # _retail = config.customers.buy_channel.retail

  # return
  cb null,
    CustomerID: id
    Title: title
    Name: name
    FirstName: firstName
    Birthday: birthday
    PostalCode: postalCode
    City: city
    State: state
    Country: country
    Coordinate: [latitude, longitude]
    _agegroup: _agegroup
    _group: _group
    _retail: _retail

createSomeCustomers = (count, cb) ->
  bar = new ProgressBar '║:bar║ :current Customers (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneCustomer n+1, next
  , (err, customers) ->
    cb err, customers

Generate.customers = (cb) ->
  createSomeCustomers config.customers.count, (err, customers) ->
    return cb err if err
    Database.customer.create customers, cb




#––– orders ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

createOneOrder = (orderId, cb) ->

  # prepare for order date creation
  count = config.orders.count
  totalYears = config.orders.years
  startDate = Date.create().beginningOfYear().addYears( -totalYears )
  totalDays = Date.create().beginningOfYear().daysSince( startDate ) - 0.0001
  # ascending frequency per year
  growth = config.orders.growth
  currentPartialYear = Math.log( 1 + orderId / count * ( Math.pow( growth, totalYears ) - 1 )) / Math.log( growth )
  # write order date
  day = Math.floor currentPartialYear / totalYears * totalDays
  orderDate = startDate.addDays( day )
  # TODO (priority low):    different growth-factors in different years
  # TODO (priority medium): maky orderDate depending on config.orders.buy_month
  # TODO (priority medium): make orderDate fuzzy

  # assign customer to order date
  remainingLeads = config.customers.count - ( config.customers.current_lead - 1)
  remainingOrders = count - ( orderId - 1 )
  pConversion = remainingLeads / remainingOrders
  if pConversion > Math.random()
    customerId = config.customers.current_lead
    config.customers.current_lead += 1
  else
    customersCount = config.customers.current_lead - 1
    customerId = Math.floor Math.random() * customersCount + 1
  customer = Database.customer.get customerId

  # set the distributionChannel (retail / eShop) depending on customer._retail
  distributionChannelId = if Math.random() > customer._retail then 1 else 0

  # orderDetails
  createSomeOrderDetails orderId, customer, (err, orderDetails) ->
    return cb err if err
    Database.orderDetail.create orderDetails, (err) ->
      console.log err if err

  # return
  cb null,
    OrderID: orderId,
    CustomerID: customerId,
    DistributionChannelID: distributionChannelId,
    OrderDate: orderDate

createSomeOrders = (count, cb) ->
  bar = new ProgressBar '║:bar║ :current Orders (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneOrder n+1, next
  , (err, orders) ->
    cb err, orders

Generate.orders = (cb) ->
  createSomeOrders config.orders.count, (err, orders) ->
    return cb err if err
    Database.order.create orders, cb




#––– orderDetails ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

createShoppingBasket = (customer) ->
  amount = choseByProbability config.orders.buy_amount
  # TODO – for now randomly and without duplicate detection
  _.map [0...amount], -> productId = Math.floor Math.random() * 64 + 1

extendShoppingBasket = (productIds) ->
  amount = choseByProbability config.orders.add_amount
  return productIds if amount = 0
  ranking = []
  for productId in productIds
    for value, index in config.products.correlation[productId]
      ranking[index+1] = value + ranking[index+1] or 0
  # TODO – sort this ranking and take the highest rated products (without doubles) to the basket
  productIds

createOneOrderDetail = (orderId, productId, cb) ->
  # TODO (medium priority): set more realistic quantities in the config file
  quantity = 1 + Math.floor Math.random() * config.products.quantities[productId-1]
  # pick unitPrice from the Product
  unitPrice = Database.product.get( productId )[5]
  # TODO (medium priority): set an discount depending on dates and increase buy probability accordingly
  discount = 0

  # return
  cb null,
    OrderDetailID: undefined
    OrderID: orderId
    ProductID: productId
    Quantity: quantity
    UnitPrice: unitPrice
    Discount: discount
    UnitOfMeasure: "ST"
    CURRENCY: "EUR"

createSomeOrderDetails = (orderId, customer, cb) ->
  # select products
  productIds = createShoppingBasket customer
  productIds = extendShoppingBasket productIds

  # create order details
  async.map productIds, (productId, cb) ->
    createOneOrderDetail orderId, productId, cb
  , (err, orderDetails) ->
    cb err, orderDetails
