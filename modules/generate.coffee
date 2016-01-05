Generate = module.exports

### libraries ###
_ = require "underscore"
async = require "async"
ProgressBar = require "progress"

### modules ###
Database = require "./database"

### names ###
# copyright by Deron Meranda
# source: http://deron.meranda.us/data/census-dist-2500-last.txt
# source: http://deron.meranda.us/data/census-dist-female-first.txt
# source: http://deron.meranda.us/data/census-dist-male-first.txt
names =
  family: require "../source/family-names.json"
  female: require "../source/female-names.json"
  male: require "../source/male-names.json"

### configs ###
config =
  buy: require "../config/buy.json"
  customers: require "../config/customers.json"
  products: require "../config/products.json"


#––– names –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

prepareNames = (obj) ->
  sum = 0
  obj = _.mapObject obj, (val, key) -> sum += val
  obj = _.mapObject obj, (val, key) -> val / sum

Generate.prepare = ->
  names.family = prepareNames names.family
  names.female = prepareNames names.female
  names.male = prepareNames names.male

buildName = (cb) ->
  # family name
  rand = Math.random()
  name = _.findKey names.family, (value) -> value > rand
  # title
  title = if Math.random() < 0.5 then "Frau" else "Herr"
  # first name
  rand = Math.random()
  if title is "Frau"
    firstName = _.findKey names.female, (value) -> value > rand
  else
    firstName = _.findKey names.male, (value) -> value > rand
  # result
  cb null, title, name, firstName

# Generate.createSomeNames = ->
#   async.times 20, (n, cb) ->
#     getName (result...) -> cb null, result
#   , (err, results) -> console.log results

#––– generate customers ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

createOneCustomer = (id, cb) ->
  buildName (err, title, name, firstName) ->
    city = 'Musterstadt'
    postalCode = '00000'
    state = 'mitteldeutschland'
    country = 'Deutschland'
    cb null, [id, title, name, firstName, city, postalCode, state, country]

createSomeCustomers = (count, cb) ->
  bar = new ProgressBar ':bar :current users (:etas)', complete: '▓', incomplete: '░', total: count
  async.times count, (n, next) ->
    bar.tick 1
    createOneCustomer n, next
  , (err, customers) ->
    cb err, customers

Generate.customers = (cb) ->
  createSomeCustomers config.customers.count, (err, customers) ->
    return cb err if err
    Database.addCustomers customers, cb

