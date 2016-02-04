Generate = module.exports

### libraries ###
_ = require "underscore"
sugar = require "sugar"
async = require "async"
ProgressBar = require "progress"

### modules ###
Database = require "./database"



#––– data ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

### configs ###
# uses https://www.bmvit.gv.at/service/publikationen/verkehr/fuss_radverkehr/downloads/riz201503.pdf
# uses https://de.wikipedia.org/wiki/Altersstruktur
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
  family: require "../data/names/family.json"
  female: require "../data/names/female.json"
  male:   require "../data/names/male.json"

### global variables ###
random = {}



#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# in:   object or array that has frequencies in its values
# out:  function selecting a random key of the input by frequencies when called
randomize = (obj) ->
  # normalize, cumulate, to array
  sum = 0
  cummulated = _.mapObject obj, (val, key) -> sum += val
  normalized = _.mapObject cummulated, (val, key) -> val / sum
  array = _.map normalized, (value, key) -> key: key, prob: value
  return ->
    rand = Math.random()
    i = _.findIndex array, (item) -> item.prob > rand
    array[i].key

# same as randomize
# but should be much faster for really large datasets (not yet tested)
randomizeFast = (obj) ->
  # normalize, cumulate, to array
  sum = 0
  cummulated = _.mapObject obj, (val, key) -> sum += val
  normalized = _.mapObject cummulated, (val, key) -> val / sum
  array = _.map normalized, (value, key) -> key: key, prob: value
  # heuristic for pivot
  middle = ( _.findIndex array, (item) -> item.prob > 0.5 ) / array.length
  return ->
    rand = Math.random()
    start = 0
    end = array.length
    # binary search – should be much faster for really large frequencies
    while end - start > 10
      pivot = Math.floor start + middle * (end-start)
      if rand < array[pivot].prob then end = pivot
      else start = pivot
    i = _.findIndex array, (item) -> item.prob > rand
    array[i].key

chose = (data) ->
  rand = Math.random()
  _.findKey data, (value) -> value > rand

Generate.prepare = (cb) ->

  # customers / groups
  random.age = randomize config.customers.age15to80
  random.group = randomize config.customers.group

  # customers / names
  random.familyName = randomize names.family
  random.femaleName = randomize names.female
  random.maleName = randomize names.male

  # customers / locations, retail
  locations = {}
  locationsRetail = {}
  _.each Database.location.all(), (row) ->
    population = Number(row.Population)
    stateFactor = config.customers.state[row.State]  # distribution by: https://www.bmvit.gv.at/service/publikationen/verkehr/fuss_radverkehr/downloads/riz201503.pdf
    nearRetail = customersByDistance row.Latitude, row.Longitude  # more customers in citys with retail stores
    locations[ row.LocationID ] = population * stateFactor * nearRetail
    locationsRetail[ row.LocationID ] = population * stateFactor * nearRetail * retailByDistance row.Latitude, row.Longitude
  random.location = randomize locations

  # retail correction
  all = _.reduce (_.map locations, (value) -> value), (memo, curr) -> memo + curr
  retail = _.reduce locationsRetail, (memo, curr) -> memo + curr
  calcRetail = retail / all
  config.orders.retailFactor = _.map config.orders.buy_retail, (actualRetail) -> actualRetail / calcRetail

  # orders / shopping basket
  random.buyAmount = randomize config.orders.buy_amount
  random.addAmount = randomize config.orders.add_amount

  # products / campaign
  config.orders.campaigns = new Array()
  random.campaignValue = randomize config.orders.campaign_value

  # products / discount
  config.products.discount = _(64).times -> {discount: 0, days: 0}

  # no errors
  cb null



#––– customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

retailByDistance = (lat, lon) ->
  distance = retailDistance lat, lon
  return 0.8 if distance < 10
  return 0.1 if distance > 80
  return 0.9 - 0.01 * distance # if between 10 km and 80 km

customersByDistance = (lat, lon) ->
  distance = retailDistance lat, lon
  return 1.5 if distance < 10
  return 1.0 if distance > 60
  return 1.6 - 0.01 * distance

retailDistance = (lat1, lon1) ->
  distances = _.mapObject config.customers.retail_stores, (coordinate, city) ->
    lat1 = Number(lat1)
    lon1 = Number(lon1)
    lat2 = Number(coordinate[0])
    lon2 = Number(coordinate[1])
    dx = 111.3 * Math.cos( (lat1+lat2) / 2 / 180 * Math.PI ) * Math.abs( lon1 - lon2 )
    dy = 111.3 * Math.abs( lat1 - lat2 )
    Math.sqrt( dx * dx + dy * dy )
  _.values(distances).reduce (prev, curr) -> _.min [prev, curr]

randomBirthday = ->
  # age range
  index = random.age()
  fromAge = index * 5 + 20
  # random date
  randomDays = Math.floor( Math.random() * 365 * 5 + 1 )
  return Date.create().beginningOfYear().addYears(-fromAge).addDays(randomDays)

setAgeGroup = (birthday) ->
  age = Date.create().yearsSince birthday
  return "51-70" if age > 50
  return "31-50" if age > 30
  return "14-30"

createOneCustomer = (id, cb) ->
  time1 = Date.now()
  # name
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  name = do random.familyName
  firstName = do random.femaleName if title is "Frau"
  firstName = do random.maleName if title is "Herr"
  birthday = do randomBirthday

  # location
  locationID = do random.location
  location = Database.location.get locationID
  postalCode = location.PostalCode[ Math.floor Math.random() * location.PostalCode.length ]

  # grouping customers
  _agegroup = setAgeGroup(birthday)  # "51-70", "31-50", "14-30"
  _group = random.group()             # "family", "athletic", "outdoor"

  # probability that this customer buys in a retail store rather than in an eShop
  # dependig on distance to retail stores
  _retail = retailByDistance location.Latitude, location.Longitude

  # return
  cb null,
    CustomerID: id
    Title: title
    Name: name
    FirstName: firstName
    Birthday: birthday
    PostalCode: postalCode
    LocationID: locationID
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

createOneOrder = (orderId, orderDate, cb) ->

  # choose customer
  remainingLeads = config.customers.count - ( config.customers.current_lead - 1)
  remainingOrders = config.orders.count - ( orderId - 1 )
  pConversion = remainingLeads / remainingOrders
  if pConversion > Math.random()
    customerId = config.customers.current_lead
    config.customers.current_lead += 1
  else
    customersCount = config.customers.current_lead - 1
    customerId = Math.floor Math.random() * customersCount + 1
  customer = Database.customer.get customerId

  # correct retail probability
  year =  orderDate.getFullYear() + config.orders.years - Date.create().getFullYear()
  retailFactor = config.orders.retailFactor[year]
  # set the distributionChannel (retail / eShop) depending on customer._retail
  if Math.random() < customer._retail * retailFactor * 7/5 and orderDate.isWeekday()
    distributionChannelId = 1 # retail
  else
    distributionChannelId = 2 # eShop

  # add Order to Database
  order =
    OrderID: orderId,
    CustomerID: customerId,
    DistributionChannelID: distributionChannelId,
    OrderDate: orderDate
  Database.order.create order, (err) -> return cb err if err

  # create orderDetails to that order
  createSomeOrderDetails orderId, customer, (err, orderDetails) ->
    return cb err if err
    Database.orderDetail.create orderDetails, (err) ->
      console.log err if err
  cb null


createSomeOrdersAt = (orderIdOffset, count, date, cb) ->
  month = date.getMonth()

  # check each day if to start a campaign
  if Math.random() < config.orders.campaign_prob[ month ] / 30
    value = do random.campaignValue
    volume = Math.floor count * config.orders.campaign_duration * config.orders.campaign_volume[ month ]
    duration = config.orders.campaign_duration
    config.orders.campaigns.push value: value, volume: volume, end: date.clone().addDays(duration)
  config.orders.campaigns = config.orders.campaigns.filter (campaign) -> date < campaign.end

  # change discount of all products
  config.products.discount = config.products.discount.map (actualDiscount) ->
    # set a discount
    if Math.random() < config.orders.discount_prob[ month ] / 30
      min = config.orders.discount_value_min[ month ]
      max = config.orders.discount_value_max[ month ]
      days = config.orders.discount_duration
      discount = (Math.round ( Math.random() * (max-min) + min ) * 100) / 100
    else
      days = actualDiscount.days - 1
      discount = if days > 0 then actualDiscount.discount else 0.0
    days: days, discount: discount

  # create orders
  for orderId in [orderIdOffset...orderIdOffset+=count]
    createOneOrder orderId, date, (err) -> return cb err if err
  cb null


createSomeOrders = (totalCount, cb) ->
  # date init
  totalYears = config.orders.years
  startDate = Date.create().beginningOfYear().addYears( -totalYears )

  # helper function
  normalizeArray = (array, total) ->
    sum = _.reduce array, (prev, curr) -> prev + curr
    diff = 0
    _.map array, (value) ->
      tmp = value / sum * total + diff
      count = Math.round tmp
      diff = tmp - count
      count

  # make growth relative to the start date
  growth = config.orders.growth
  prev = 1
  growthMultipl = _.map growth, (fac) -> prev *= fac
  prev = 1
  parts = _.map growthMultipl, (fac) -> part=(fac+prev)/2; prev=fac; part
  countYearly = normalizeArray parts, totalCount

  # split count into days
  countsYearly = _.map countYearly, (count, year) ->
    start = startDate.clone().addYears( year )
    end = startDate.clone().addYears( year ).endOfYear()
    days = start.daysUntil( end )
    parts = [0...days].map (day) ->
      # ascending frequency (linear interpolation should be enough)
      part = 1 + day / days * ( growth[year] - 1 )
      # depending on config.orders.buy_density
      months = config.orders.buy_density.length
      monthFull = (day+0.5) / days * months
      month = Math.floor monthFull
      monthPart = monthFull - month
      curve = config.orders.buy_density
      saisonFactor = curve[ month % months ] * (1 - monthPart)  +  curve[ (month+1) % months ] * monthPart
      part *= saisonFactor
      # ± fuzzy
      part *= Math.random() * config.orders.buy_fuzzy_daily + 1
      # return
      part
    # map count to days
    normalizeArray parts, count

  # join all days into one timeline and run order creation day-to-day
  countsOverall = _.flatten countsYearly
  bar = new ProgressBar '║:bar║ :current Orders (:etas)', complete: '▓', incomplete: '░', total: totalCount
  orderIdOffset = 1
  # run order creation
  for count, day in countsOverall
    date = startDate.clone().addDays( day )
    bar.tick count
    createSomeOrdersAt orderIdOffset, count, date, (err) -> return cb err if err
    orderIdOffset += count
  cb null


Generate.orders = (cb) ->
  createSomeOrders config.orders.count, (err) ->
    return cb err if err
    cb null




#––– orderDetails ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

createShoppingBasket = (customer) ->
  amount = do random.buyAmount
  ranking = _.map config.products.preferences, (value, index) ->
    value *= config.products.preferences_group[ customer._group ][index] *
            config.products.preferences_sex[ customer.Title ][index] *
            config.products.preferences_age[ customer._agegroup ][index] *
            ( 1 + Math.random() * 0.5 )
    [index+1, value]
  ranking = _.sortBy ranking, (value) -> -value[1]
  ranking = ranking.slice(0, amount)
  _.map ranking, (value) -> value[0]

extendShoppingBasket = (productIds) ->
  amount = do random.addAmount
  return productIds if amount is 0
  ranking = []
  for productId in productIds
    for value, index in config.products.correlation[productId]
      ranking[index+1] = (value + 0.1) * (ranking[index+1] or 1)
  ranking = _.map ranking, (value, index) -> [index, value]
  ranking = _.filter ranking, (VALUE) -> (value[1] not in productIds) and value[1]>0
  ranking = _.shuffle ranking
  ranking = _.sortBy ranking, (value) -> -value[1]
  ranking = ranking.slice(0, amount)
  ranking = _.map ranking, (value) -> value[0]
  productIds.concat ranking

createOneOrderDetail = (orderId, productId, cb) ->
  # FEATURE: product ➔ quantity
  # TODO (medium priority): set more realistic quantities in the config file
  quantity = 1 + Math.floor Math.random() * config.products.quantities[productId-1]
  # pick unitPrice from the Product
  unitPrice = Database.product.get( productId ).UnitPrice
  # FEATURE: discountplan/product ➔ discount/product
  # TODO (medium priority): increase buy probability as discount becomes higher
  discount = config.products.discount[ productId-1 ].discount

  # return
  cb null,
    OrderDetailID: undefined
    OrderID: orderId
    ProductID: productId
    Quantity: quantity
    UnitPrice: unitPrice
    Discount: discount

createSomeOrderDetails = (orderId, customer, cb) ->
  # select products
  productIds = createShoppingBasket customer
  productIds = extendShoppingBasket productIds

  # create order details
  async.map productIds, (productId, cb) ->
    createOneOrderDetail orderId, productId, cb
  , (err, orderDetails) ->
    cb err, orderDetails
