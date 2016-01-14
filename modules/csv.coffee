csv = module.exports

### libraries ###
fs = require 'fs'
_ = require 'underscore'


#––– read ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# cb = (err, data-array) ->
csv.readFile = (opts, cb) ->
  opts.path ?= process.env.PWD
  opts.encoding ?= 'utf8'
  opts.seperator ?= ';'

  fs.readFile opts.path, opts.encoding, (err, data) ->
    cb err if err
    table = data.split /[\r\n]+/
    table = for row in table when row.length > 0
      row = row.split opts.seperator # TODO: matching does not yet ignore escaped seperators or seperators inside strings
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
csv.writeFile = (data, opts, cb) ->
  # set defaults
  opts.path ?= process.env.PWD
  opts.encoding ?= 'utf8'
  opts.seperator ?= ';'
  opts.splitDate ?= false

  # prepare
  keys = getColumns data

  # write head
  tmp = _.map keys, (key) -> "\"#{key}\""
  string = tmp.join(opts.seperator) + '\n'
  string = string.replace /([^\"]*Date[^\"]*)/i, "$1_D\"#{opts.seperator}\"$1_M\"#{opts.seperator}\"$1_Y" if opts.splitDate

  console.log opts

  # write content
  for row in data
    tmp = _.map keys, (key) ->
      value = row[key]
      return null unless value?
      return "#{value}" if _.isNumber value or _.isString value and value.match /\d+\.?\d*/
      return value.format "{d}#{opts.seperator}{M}#{opts.seperator}{yyyy}" if _.isDate(value) and opts.splitDate
      return value.format "{d}.{M}.{yyyy}" if _.isDate value
      return "\"#{value}\""
    string += tmp.join(opts.seperator) + '\n'
  fs.writeFile opts.path, string, opts.encoding, cb
