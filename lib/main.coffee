program = require 'commander'
logging = require './logging'
fs      = require 'fs'

Package = require './package'
program.name = 'jspackle'

version = JSON.parse(fs.readFileSync(__dirname+'/../package.json')).version

console.log "jspackle v#{version}\n"

task = ->
  console.log """No valid command provided!:
jspackle (build|test)
"""


program
  .version(version)
  .option('-v, --verbose', 'Include debugging information in the output')
  .option('-q, --quiet', 'Only print critical errors to the screen')
  .option('-n, --no-color', 'Disable colors in the output')
  .option('-c, --coffee', 'Look for and compile coffee-script files')
  .option('-r, --root <root>', 'The of the project', process.cwd()+'/')
  .option('-p, --path <path>', 'Path of the config file, relative to root', 'jspackle.json')
  .option('-s, --test_server <test_server>', 'Test server', 'http://localhost:9876')
  .option('-t, --test_timeout <test_timeout>', 'Test timeout (in seconds)', 90)
  .option('-a, --test_args <test_args>', 'Additional args to pass to the underlying tester', '')
  .option('-o, --build_output <build_output>', 'File to write built project')

test = program
  .command('test')
  .description('  - Execute tests')
  .action (env)->
    task = ->
      logging.info "Executing command: 'test'"
      p = new Package program, test
      p.test()

build = program
  .command('build')
  .description(' - Build output file')
  .action (env)->
    task = ->
      logging.info "Executing command: 'build'"
      p = new Package program, build
      p.build()


program.parse process.argv
logging.setColor program.color
if program.verbose
  logging.setLevel 'debug'

if program.quiet
  logging.setClean true
  logging.setLevel 'critical'

task()
