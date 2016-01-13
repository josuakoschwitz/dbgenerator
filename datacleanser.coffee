#!/usr/bin/env coffee

_ = require "underscore"
sugar = require "sugar"
fs = require "fs"


#––– step 1 ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Csv = require "./modules/csv"
Csv.readFile "input/geodata/DE.tab", 'utf8', /\t/, (err, data) ->
  data = selectColumns data, "level", "typ", "#loc_id", "of", "ags", "invalid", "ascii", "name", "amt", "kz", "lat", "lon", "einwohner", "flaeche", "vorwahl", "plz"
  validateOrder data

  writeFile 'input/geodata/DE.json', data, true


#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

selectColumns = (data, columns...) ->
  head = data[0]
  mapping = _.map columns, (column) -> head.indexOf column
  _.map data, (row) ->
    _.map mapping, (column) -> row[column]

validateOrder = (data) ->
  logcol_level = data[0].indexOf "level"
  col_id = data[0].indexOf "#loc_id"
  col_of = data[0].indexOf "of"
  # TODO
  # ...
  # ...
  # ...

writeFile = (path, data, align = true) ->
  lengthes = getLengthes data if align
  data = _.map data, (row) ->
    row = _.map row, (item, i) ->
      tmp = ('\"' + item + '\", ')
      tmp = tmp.padRight(lengthes[i]+4) if align
      tmp
    row = row.join('').trimRight().slice(0,-1)
    row = "  [#{row}]"
    row
  data = data.join ',\n'
  data = "[\n#{data}\n]"
  fs.writeFile path, data

getLengthes = (data) ->
  lengthes = _.map data, (row) ->
    item?.length or 0 for item in row
  lengthes = _.reduce lengthes, (memo, row) ->
    _.max([ memo[index], row[index] ]) for item, index in row
  lengthes
