csv = module.exports

### libraries ###
fs = require 'fs'
_ = require 'underscore'
sugar = require 'sugar'


#––– Helper ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

fs.mkdir 'data/output', (err) ->


#––– read ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# cb = (err, data-array) ->
csv.readFile = (opts, cb) ->
  opts.path ?= process.env.PWD
  opts.encoding ?= 'utf8'
  opts.seperator ?= ';'
  opts.head ?= true

  fs.readFile opts.path, opts.encoding, (err, data) ->
    cb err if err
    table = data.split /[\r\n]+/
    table = for row in table when row.length > 0
      row = row.split new RegExp "#{opts.seperator}(?=(?:[^\"]*\"[^\"]*\")*?[^\"]*$)"
      row = for item, i in row
        item = item
          .replace /^"(.+)"$/, '$1'
          .replace /""/g, '"'
          .replace /,(\d\d) €/, '.$1'
          .trim()
    # head to keys
    if opts.head
      table = table.slice(1).map (row) ->
        tmp = {}
        for item, index in row
          tmp[ table[0][index] ] = item
        return tmp
    cb null, table


#––– write –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

getColumns = (data) ->
  types = _.map data, (row) ->
    row = _.pick data[0], (v, k) -> k[0] isnt "_"
    _.mapObject row, (value, key) ->
      return undefined if not value? or value.length is 0
      return 'Date' if _.isDate(value)
      return 'Enum' if _.isString(value) and value in ["EUR", "ST"]
      return 'Number' if _.isNumber(value) or _.isString(value) and value.match(/^\d+(\.\d+)?$/)
      return 'Array' if _.isArray(value)
      return 'String' # otherwise
  _.reduce types, (memo, row) ->
    columns = _.invert _.union _.keys(memo), _.keys(row)
    _.mapObject columns, (x, key) ->
      # if one is undefined then chose the other one
      unless memo[key] and row[key]
        return memo[key] or row[key]
      # if the types are diffent which is fatal, fall back to string
      else if memo[key] isnt row[key]
        console.error "csv.writeFall must fall back to String for \"#{key}\""
        return 'String'
      # otherwise return the type
      else
        return memo[key]

getLengthes = (data, columns) ->
  lengthes = _.mapObject columns, (val, key) -> key.length + 2
  for row in data
    for column, value of row
      length = 0
      length = value.toString().length if columns[column] in ['Number', 'Enum']
      length = value.toString().length + 2 if columns[column] in ['String', 'Array']
      length = 12 if columns[column] is 'Date'
      lengthes[column] = length if lengthes[column] < length
  lengthes

csv.writeFile = (data, opts, cb) ->
  # set defaults
  opts.path ?= process.env.PWD
  opts.encoding ?= 'utf8'
  opts.seperator ?= ';'
  opts.align ?= false

  # prepare
  columns = getColumns data
  lengthes = getLengthes data, columns if opts.align

  # row = _.map row, (item, i) ->
  #   ('\"' + item + '\", ').padRight(lengthes[i] + 4)
  # row = row.join('').trimRight().slice(0,-1)
  # row = "  [#{row}]"

  # write head
  head = _.map columns, (num, col) ->
    value = "\"#{col}\"" + opts.seperator
    value = value.padRight lengthes?[col] + opts.seperator.length if opts.align
    value
  string = head.join('').trimRight().slice(0,-opts.seperator.trimRight().length) + '\n'

  # write content
  for row in data
    tmp = _.map columns, (type, col) ->
      value = row[col]
      value = switch type
        when undefined then ""
        when 'Number' then value.toString()
        when 'Enum' then value.toString()
        when 'Date' then value.format "{yyyy}-{MM}-{dd}"
        when 'Array' then "[#{value.toString()}]"
        else value.replace '\"', '\"\"';  "\"#{value}\""
      value = value + opts.seperator
      value = value.padRight lengthes?[col] + opts.seperator.length if opts.align
      value
    string += tmp.join('').trimRight().slice(0,-opts.seperator.length) + '\n'
  fs.writeFile opts.path, string, opts.encoding, cb

