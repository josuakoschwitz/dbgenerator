#!/usr/bin/env coffee

_ = require "underscore"
sugar = require "sugar"
fs = require "fs"
progress = require "progress"

Csv = require "./modules/csv"



#––– database ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

data = new Array()
cell = (row, key) -> row[ data[0].indexOf key ]


#––– run –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Csv.readFile path:"data/geodata/DE.tab", seperator:/\t/, (err, result) ->
  data = result

  # select …
  # selectColumns "level", "typ", "#loc_id", "of", "ags", "invalid", "ascii", "name", "amt", "kz", "lat", "lon", "einwohner", "flaeche", "vorwahl", "plz"
  selectColumns "level", "typ", "#loc_id", "of", "invalid", "name", "lat", "lon", "einwohner", "plz"

  # where …
  filter plz: /^.+$/
  filter lat: /^.+$/
  filter lon: /^.+$/
  filter einwohner: /^.+$/
  filter einwohner: (item) -> item > 200000
  filter level: "6"
  # filter level: /^[8-9]$/
  # filter typ: "Verwaltungsgemeinschaft", '#loc_id': "290"
  # validateParent()

  writeFile data, 'data/geodata/de.json'

  # write back
  selectColumns "name", "lat", "lon", "einwohner", "plz"
  writeFile data, 'data/geodata/example2.json' # set example to not overwrite example.json


#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

selectColumns = (columns...) ->
  head = data[0]
  mapping = _.map columns, (column) -> head.indexOf column
  data = _.map data, (row) -> _.map mapping, (column) -> row[column]

filter = (options) ->
  data = _.filter data, (row, index) ->
    return true if index is 0
    tmp = _.map options, (predicate, key) ->
      item = cell(row, key)
      return item.match predicate if _.isRegExp predicate
      return item is predicate if _.isString predicate
      return predicate( item ) if _.isFunction predicate
    return _.reduce tmp, (prev, curr) -> prev or curr

validateParent = ->
  # indices of columns
  iLoc = data[0].indexOf '#loc_id'
  iLevel = data[0].indexOf 'level'
  iOf = data[0].indexOf 'of'

  # available ids
  tmp = data
    .slice(1) # rm header
    .map (row,id) -> [ Number(row[iLoc]), id+1, Number(row[iLevel])]
    .sort (i,j) -> i[0] > j[0]
  locIds =
    id: _.map tmp, (value) -> value[0]
    index: _.map tmp, (value) -> value[1]
    level: _.map tmp, (value) -> value[2]

  # apply filtering
  # bar = new progress 'validate parent ║:bar║', complete: '▓', incomplete: '░', total: data.length
  data = data.filter (row, i) ->
    # bar.tick 1
    return true if i is 0
    ofid = Number(row[iOf])
    level = Number(row[iLevel])
    found = ofid in locIds.id
    # console.log " of: #{ofid} not found (Level #{level})" unless found
    return found


writeFile = (arr, path) ->
  lengthes = getLengthes arr
  if path.match /\.json$/i
    out = _.map arr, (row) ->
      row = _.map row, (item, i) ->
        ('\"' + item + '\", ').padRight(lengthes[i] + 4)
      row = row.join('').trimRight().slice(0,-1)
      row = "  [#{row}]"
      row
    out = out.join ',\n'
    out = "[\n#{out}\n]"
  # else if path.match /\.csv$/i
  #   out = _.map arr, (row) ->
  #     row = _.map row, (item, i) ->
  #       ('\"' + item + '\"; ').padRight(lengthes[i] + 4) if _.isString item
  #       ('\"' + item + '\"; ').padRight(lengthes[i] + 4) if _.isArray item
  #     row.join('').trimRight().slice(0,-1)
  #   out = out.join '\n'
  else return
  fs.writeFile path, out

getLengthes = (arr) ->
  lengthes = _.map arr, (row) ->
    item?.length or 0 for item in row
  lengthes = _.reduce lengthes, (memo, row) ->
    _.max([ memo[index], row[index] ]) for item, index in row
  lengthes
