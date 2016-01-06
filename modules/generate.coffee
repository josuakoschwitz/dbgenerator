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


#––– random dates ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

randomDate = () ->
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
  postalCode = '00000'
  city = 'Chemnitz'
  state = 'Sachen'
  country = 'Deutschland'

  # grouping customers
  birthDay = randomDate()
  _agegroup = ''
  _group = ''

  # return
  cb null, ID: id, TITLE: title, NAME: name, FIRSTNAME: firstName, CITY: city, POSTALCODE: postalCode, STATE: state, COUNTRY: country, BIRTHDAY: birthDay, _AGEGROUP: _agegroup, _GROUP: _group

createSomeCustomers = (count, cb) ->
  bar = new ProgressBar '╢:bar╟ :current Customers (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneCustomer n, next
  , (err, customers) ->
    cb err, customers

Generate.customers = (cb) ->
  createSomeCustomers config.customers.count, (err, customers) ->
    return cb err if err
    Database.addCustomers customers, cb


#––– generate orders –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Generate.orders = (cb) ->
  cb null


#––– generate order details ––––––––––––––––––––––––––––––––––––––––––––––––––––
