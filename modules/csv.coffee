csv = module.exports

### libraries ###
fs = require 'fs'
_ = require 'underscore'


#––– csv io ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# cb = (err, data-array) ->
csv.readFile = (path, encoding, cb) ->
  fs.readFile path, encoding, (err, data) ->
    cb err if err
    table = data.split /[\r\n]+/
    table = for row in table when row.length > 0
      row = row.split ';'
      row = for item, i in row
        item = item
          .replace /^"(.+)"$/, '$1'
          .replace /""/g, '"'
          .replace /,(\d\d) €/, '.$1'
          .trim()
    cb null, table

# cb = (err) ->
csv.writeFile = (path, data, encoding, cb) ->
  # write head
  tmp = _.map data[0], (v, k) -> "\"#{k}\""
  string = tmp.join(';') + '\n'
  # write content
  for row in data
    tmp = _.map row, (v, k) ->
      return "#{v}" if _.isNumber v
      return "#{v}" if v.match /\d\d\.\d\d\.\d\d\d\d\./
      return "\"#{v}\""
    string += tmp.join(';') + '\n'
  fs.writeFile path, string, encoding, cb
