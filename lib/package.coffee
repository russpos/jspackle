_    = require 'underscore'
yaml = require 'pyyaml'
fs   = require 'fs'
readDir = require './readdir'
exec    = require('child_process').exec

defaults =
  depends_folder: 'requires'
  spec_folder: 'specs'
  source_folder: 'src'

class Package

  constructor: (opts={}, cmd)->
    configs = @loadConfigs opts
    @opts = []
    # Extend objects in reverse precedence, objects will over-write previously
    # set properties, giving the last item the highest precedence.
    #  1. Default settings
    #  2. Config file settings
    #  3. Commandline options
    #  4. Command specific command-line options
    _.extend @opts, defaults, configs, opts, cmd

  loadConfigs: (opts)->
    JSON.parse fs.readFileSync opts.root+opts.path

  test: ->
    @_createJsTestDriverFile (err)=>
      throw err if err
      @_executeTests (code)=>
        throw err if err
        process.exit code

  _executeTests: (callback)->
    console.log @_testCmd()
    exec @_testCmd(), (err, stdout, stderr)->
      console.log stdout
      console.log stderr
      if err
        code = err.code
      else
        code = 0
      callback code

  _createJsTestDriverFile: (callback)->
    configs =
      server: @opts.test_server
      timeout: @opts.test_timeout

    configs.load = @depends().concat(@testDepends()).concat(@sources())
    configs.test = @tests()
    yaml.dump configs, @opts.root+'JsTestDriver.conf', callback

  depends: ->
    @_process 'depends', @opts.depends_folder

  testDepends: ->
    @_process 'test_depends', @opts.depends_folder

  sources: ->
    if @opts.coffee
      throw "CoffeScript not yet supported!"

    @_process 'sources', @opts.source_folder

  tests: ->
    @_process @_findTests(), @opts.spec_folder

  _testCmd: ->
    "js-test-driver --config ./JsTestDriver.conf --tests all #{@opts.test_args}"

  _findTests: ->
    found = readDir @opts.root+@opts.spec_folder
    tests = []
    for file in found.files
      if file.substring(file.length-2) is 'js'
        tests.push(file.replace(@opts.root+@opts.spec_folder+'/', ''))
    tests

  _process: (option, folder)->
    root = folder+'/'
    sources = []
    if typeof option == 'string'
      paths = @opts[option]
    else
      paths = option

    for path in paths
      if path.substring(0, 7) == 'http://' or path.substring(0, 8) == 'https://'
        sources.push path
      else
        sources.push root+path
    sources


module.exports = Package
