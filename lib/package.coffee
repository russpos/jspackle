_       = require 'underscore'
logging = require './logging'
pathLib = require 'path'

String::isHTTP = ->
  @substring(0, 7) == 'http://' or @substring(0, 8) == 'https://'

String::isCoffee = -> pathLib.extname(pathLib.basename(@))  == '.coffee'
String::isJs = -> pathLib.extname(pathLib.basename(@))  == '.js'

String::isScript = -> @isCoffee or @isJs

###
Load any methods or libraries that interact with the outside
  system.  In the tests, these should all be mocked out via stubble
###
coffee =  require 'coffee-script'
exec =    require('child_process').exec
flow =    require 'flow'
fs =      require 'node-fs'
restler = require 'restler'
readDir = require './readdir'
uglify =  require 'uglify-js'
yaml =    require 'pyyaml'


# Default configs values
defaults =
  depends: []
  test_depends: []
  sources: []
  minify: false
  include_depends: false
  depends_folder: 'requires'
  test_build_folder: 'build'
  spec_folder: 'specs'
  source_folder: 'src'
  build_output: 'output.js'

###
@description Represents an instance of a Package, which is the basic
  unit in Jspackle.  All tasks are executed against a single package.
  Provides public methods to execute the basic tasks that Jspackle
  allows on itself.

@name Package
@class
###
class Package

  exitCode: 0

  exit:    (code)->
    @exitCode = code

  ###
  ###
  complete: ->
    process.nextTick =>
      process.exit @exitCode

  ###
  @description Use the settings provided in ``opts`` (command line options
    for the entire Jspackle process) as well as the settings in ``cmd``
    (command line options specific for the sub-command that is going to be
    executed to define the ``@opts`` for this Package instance.

    Extend objects in reverse precedence:  overwrite previously set
    properties, giving the last item the highest precedence.

      1. Default settings                      (Lowest precedence)
      2. Config file settings
      3. Commandline options
      4. Command specific command-line options (Highest precedence)

  @param   {Object} opts Commandline options for jspackle
  @param   {Object} cmd  Commandline options specific to jspackle subcommand
  @returns {void}

  @public
  @function
  @constructor
  @memberOf Package.prototype
  ###
  constructor: (opts={}, cmd={})->
    configs = @loadConfigs opts
    @opts = []
    _.extend @opts, defaults, configs, opts, cmd


  ###
  @description Using the base options provided to Jspackle, load the
    Jspackle config file that defines this package.

  @param   {Object} opts Commandline options for jspackle
  @returns {Object} Config files parsed from the JSON config-file

  @public
  @function
  @memberOf Package.prototype
  ###
  loadConfigs: (opts)->
    path = opts.root+opts.path
    logging.debug "Parsing jspackle file: #{path}"
    try
      JSON.parse fs.readFileSync path
    catch e
      @error "ERROR opening config file '#{path}'"

  ###
  @description Defines the standard behavior of when an error is
    encountered. Logs the error and ends the process with an error
    code.

  @param {mixed} e Error.  Regardless of type, it is passed to the
    logging module where it co-erced to a string.
  @param {integer} code Error code to exit this process with. Defaults
    to 1 (standard error).
  @returns {void}

  @public
  @function
  @memberOf Package.prototype
  ###
  error: (e, code=1)->
    logging.warn e
    @exit code

  build: ->
    _this = this
    sources = []

    # Asyncronously read sources into memory and cache them
    # the sources object.  Register it as an async multi-step
    # flow command
    loadSources = ->
      flow = this
      sources = []
      if _this.opts.include_depends
        sources = sources.concat _this.depends
      sources = sources.concat _this.sources
      for index, src of sources

        # Execute in a closure so that i is local to this
        # loop, so that it doesn't change by the time our
        # callback is executed.
        do ->
          i = index
          registered = flow.MULTI()

          if src.isHTTP()
            _this.httpGet src, (script)->
              sources[i] = script
              registered()

          else

            # Read the file, cache the source, and mark this portion of
            # the multi-step as complete
            fs.readFile _this.opts.root+src, (err, script)->
              return _this.error err if err
              sources[i] = script
              registered()


    # Once all our registered multi-steps have completed, join
    # the ordered sources with new lines and write the output
    # to our build file.
    processSources = ->
      outputFile = _this._generateOutputPath()
      logging.info "Found #{sources.length} source file"
      logging.info "Writing processed sources to: '#{outputFile}'"
      output = sources.join "\n"
      if _this.opts.minify
        output = _this.minify output
      fs.writeFile outputFile, output, this

    # End the program, returning the correct error code based on if
    # writing finished or not.
    finish = (err)->
      _this.exit if err then 1 else 0

    complete = ->
      _this.complete()

    flow.exec loadSources, processSources, finish, complete

  ###
  @description The ``test`` task.  Create test config file, execute
    tests, and clean up after itself.

  @returns {void}

  @public
  @function
  @memberOf Package.prototype
  ###
  test: ->
    cancel = false
    _this = this

    # Create the test driver conf file
    createFile = ->
      _this._createJsTestDriverFile this

    # Execute tests
    execute = (err)->
      cancel = err
      if cancel
        _this.exit 1
        return this()
      _this._executeTests this

    # Clean up files that were created along the way
    clean = (err)->
      flow = this
      cancel = cancel or err
      _this.clean flow
      _this.exit if cancel then (parseInt(cancel, 10) or 1) else 0

    complete = ->
      _this.complete()

    flow.exec createFile, execute, clean, complete

  ###
  @description Cleans up after a task.  Unlinks any temporary files that
    were created as part of its process.

  @returns {void}

  @public
  @function
  @memberOf Package.prototype
  ###
  clean: (flow)->
    logging.info "Cleaning up after jspackle run..."
    fs.unlink "#{@opts.root}JsTestDriver.conf", flow.MULTI()
    exec "rm -rf #{@opts.test_build_folder}", (err, stdout, stderr) ->
      if err
        logging.warn stderr
      flow.MULTI()

  ###
  @description Minifies the source provided to it.

  @params  {String} source JavaScript source to be minified
  @returns {String} Minified JavaScript source

  @public
  @function
  @memberOf Package.prototype
  ###
  minify: (source)->
    logging.info "Minifying JavaScript source..."
    tokens = uglify.parser.parse source
    tokens = uglify.uglify.ast_mangle tokens
    tokens = uglify.uglify.ast_squeeze tokens
    uglify.uglify.gen_code tokens

  ###
  @description Gets the given URL, and passes the response to
  the callback function. If an error occurs, the process exits
  with code 1

  @params {String} url URL of the get request
  @params {Function} callback Callback function to be executed on
    complete

  @public
  @function
  @memberOf Package.prototype
  ###
  httpGet: (url, callback)->
    resp = restler.get url
    resp.on 'complete', callback
    resp.on 'error', => @error "ERROR: Cannot get #{url}"

  ### ------ Private Methods ------- ###

  _executeTests: (callback)->
    logging.debug "Executing tests: #{@testCmd}"
    exec @testCmd, (err, stdout, stderr)->
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

  _createJsTestDriverFile: (callback)->
    configs =
      server: @opts.test_server
      timeout: @opts.test_timeout

    configs.load = @depends.concat(@testDepends).concat(@sources)
    configs.test = @tests

    if @opts.coverage
      configs.plugin = [
        name: "coverage"
        jar: @opts.coverage
        module: "com.google.jstestdriver.coverage.CoverageModule"
      ]

    logging.info "Executing #{configs.test.length} specs"

    path = "#{@opts.root}JsTestDriver.conf"
    logging.debug "Dumping configs to: #{path}"
    yaml.dump configs, path, callback

  _coffeeCompile: (src, buildFolder)->
    # Compiles a coffeescript file and writes it to buildFolder
    try
      compiled = coffee.compile fs.readFileSync(src).toString()
    catch e
      logging.critical "Cannot parse #{src} as valid CoffeeScript!"
      logging.critical e
      throw e

    fileName = pathLib.join buildFolder, src.replace('.coffee', '.js')
    filePath = pathLib.join buildFolder, pathLib.dirname src

    fs.mkdirSync filePath, 0777, true
    logging.info "Compiling #{src} to '#{fileName}'"
    fs.writeFileSync fileName, compiled
    return fileName

  _findTests: ->
    found = readDir @opts.root+@opts.spec_folder
    tests = []
    for file in found.files
      if file.isScript()
        logging.debug "Discovered test: '#{file}'"
        tests.push(file.replace(@opts.root+@opts.spec_folder+'/', ''))
    tests

  ###
  Generate the output path from our options, and template variables
  ###
  _generateOutputPath: ->
    filePath = pathLib.join @opts.root, @opts.build_output
    for variable in ['name', 'version']
      re = new RegExp "{{#{variable}}}", 'g'
      filePath = filePath.replace re, @opts[variable]
    return filePath

  _process: (option, folder, buildFolder=@opts.test_build_folder)->
    root = folder+'/'
    sources = []
    if typeof option == 'string'
      srcPaths = @opts[option]
    else
      srcPaths = option

    for source in srcPaths
      if source.isHTTP()
        if source.isJs()
          sources.push source
        else
          logging.warn "Cannot include coffee script HTTP resources!"
      else if source.isJs()
          sources.push root+source
      else if source.isCoffee()
        sources.push @_coffeeCompile root+source, buildFolder
      else
        logging.warn "Ignoring unkonown file type #{source}"
    return sources

###
Read only properties
--------------------

Defines read-only properties on the Package object using  v8's
``__defineGetter__`` syntax.  These properties expand arguments that
are provided as part of the configuration into fleshed out properties.
###
Package.prototype.__defineGetter__ 'sources', ->
  @_process 'sources', @opts.source_folder, @opts.test_build_folder

Package.prototype.__defineGetter__ 'depends', ->
  @_process 'depends', @opts.depends_folder

Package.prototype.__defineGetter__ 'testDepends', ->
  @_process 'test_depends', @opts.depends_folder

Package.prototype.__defineGetter__ 'tests', ->
  @_process @_findTests(), @opts.spec_folder, @opts.test_build_folder

Package.prototype.__defineGetter__ 'testCmd', ->
  "js-test-driver --config ./JsTestDriver.conf --tests all --reset #{@opts.test_args}"

module.exports = Package
