program = require 'commander'

Package = require './package'
program.name = 'jspackle'

program
  .version('1.0.0')
  .option('-c, --coffee', 'Look for and compile coffee-script files')
  .option('-r, --root <root>', 'The of the project', process.cwd()+'/')
  .option('-p, --path <path>', 'Path of the config file, relative to root', 'jspackle.json')
  .option('-s, --test_server <test_server>', 'Test server', 'http://localhost:9876')
  .option('-t, --test_timeout <test_timeout>', 'Test timeout (in seconds)', 90)
  .option('-a, --test_args <test_args>', 'Additional args to pass to the underlying tester', '')

test = program
  .command('test')
  .description('Execute tests')
  .action (env)->
    p = new Package program, test
    p.test()


program.parse process.argv
