Distribution = module.exports

### libraries ###
sqlite3 = require("sqlite3").verbose()

### database ###
file = "sales.db"
db = new sqlite3.Database file


#––– table handling ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Distribution.createTable = (cb) ->
  db.run """
    CREATE TABLE IF NOT EXISTS DistributionChannels (
      DistributionChannelID INTEGER PRIMARY KEY AUTOINCREMENT,
      DistributionChannelName VARCHAR(50)
    ) """, cb

Distribution.closeDatabase = (cb) ->
  db.close cb


#––– crud ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
