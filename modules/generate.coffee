Generate = module.exports

### libraries ###
_ = require "underscore"
async = require "async"

### modules ###
Customers = require "./database/customers"

### configs ###
config =
  buy: require "../config/buy.json"
  customers: require "../config/customers.json"
  products: require "../config/products.json"


#––– generate customers ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

createOneCustomer = (id, cb) ->
  name = 'Mustermann'
  firstName = 'Max'
  city = 'Musterstadt'
  postalCode = '00000'
  state = 'mitteldeutschland'
  country = 'deutschland'
  cb null, [id, name, firstName, city, postalCode, state, country]

createSomeCustomers = (count, cb) ->
  async.times count, (n, next) ->
    createOneCustomer n, next
  , (err, customers) ->
    cb err, customers

Generate.customers = (cb) ->
  createSomeCustomers config.customers.count, (err, customers) ->
    return cb err if err
    Customers.create customers, cb

