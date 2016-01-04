Customers = module.exports

### libraries ###
async = require "async"
sqlite3 = require("sqlite3").verbose()

### database ###
file = "sales.db"
db = new sqlite3.Database file


#––– table handling ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Customers.createTable = (cb) ->
  db.run """
    CREATE TABLE IF NOT EXISTS Customers (
      CustomerID INTEGER PRIMARY KEY,
      Name VARCHAR(50),
      FirstName VARCHAR(50),
      City VARCHAR(50),
      PostalCode VARCHAR(5),
      State VARCHAR(25),
      Country VARCHAR(25)
    ) """, cb

Customers.closeDatabase = (cb) ->
  db.close cb


#––– crud ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# data = [[…],[…],…]
# cb = (err) ->
Customers.create = (data, cb) ->
  stmt = db.prepare "INSERT INTO Customers VALUES (?, ?, ?, ?, ?, ?, ?)"
  async.each data, (row, cb) ->
    stmt.run row, (err) -> cb err
  , cb

# cb = (err, data) ->
Customers.all = (cb) ->
  db.all "SELECT * FROM Customers ORDER BY CustomerID", cb

# cb = (err, data) ->
Customers.allExport = (cb) ->
  db.all "SELECT CustomerID, Name, FirstName, City, PostalCode, State, Country FROM Customers ORDER BY CustomerID", cb
