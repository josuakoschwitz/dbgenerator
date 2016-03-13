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



#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# in:   object or array that has frequencies in its values
# out:  function selecting a random key of the input by frequencies when called
randomize = (obj) ->
  # normalize, cumulate, to array
  sum = 0
  cummulated = _.mapObject obj, (val, key) -> sum += val
  normalized = _.mapObject cummulated, (val, key) -> val / sum
  array = _.map normalized, (value, key) -> key: key, prob: value
  obj.random = ->
    rand = Math.random()
    i = _.findIndex array, (item) -> item.prob > rand
    if (array[i].key).match /^\d+$/ then Number(array[i].key) else array[i].key
  return obj

# same as above but should be much faster for really large datasets (not yet tested)
randomizeFast = (obj) ->
  # normalize, cumulate, to array
  sum = 0
  cummulated = _.mapObject obj, (val, key) -> sum += val
  normalized = _.mapObject cummulated, (val, key) -> val / sum
  array = _.map normalized, (value, key) -> key: key, prob: value
  # heuristic for pivot
  middle = ( _.findIndex array, (item) -> item.prob > 0.5 ) / array.length
  obj.random = ->
    rand = Math.random()
    start = 0
    end = array.length
    # binary search – should be much faster for really large frequencies
    while end - start > 10
      pivot = Math.floor start + middle * (end-start)
      if rand < array[pivot].prob then end = pivot
      else start = pivot
    i = _.findIndex array, (item) -> item.prob > rand
    if (array[i].key).match /^\d+$/ then Number(array[i].key) else array[i].key
  return obj

chose = (data) ->
  rand = Math.random()
  _.findKey data, (value) -> value > rand

Generate.prepare = (cb) ->

  # customers / groups
  config.customers.age15to80 = randomize config.customers.age15to80
  config.customers.group = randomize config.customers.group

  # customers / names
  names.family = randomize names.family
  names.female = randomize names.female
  names.male = randomize names.male

  # customers / locations, retail
  locations = {}
  locationsRetail = {}
  _.each Database.location.all(), (row) ->
    population = Number(row.Population)
    stateFactor = config.customers.state[row.State]  # distribution by: https://www.bmvit.gv.at/service/publikationen/verkehr/fuss_radverkehr/downloads/riz201503.pdf
    nearRetail = customersByDistance row.Latitude, row.Longitude  # more customers in citys with retail stores
    locations[ row.LocationID ] = population * stateFactor * nearRetail
    locationsRetail[ row.LocationID ] = population * stateFactor * nearRetail * retailByDistance row.Latitude, row.Longitude
  config.locations = randomize locations

  # retail correction
  all = _.reduce (_.map locations, (value) -> value), (memo, curr) -> memo + curr
  retail = _.reduce locationsRetail, (memo, curr) -> memo + curr
  calcRetail = retail / all
  config.orders.retailFactor = _.map config.orders.buy_retail, (actualRetail) -> actualRetail / calcRetail

  # orders / shopping basket
  config.orders.buy_amount = randomize config.orders.buy_amount
  config.orders.add_amount = randomize config.orders.add_amount

  # products / campaign
  config.orders.campaigns = new Array()
  config.orders.campaign_value = randomize config.orders.campaign_value

  # products / discount
  config.products.discount = _(64).times -> {discount: 0, days: 0}

  # products / normalize probability
  productCount = config.products.preferences.length
  if config.products.normalize
    config.products.normalize = []
    # buy probability
    age = config.customers.age15to80
    for i in [0...productCount]
      config.products.normalize[i] = 1 / (
        (
          config.products.preferences_group.family[i]   * config.customers.group.family +
          config.products.preferences_group.athletic[i] * config.customers.group.athletic +
          config.products.preferences_group.outdoor[i]  * config.customers.group.outdoor
        ) * (
          config.products.preferences_sex.Frau[i]       * 0.5 +
          config.products.preferences_sex.Herr[i]       * 0.5
        ) * (
          config.products.preferences_age['14-30'][i]   * (age[0]+age[1]+age[2]) +
          config.products.preferences_age['31-50'][i]   * (age[3]+age[4]+age[5]+age[6]) +
          config.products.preferences_age['51-80'][i]   * (age[7]+age[8]+age[9]+age[10]+age[11]+age[12])
        )
      )
    # TODO cross selling probability (does not work this way – use ratio between count of selling/crossellling)
    # cs = _.map config.products.correlation, (row) ->
    #         row.map (value) -> (value + 0.1)**2
    #       .reduce (prev, curr) ->
    #         _.zip(prev,curr).map (product) -> product[0] + product[1]
    # for value, i in cs
    #   config.products.normalize[i] /= value
  else
    config.products.normalize = []
    config.products.normalize[i] = 1 for i in [0...productCount]

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
  index = config.customers.age15to80.random()
  fromAge = index * 5 + 20
  # random date
  randomDays = Math.floor( Math.random() * 365 * 5 + 1 )
  return Date.create().beginningOfYear().addYears(-fromAge).addDays(randomDays)

setAgeGroup = (birthday) ->
  age = Date.create().yearsSince birthday
  return "51-80" if age > 50
  return "31-50" if age > 30
  return "14-30"

createOneCustomer = (id, cb) ->
  time1 = Date.now()
  # name
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  name = do names.family.random
  firstName = do names.female.random if title is "Frau"
  firstName = do names.male.random if title is "Herr"
  birthday = do randomBirthday

  # location
  locationID = do config.locations.random
  location = Database.location.get locationID
  postalCode = location.PostalCode[ Math.floor Math.random() * location.PostalCode.length ]

  # grouping customers
  _agegroup = setAgeGroup(birthday)  # "51-80", "31-50", "14-30"
  _group = do config.customers.group.random  # "family", "athletic", "outdoor"

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

  # create orderDetails to that order
  createSomeOrderDetails orderId, customer, (err, orderDetails) ->
    return cb err if err

    # apply campaign discount
    # totalPrice = orderDetails.map((oderDetail) -> Number(oderDetail.UnitPrice)).reduce (prev, curr) -> prev + curr
    order.OrderDiscount = 0
    for campaign in config.orders.campaigns when campaign.discountProb > Math.random()
      order.OrderDiscount = campaign.discountValue

    # write order and orderDetails to database
    Database.order.create order, (err) -> return cb err if err
    Database.orderDetail.create orderDetails, (err) -> return cb err if err

  cb null


createSomeOrdersOn = (orderIdOffset, count, date, cb) ->
  month = date.getMonth()

  # check each day if to start a campaign
  if Math.random() < config.orders.campaign_prob[ month ] / 30
    discountValue = do config.orders.campaign_value.random
    discountProb = config.orders.campaign_volume[ month ] * ( 1 + (Math.random() * 2 - 1) * config.orders.campaign_volume_fuzzy)
    duration = config.orders.campaign_duration
    config.orders.campaigns.push discountValue: discountValue, discountProb: discountProb, end: date.clone().addDays(duration)
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
    createSomeOrdersOn orderIdOffset, count, date, (err) -> return cb err if err
    orderIdOffset += count
  cb null


Generate.orders = (cb) ->
  createSomeOrders config.orders.count, (err) ->
    return cb err if err
    cb null




#––– orderDetails ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# TODO: memoize this function (_.memoize didn't work well)
randomizeBasket = (group, title, agegroup) ->
  ranking = config.products.preferences.map (value, index) ->
    Number( value *
    config.products.preferences_group[ group ][index] *
    config.products.preferences_sex[ title ][index] *
    config.products.preferences_age[ agegroup ][index] *
    config.products.normalize[index] )
    # ( 1 + Math.random() * 0.5 ) # TODO: remove this line when function becomes memoized
  -> randomize(ranking).random() + 1

createShoppingBasket = (customer) ->
  amount = do config.orders.buy_amount.random
  productIds = []
  while productIds.length < amount
    productIds.push do randomizeBasket customer._group, customer.Title, customer._agegroup
  productIds

# TODO: memoize this function (_.memoize didn't work well)
randomizeExtendBaseket = (productIds) ->
  count = config.products.preferences.length
  ranking = (0.9 + 0.2 * Math.random() for i in [0...count])
  for productId in productIds
    for value, index in config.products.correlation[productId]
      ranking[index] *= (value + 0.1)**2
  -> randomize(ranking).random() + 1

extendShoppingBasket = (referenceProductIds) ->
  amount = do config.orders.add_amount.random
  productIds = []
  while productIds.length < amount
    productIds.push do randomizeExtendBaseket referenceProductIds
  productIds

createOneOrderDetail = (orderId, productId, quantity, crossSeling, cb) ->
  unitPrice = Database.product.get( productId ).UnitPrice
  # TODO (low priority): increase buy probability as discount becomes higher
  discount = config.products.discount[ productId-1 ].discount
  # return
  cb null,
    OrderDetailID: undefined
    OrderID: orderId
    ProductID: productId
    Quantity: quantity
    UnitPrice: unitPrice
    Discount: discount
    _crossSelling: crossSeling

createSomeOrderDetails = (orderId, customer, cb) ->
  # select products
  productIds1 = createShoppingBasket customer
  productIds2 = extendShoppingBasket productIds1

  # merge doubles
  productIds = [].concat productIds1, productIds2
  uniqueProductIds = _.uniq productIds

  # quantities
  quantities = {}
  quantities[id] = (quantities[id] or 0) + 1 for id in productIds
  # quantities just for cross-selling statistics
  quantities2 = {}
  quantities2[id] = (quantities2[id] or 0) + 1 for id in productIds2

  # console.log "#{JSON.stringify(quantities).replace(/[\"\{\}]/g,"")} #{if _.keys(quantities2).length > 0 then '--->' else ''} #{JSON.stringify(quantities2).replace(/[\"\{\}]/g,"")}"

  # create order details
  async.map uniqueProductIds, (productId, cb) ->
    crossSelling = productId in productIds2
    createOneOrderDetail orderId, productId, quantities[productId], quantities2[productId] or 0, cb
  , (err, orderDetails) ->
    cb err, orderDetails
