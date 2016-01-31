#!/usr/bin/env coffee

### libraries ###
fs = require "fs"
_ = require "underscore"
sugar = require "sugar"
progress = require "progress"

### modules ###
Csv = require "./modules/csv"

### database ###
data = new Array()


#––– main ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

Csv.readFile path:"data/input/DE.tab", seperator:'\t', (err, result) ->
  data = result
  # source: http://www.fa-technik.adfc.de/code/opengeodb/DE.tab
  # description: http://opengeodb.giswiki.org/wiki/OpenGeoDB_-_Dateninhalt
  # selectColumns "level", "typ", "#loc_id", "of", "ags", "invalid", "ascii", "name", "amt", "kz", "lat", "lon", "einwohner", "flaeche", "vorwahl", "plz"
  selectColumns "level", "typ", "invalid", "#loc_id":"id", "of":"parent", "ags":"AmtGemeindeschlüssel", "name", "state", "lat", "lon", "einwohner", "plz"

  # remove unrelevant rows
  remove level: (level) -> level > 6

  # remove unconnected entries and inherit state
  remove level: '', parent: ''
  remove invalid: '1'
  filterParentless()
  filterParentless()
  setState()

  # selection
  remove plz:'', lat:'', lon:'', einwohner:''

  # projection (select)
  keep level: 6
  keep einwohner: (item) -> item >= 1000

  # correction
  repairCells()
  splitPlz()

  # write
  selectColumns 'AmtGemeindeschlüssel':'LocationID', 'name':'City', 'state':'State', 'lat':'Latitude', 'lon':'Longitude', 'plz':'PostalCode', 'einwohner':'Population'
  Csv.writeFile data, path:'data/input/de.csv', align:true, seperator:'; '


#––– helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

selectColumns = (columns...) ->
  # renaming
  renamings = _.filter columns, (column) -> _.isObject column
  renamings = _.extend {}, renamings...
  data = _.map data, (row) ->
    for key1, key2 of renamings
      row[key2] = row[key1]
      delete row[key1]
    row

  # projection (select)
  columns = _.flatten _.map columns, (column) -> if _.isObject column then _.values column else column
  data = _.map data, (row) ->
    tmp = {}
    for column in columns
      tmp[column] = row[column] or ''
    tmp

keep = (options) -> filter true, options

remove = (options) -> filter false, options

filter = (matched, options) ->
  data = _.filter data, (row, index) ->
    for key, predicates of options
      item = row[key]
      predicates = [predicates] unless _.isArray predicates
      for pred in predicates
        return matched if (_.isString(pred) or _.isNumber(pred)) and item.toString() is pred.toString()
        return matched if _.isRegExp(pred) and item.match pred
        return matched if _.isFunction(pred) and pred( item )
    return not matched

filterParentless = ->
  index = []
  index[row.id] = row for row in data
  data = _.filter data, (row) -> row.level is '3' or index[row.parent]?

setState = ->
  index = []
  index[row.id] = row for row in data
  # init state
  states = _.filter data, (row) -> row.level is '3'
  _.each states, (state) -> state.state = state.name
  # TODO -> write states into other rows
  for row in data
    tmp = row
    tmp = index[tmp.parent] while tmp.level isnt '3'
    row.state = tmp.state

repairCells = ->
  for row in data
    for key, value of row
      value = value.replace /,$/, ''
      row[key] = value

splitPlz = ->
  for row in data
    row.plz = row.plz.split ','
    row.plz = row.plz.map (plz) -> '"' + plz + '"'


#––– IO ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# writeFile = (path) ->
#   if path.match /\.json$/i
#     lengthes = getLengthes data
#     out = _.map data, (row) ->
#       row = _.map row, (item, i) ->
#         ('\"' + item + '\", ').padRight(lengthes[i] + 4)
#       row = row.join('').trimRight().slice(0,-1)
#       row = "  [#{row}]"
#       row
#     out = out.join ',\n'
#     out = "[\n#{out}\n]"
#     fs.writeFile path, out
#   if path.match /\.csv$/i
#     Csv.writeFile data, path:path, align:true, seperator:'; '

# getLengthes = ->
#   lengthes = _.map data, (row) ->
#     _.mapObject row, (item) -> item?.length or 0
#   lengthesHead = _.mapObject data[0], (v, key) -> key.length
#   lengthes = _.reduce lengthes, (memo, row) ->
#     _.mapObject memo, (val, key) -> _.max [ val, row[key] ]
#   , lengthesHead
#   lengthes
