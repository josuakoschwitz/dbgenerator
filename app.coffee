#!/usr/bin/env coffee

### libraries ###
async = require "async"

### modules ###
Generate = require "./modules/generate"
Database = require "./modules/database"


#––– main app ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

async.series [

  # preparing database
  (cb) -> Database.clear cb
  (cb) -> Database.init cb

  ], (err) ->
    console.log err if err
    Database.close

