Database = module.exports

### libraries ###
fs = require "fs"


Database.clear = (cb) ->
  fs.truncate "sales.db", 0, cb

Database.init = (cb) ->
  cb null
Database.close = (cb) ->
  cb null
