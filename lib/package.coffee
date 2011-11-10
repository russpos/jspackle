_    = require 'underscore'
yaml = require 'pyyaml'
fs     = require 'fs'
coffee = require 'coffee-script'
readDir = require './readdir'
exec    = require('child_process').exec
logging = require './logging'

defaults =
  depends: []
  test_depends: []
  sources: []
  depends_folder: 'requires'
  test_build_source_file: 'auto-source.js'
  test_build_test_file: 'auto-test.js'
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
    path = opts.root+opts.path
    logging.debug "Parsing jspackle file: #{path}"
    JSON.parse fs.readFileSync path

  test: ->
    try
      @_createJsTestDriverFile (err)=>
        throw err if err
        @_executeTests (code)=>
          throw err if err
          @_clean()
          if code
            logging.critical 'An error occurred while running tests'
          process.exit code
    catch e
      logging.warn e
      process.exit 1

  _executeTests: (callback)->
    logging.debug "Executing tests: #{@_testCmd()}"
    exec @_testCmd(), (err, stdout, stderr)->
      msg =  """

Output:

#{stdout}
"""
      if err
        logging.warn msg
        code = err.code
      else
        logging.info msg
        code = 0
      callback code

  _clean: ->
    fs.unlink "#{@opts.root}JsTestDriver.conf"
    fs.unlink @opts.test_build_source_file
    fs.unlink @opts.test_build_test_file

  _createJsTestDriverFile: (callback)->
    configs =
      server: @opts.test_server
      timeout: @opts.test_timeout

    configs.load = @depends().concat(@testDepends()).concat(@sources())
    configs.test = @tests()

    logging.info "Executing #{configs.test.length} specs"

    path = "#{@opts.root}JsTestDriver.conf"
    logging.debug "Dumping configs to: #{path}"
    yaml.dump configs, path, callback

  _coffeeCompile: (sources, path)->
    logging.info "Compiling coffee-script to '#{path}'"
    compiled = []
    paths = []
    for src in sources
      if @_isHTTP src
        paths.push src
      else
        compiled.push coffee.compile fs.readFileSync(src).toString()
    fs.writeFileSync path, compiled.join "\n"
    paths.push path
    return paths

  depends: ->
    @_process 'depends', @opts.depends_folder

  testDepends: ->
    @_process 'test_depends', @opts.depends_folder

  sources: ->
    sources = @_process 'sources', @opts.source_folder, @opts.test_build_source_file

  tests: ->
    tests = @_process @_findTests(), @opts.spec_folder, @opts.test_build_test_file

  _testCmd: ->
    "js-test-driver --config ./JsTestDriver.conf --tests all #{@opts.test_args}"

  _findTests: ->
    found = readDir @opts.root+@opts.spec_folder
    tests = []
    for file in found.files
      if @_isScript file
        logging.debug "Discovered test: '#{file}'"
        tests.push(file.replace(@opts.root+@opts.spec_folder+'/', ''))
    tests

  _process: (option, folder, compile=false)->
    root = folder+'/'
    sources = []
    if typeof option == 'string'
      paths = @opts[option]
    else
      paths = option

    for path in paths
      if @_isHTTP path
        sources.push path
      else
        sources.push root+path
    return sources if not (compile and @opts.coffee)
    @_coffeeCompile sources, compile

  _isHTTP: (path)->
    path.substring(0, 7) == 'http://' or path.substring(0, 8) == 'https://'

  _isScript: (file)->
    file.substring(file.length-2) is 'js' or file.substring(file.length-6) is 'coffee'


module.exports = Package
