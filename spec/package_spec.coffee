Stubble    = require 'stubble'
path       = require 'path'
cs         = require 'coffee-script'
filesys    = require 'fs'
specHelper = require './helper'

Package = undefined
stub = runTest = returned = configs = minify = opts = pack = undefined

# Runs a (partial) test file as if it was written inline into this given test
# suite.
runTest = (file)->
  filename = path.join __dirname, file+'.coffee'
  eval cs.compile filesys.readFileSync(filename).toString()

describe 'Package', ->

  beforeEach ->
    returned =
      compiled: {}
      response:
        on: jasmine.createSpy 'response'

    minify = jasmine.createSpy "minify"
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

    opts =
      root: process.cwd()+'/'
      path: 'jspackle.json'
      first: 'a'
      second: 'b'
      coverage: './coverage.jar'

    stub = specHelper.generateStub configs, opts, returned
    Package = stub.require __dirname+'/../lib/package'
    Package.prototype.complete = jasmine.createSpy "process.exit"

  describe 'when loading a coffee-script project', ->

    srcs = undefined
    beforeEach ->
      opts.coffee = true
      opts.test_build_source_file = 'foo.js'
      opts.sources = ['http://www.example.com/foo.js', 'foo.coffee', 'bar.coffee']
      pack = new Package opts
      srcs = pack.sources

    it 'should return compiled and HTTP sources', ->
      expect(srcs.length).toEqual 2
      expect(srcs[0]).toEqual opts.sources[0]
      expect(srcs[1]).toEqual opts.test_build_source_file

    it 'should compile coffee from sources', ->
      expect(stub.stubs.fs.readFileSync).toHaveBeenCalled()
      expect(stub.stubs.fs.readFileSync.calls.length).toEqual 3 # +1 for the config file
      expect(stub.stubs.fs.readFileSync.calls[1].args[0]).toEqual 'src/'+opts.sources[1]
      expect(stub.stubs.fs.readFileSync.calls[2].args[0]).toEqual 'src/'+opts.sources[2]
      expect(stub.stubs['coffee-script'].compile).toHaveBeenCalled()

    it 'should write the compiled coffee to the build file', ->
      expect(stub.stubs.fs.writeFileSync).toHaveBeenCalled()
      expect(stub.stubs.fs.writeFileSync.calls[0].args[0]).toBe opts.test_build_source_file
      expect(stub.stubs.fs.writeFileSync.calls[0].args[1]).toBe [returned.compiled, returned.compiled].join "\n"

  describe 'when loading configs fails', ->

    beforeEach ->
      stub.stubs.fs.readFileSync = jasmine.createSpy('fs.readFileSync').andReturn '{"bad_json" : tru'
      pack = new Package opts

    it 'should exit with code 1', ->
      expect(pack.exitCode).toEqual 1

  describe 'successfully loading configs', ->

    cmd = undefined
    beforeEach ->
      cmd =
        second: 'x'
      pack = new Package opts, cmd

    it 'reads the jspackle.json file', ->
      expect(stub.stubs.fs.readFileSync).toHaveBeenCalled()
      expect(stub.stubs.fs.readFileSync.calls[0].args[0]).toEqual process.cwd()+'/jspackle.json'

    runTest 'configs'
    runTest 'properties'
    runTest 'test'
    runTest 'build'
    runTest 'build_depends'
    runTest 'minify'
    runTest 'get'
