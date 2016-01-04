OrderDetails = module.exports

### libraries ###
sqlite3 = require("sqlite3").verbose()

### database ###
file = "sales.db"
db = new sqlite3.Database file


#––– table handling ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

OrderDetails.createTable = (cb) ->
  db.run """
    CREATE TABLE IF NOT EXISTS OrderDetails (
      OrderDetailsID INTEGER PRIMARY KEY AUTOINCREMENT,
      OrderID INTEGER,
      ProductID INTEGER,
      Quantity INTEGER,
      UnitPrice DECIMAL(5,2),
      Discount REAL DEFAULT 0
    ) """, cb

OrderDetails.closeDatabase = (cb) ->
  db.close cb


#––– crud ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
