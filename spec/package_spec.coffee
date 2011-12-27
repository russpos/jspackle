Stubble = require 'stubble'
logging = require '../lib/logging'
path    = require 'path'
cs      = require 'coffee-script'
filesys = require 'fs'

Package = undefined

test = (file)->
  cs.compile filesys.readFileSync(path.join __dirname, file+'.coffee').toString()

describe 'Package', ->

  ###
  Stub out anything u/o related
  ###
  stub = ast = readDir = restler = response = coffee = childProcess = compiled = configs = cmd = restler = files = flow = minify = opts = uglify = yaml = exit = pack = fs = undefined
  beforeEach ->
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

    compiled = {}
    coffee =
      compile: jasmine.createSpy("coffee.compile").andReturn compiled

    opts =
      root: process.cwd()+'/'
      path: 'jspackle.json'
      first: 'a'
      second: 'b'

    response =
      on: jasmine.createSpy 'response'
    restler =
      get: jasmine.createSpy('restler.get').andReturn response

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


    childProcess =
      exec: jasmine.createSpy "childProcess.exec"

    yaml =
      dump: jasmine.createSpy("yaml.dump").andReturn true

    minify = jasmine.createSpy "minify"

    # Stub fs module
    fs =
      readFile:      jasmine.createSpy "fs.readFile"
      readFileSync:  jasmine.createSpy("fs.readFileSync").andReturn JSON.stringify configs
      unlink:        jasmine.createSpy "fs.unlink"
      writeFile:     jasmine.createSpy "fs.writeFile"
      writeFileSync: jasmine.createSpy "fs.writeFileSync"

    # Stub flow
    flow =
      exec: jasmine.createSpy "flow.exec"

    # Stub other things that interact with the process
    exit = jasmine.createSpy "process.exit"
    readDir = jasmine.createSpy("readDir").andReturn files: [opts.root+'specs/foo_spec.js',
                                                             opts.root+'specs/image.img',
                                                             opts.root+'specs/bar_spec.js']

    stubs =
       fs: fs
       flow: flow
       "uglify-js": uglify
       restler: restler
       pyyaml: yaml
       child_process: childProcess
       "./readdir": readDir
       "coffee-script" : coffee

    stub = new Stubble stubs
    Package = stub.require __dirname+'/../lib/package'

    Package.prototype.complete = exit
#    Package.prototype.exec = exec
#    Package.prototype.yaml = yaml
#    Package.prototype.flow = flow
#    Package.prototype.readDir = readDir
#    Package.prototype.coffee = coffee
#    Package.prototype.fs = fs

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
      fs.readFileSync = jasmine.createSpy('fs.readFileSync').andReturn '{"bad_json" : tru'
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

