Package = require '../lib/package'
logging = require '../lib/logging'
path    = require 'path'
cs      = require 'coffee-script'
filesys = require 'fs'

test = (file)->
  cs.compile filesys.readFileSync(path.join __dirname, file+'.coffee').toString()

describe 'Package', ->

  ###
  Stub out anything u/o related
  ###
  ast = readDir = coffee = compiled = configs = cmd = flow = minify = opts = exec = uglify = yaml = exit = pack = fs = undefined
  beforeEach ->
    ast = {}
    configs =
      first: 'z'
      third: 'c'
      test_args: " --forceReset"
      depends: ['jquery.js',
                'http://www.example.com/underscore.js',
                'https://myprivate.server.net/my_lib.latest.js']
      test_depends: ['jasmine.js', 'jquery-test-suite.js']
      sources: ['foo.js', 'baz.js', 'bar.js']
      test_server: 'http://localhost:9876'
      test_timeout: 90

    coffee =
      compile: jasmine.createSpy "coffee.compile"

    compiled = {}

    opts =
      root: process.cwd()+'/'
      path: 'jspackle.json'
      first: 'a'
      second: 'b'

    cmd =
      second: 'x'

    uglify =
      parser:
        parse:       jasmine.createSpy "uglify.parser.parse"
      uglify:
        ast_mangle:  jasmine.createSpy "uglify.uglify.ast_mangle"
        ast_squeeze: jasmine.createSpy "uglify.uglify.ast_squeeze"
        gen_code:    jasmine.createSpy "uglify.uglify.gen_code"


    # Stub logs
    logging.critical = jasmine.createSpy "logging.critical"
    logging.info     = jasmine.createSpy "logging.info"
    logging.warn     = jasmine.createSpy "logging.warn"

    exec = jasmine.createSpy "childProcess.exec"

    yaml =
      dump: jasmine.createSpy "yaml.dump"

    minify = jasmine.createSpy "minify"

    # Stub fs module
    fs =
      readFile:      jasmine.createSpy "fs.readFile"
      readFileSync:  jasmine.createSpy "fs.readFileSync"
      unlink:        jasmine.createSpy "fs.unlink"
      writeFile:     jasmine.createSpy "fs.writeFile"
      writeFileSync: jasmine.createSpy "fs.writeFileSync"

    # Stub flow
    flow =
      exec: jasmine.createSpy "flow.exec"

    # Stub other things that interact with the process
    exit = jasmine.createSpy "process.exit"
    readDir = jasmine.createSpy "readDir"

    Package.prototype.complete = exit
    Package.prototype.exec = exec
    Package.prototype.yaml = yaml
    Package.prototype.flow = flow
    Package.prototype.readDir = ->
      readDir.apply this, arguments
      retVal =
        files: [opts.root+'specs/foo_spec.js',
                opts.root+'specs/image.img',
                opts.root+'specs/bar_spec.js']

    Package.prototype.coffee =
      compile: ->
         coffee.compile.apply this, arguments
         compiled

    Package.prototype.fs =
      readFile: fs.readFile
      readFileSync: ->
        fs.readFileSync.apply this, arguments
        JSON.stringify configs
      writeFile: fs.writeFile
      writeFileSync: ->
        fs.writeFileSync.apply this, arguments
      unlink: fs.unlink

  describe 'when loading a coffee-script project', ->

    srcs = undefined
    beforeEach ->
      opts.coffee = true
      opts.test_build_source_file = 'foo.js'
      opts.sources = ['http://www.example.com/foo.js', 'foo.coffee', 'bar.coffee']
      pack = new Package opts, cmd
      srcs = pack.sources

    it 'should return compiled and HTTP sources', ->
      expect(srcs.length).toEqual 2
      expect(srcs[0]).toEqual opts.sources[0]
      expect(srcs[1]).toEqual opts.test_build_source_file

    it 'should compile coffee from sources', ->
      expect(fs.readFileSync).toHaveBeenCalled()
      expect(fs.readFileSync.calls.length).toEqual 3 # +1 for the config file
      expect(fs.readFileSync.calls[1].args[0]).toEqual 'src/'+opts.sources[1]
      expect(fs.readFileSync.calls[2].args[0]).toEqual 'src/'+opts.sources[2]
      expect(coffee.compile).toHaveBeenCalled()

    it 'should write the compiled coffee to the build file', ->
      expect(fs.writeFileSync).toHaveBeenCalled()
      expect(fs.writeFileSync.calls[0].args[0]).toBe opts.test_build_source_file
      expect(fs.writeFileSync.calls[0].args[1]).toBe [compiled, compiled].join "\n"

  describe 'when loading configs fails', ->

    beforeEach ->
      Package.prototype.fs.readFileSync = ->
          fs.readFileSync.apply this, arguments
          '{"bad_json" : tru'
      Package.prototype.readDir = (dir)->

      pack = new Package opts, cmd

    it 'should exit with code 1', ->
      expect(pack.exitCode).toEqual 1

  describe 'successfully loading configs', ->

    beforeEach ->
      pack = new Package opts, cmd

    it 'reads the jspackle.json file', ->
      expect(fs.readFileSync).toHaveBeenCalled()
      expect(fs.readFileSync.calls[0].args[0]).toEqual process.cwd()+'/jspackle.json'

    eval test 'configs'
    eval test 'properties'
    eval test 'test'
    eval test 'build'
    eval test 'build_depends'
    eval test 'minify'
    eval test 'get'

