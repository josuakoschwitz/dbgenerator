Products = module.exports

### libraries ###
async = require "async"
sqlite3 = require("sqlite3").verbose()

### database ###
file = "sales.db"
db = new sqlite3.Database file


#––– table handling ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Products.createTable = (cb) ->
  db.run """
    CREATE TABLE IF NOT EXISTS Products (
      ProductID INTEGER PRIMARY KEY,
      CategoryID INTEGER,
      SubCategoryID INTEGER,
      BrandID INTEGER,
      ProductName VARCHAR(50),
      UnitPrice DECIMAL(5,2)
    ) """, cb

Products.closeDatabase = (cb) ->
  db.close cb


#––– crud ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# data = [[…],[…],…]
# cb = (err) ->
Products.create = (data, cb) ->
  stmt = db.prepare "INSERT INTO Products VALUES (?, ?, ?, ?, ?, ?)"
  async.each data, (row, cb) ->
    stmt.run row, cb
  , cb

