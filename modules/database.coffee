Database = module.exports

### libraries ###
_ = require "underscore"

### modules ###
Csv = require "./csv"

### private variables ###
products = new Array()
customers = new Array()


#––– Products –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# ProductID INTEGER PRIMARY KEY,
# CategoryID INTEGER,
# SubCategoryID INTEGER,
# BrandID INTEGER,
# ProductName VARCHAR(50),
# UnitPrice DECIMAL(5,2)

Database.ProductsCount = (cb) ->
  console.log products.length

Database.ProductsFromCsv = (path, cb) ->
  Csv.readFile path, 'utf8', (err, data) ->
    return cb err if err
    products = data
    return cb null

Database.ProductsToCsv = (path, cb) ->
  Csv.writeFile path, products, 'utf8', (err) -> cb err


#––– Customers –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# CustomerID INTEGER PRIMARY KEY,
# Name VARCHAR(50),
# FirstName VARCHAR(50),
# City VARCHAR(50),
# PostalCode VARCHAR(5),
# State VARCHAR(25),
# Country VARCHAR(25)

Database.addCustomers = (data, cb) ->
  customers = data
  cb null

Database.CustomersToCsv = (path, cb) ->
  Csv.writeFile path, customers, 'utf8', (err) -> cb err


#––– Order –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
# CustomerID INTEGER,
# DistributionChannelID INTEGER,
# OrderDate DATE


#––– Order Details –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# OrderDetailsID INTEGER PRIMARY KEY AUTOINCREMENT,
# OrderID INTEGER,
# ProductID INTEGER,
# Quantity INTEGER,
# UnitPrice DECIMAL(5,2),
# Discount REAL DEFAULT 0


#––– Distribution Channel ––––––––––––––––––––––––––––––––––––––––––––––––––––––

# DistributionChannelID INTEGER PRIMARY KEY AUTOINCREMENT,
# DistributionChannelName VARCHAR(50)
