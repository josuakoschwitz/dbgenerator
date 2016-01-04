Orders = module.exports

### libraries ###
sqlite3 = require("sqlite3").verbose()

### database ###
file = "sales.db"
db = new sqlite3.Database file


#––– table handling ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Orders.createTable = (cb) ->
  db.run """
    CREATE TABLE IF NOT EXISTS Orders (
      OrderID INTEGER PRIMARY KEY AUTOINCREMENT,
      CustomerID INTEGER,
      DistributionChannelID INTEGER,
      OrderDate DATE
    ) """, cb

Orders.closeDatabase = (cb) ->
  db.close cb


#––– crud ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
