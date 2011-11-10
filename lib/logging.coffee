term = require('./colors').colors
nullColors = {}

for curColor in ['cyan', 'green', 'yellow', 'red']
  nullColors[curColor] = (msg)-> msg

# Toggle-able options
clean = false
colors = term
level = 2

levels =
  debug: 1
  info: 2
  warn: 3
  critical: 4

debug = (msg)->
  log colors.cyan("debug  ", true), msg, 1

info = (msg)->
  log colors.green("info   ", true), msg, 2

warn = (msg)->
  log colors.yellow("WARN   ", true), msg, 3

critical = (msg)->
  log colors.red("ERROR!!", true), msg, 4

log = (desc, msg, logLevel)->
  return if logLevel < level
  lines = msg.split "\n"
  for line in lines
    if clean
      console.log line
    else
      console.log " % #{desc} | #{line}"

module.exports =
  debug: debug
  info: info
  warn: warn
  critical: critical

  setClean: (toggle)->
    clean = toggle

  setColor: (toggle)->
    if toggle
      colors = term
    else
      colors = nullColors
      debug "Color output disabled"

  setLevel: (lvl)->
    level = levels[lvl]
