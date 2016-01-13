csv = module.exports

### libraries ###
fs = require 'fs'
_ = require 'underscore'


#––– read ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# cb = (err, data-array) ->
csv.readFile = (path, encoding, seperator, cb) ->
  fs.readFile path, encoding, (err, data) ->
    cb err if err
    table = data.split /[\r\n]+/
    table = for row in table when row.length > 0
      row = row.split seperator # TODO: matching does not yet ignore escaped seperators or seperators inside strings
      row = for item, i in row
        item = item
          .replace /^"(.+)"$/, '$1'
          .replace /""/g, '"'
          .replace /,(\d\d) €/, '.$1'
          .trim()
    cb null, table


#––– write –––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

getColumns = (data) ->
  _.keys _.pick data[0], (v, k) -> k[0] isnt "_"

# cb = (err) ->
csv.writeFile = (path, data, encoding, cb) ->
  # prepare
  keys = getColumns data

  # write head
  tmp = _.map keys, (key) -> "\"#{key}\""
  string = tmp.join(';') + '\n'

  # write content
  for row in data
    tmp = _.map keys, (key) ->
      value = row[key]
      return null unless value?
      return "#{value}" if _.isNumber value
      return value.format "{d}.{M}.{yyyy}" if _.isDate value
      return "\"#{value}\""
    string += tmp.join(';') + '\n'
  fs.writeFile path, string, encoding, cb
