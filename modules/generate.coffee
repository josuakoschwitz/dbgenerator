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
  family: require "../config/names/family.json"
  female: require "../config/names/female.json"
  male:   require "../config/names/male.json"

### geodata ###
# http://www.fa-technik.adfc.de/code/opengeodb/DE.tab


#––– probability distribution ––––––––––––––––––––––––––––––––––––––––––––––––––

normalizeProbability = (obj) ->
  sum = 0
  obj = _.mapObject obj, (val, key) -> sum += val
  obj = _.mapObject obj, (val, key) -> val / sum

Generate.prepare = ->
  names.family = normalizeProbability names.family
  names.female = normalizeProbability names.female
  names.male = normalizeProbability names.male
  config.customers.age15to80 = normalizeProbability config.customers.age15to80

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

createOneCustomer = (id, cb) ->
  # name
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  name = choseByProbability names.family
  firstName = choseByProbability names.female if title is "Frau"
  firstName = choseByProbability names.male if title is "Herr"

  # location  (distribution: https://www.bmvit.gv.at/service/publikationen/verkehr/fuss_radverkehr/downloads/riz201503.pdf)
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  postalCode = '09126'
  city = 'Chemnitz'
  state = 'Sachen'
  country = 'Deutschland'

  # grouping customers
  birthDay = randomBirthday()
  _agegroup = ''
  _group = ''
  _retail = 0.2 # TODO dependig on distance to retail stores

  # return
  cb null, ID: id, TITLE: title, NAME: name, FIRSTNAME: firstName, CITY: city, POSTALCODE: postalCode, STATE: state, COUNTRY: country, BIRTHDAY: birthDay, _AGEGROUP: _agegroup, _GROUP: _group, _RETAIL: _retail

createSomeCustomers = (count, cb) ->
  bar = new ProgressBar '╢:bar╟ :current Customers (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneCustomer n+1, next
  , (err, customers) ->
    cb err, customers

Generate.customers = (cb) ->
  createSomeCustomers config.customers.count, (err, customers) ->
    return cb err if err
    Database.addCustomers customers, cb


#––– orders ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# OrderDetailsID INTEGER PRIMARY KEY AUTOINCREMENT,
# OrderID INTEGER,
# ProductID INTEGER,
# Quantity INTEGER,
# UnitPrice DECIMAL(5,2),
# Discount REAL DEFAULT 0
createSomeOrderDetails = (customer) ->
  # TODO

createOneOrder = (orderId, cb) ->

  # TODO
  # for now: pure random
  # plan: every customer from the fist to the last exactly once
  #       customers buy again after a while
  #       maybe some further input is needed (in the config file)
  customerId = Math.floor Math.random() * config.customers.count + 1
  createSomeOrderDetails customerId
  customer = Database.getCustomer customerId

  # TODO
  # for now: default { 1: e-shop }
  # plan: depending on config.orders.buy_distribution
  #       and/or on the location of the customer
  distributionChanellId = 1

  # TODO
  # for now: simply one random day in the last five years
  # plan: depending on config.orders.buy_month
  randomDays = Math.floor( Math.random() * 365 * 5 + 1 )
  orderDate = Date.create().beginningOfYear().addYears(-5).addDays(randomDays)

  # return
  cb null, ORDERID: orderId, CUSTOMERID: customerId, DISTRIBUTIONCHANELLID: distributionChanellId, ORDERDATE: orderDate

createSomeOrders = (count, cb) ->
  bar = new ProgressBar '╢:bar╟ :current Orders (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneOrder n+1, next
  , (err, orders) ->
    cb err, orders

Generate.orders = (cb) ->
  createSomeOrders config.orders.count, (err, orders) ->
    return cb err if err
    Database.addOrders orders, cb
