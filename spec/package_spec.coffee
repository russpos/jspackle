Package = require '../lib/package'
logging = require '../lib/logging'

describe 'Package', ->

  readDir = coffee = compiled = configs = cmd = flow = opts = exec = yaml = exit = pack = fs = undefined
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


    # Stub logs
    logging.critical = jasmine.createSpy "logging.critical"
    logging.info     = jasmine.createSpy "logging.info"
    logging.warn     = jasmine.createSpy "logging.warn"

    exec = jasmine.createSpy "childProcess.exec"

    yaml =
      dump: jasmine.createSpy "yaml.dump"

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

    Package.prototype.exit = exit
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
      expect(exit).toHaveBeenCalled()
      expect(exit.calls[0].args[0]).toEqual 1

  describe 'successfully loading configs', ->

    beforeEach ->
      pack = new Package opts, cmd

    it 'reads the jspackle.json file', ->
      expect(fs.readFileSync).toHaveBeenCalled()
      expect(fs.readFileSync.calls[0].args[0]).toEqual process.cwd()+'/jspackle.json'

    describe 'Package configuration precedence', ->

      it 'should take on config file options', ->
        expect(pack.opts.third).toBe 'c'

      it 'should replace config file arguments with commandline options', ->
        expect(pack.opts.first).toBe 'a'

      it 'should replace base options with command specific options', ->
        expect(pack.opts.second).toBe 'x'

    describe 'package properties', ->

      it 'should have sources', ->
        sources = pack.sources
        expect(sources.length).toEqual 3
        expect(sources[0]).toBe 'src/foo.js'
        expect(sources[1]).toBe 'src/baz.js'
        expect(sources[2]).toBe 'src/bar.js'

      it 'should have depends', ->
        deps = pack.depends
        expect(deps.length).toEqual 3
        expect(deps[0]).toBe 'requires/jquery.js'
        expect(deps[1]).toBe configs.depends[1]
        expect(deps[2]).toBe configs.depends[2]

      it 'should have test_depends', ->
        deps = pack.testDepends
        expect(deps.length).toEqual 2
        expect(deps[0]).toBe 'requires/jasmine.js'
        expect(deps[1]).toBe 'requires/jquery-test-suite.js'

      it 'should have tests', ->
        tests = pack.tests
        expect(readDir).toHaveBeenCalled()
        expect(readDir.calls[0].args[0]).toEqual opts.root+'specs'
        expect(tests.length).toEqual 2
        expect(tests[0]).toEqual 'specs/foo_spec.js'
        expect(tests[1]).toEqual 'specs/bar_spec.js'

      it 'should have a custom testCmd', ->
        cmd = pack.testCmd
        expect(cmd.indexOf(configs.test_args)).toBeGreaterThan 0

    describe 'running tests', ->

      args = undefined
      beforeEach ->
        pack.test()
        args = yaml.dump.calls[0].args

      it 'dumps the YAML configs', ->
        expect(yaml.dump).toHaveBeenCalled()

      it 'loads depends, test_depends, then sources', ->
        expect(args[0].load).toEqual [
          'requires/jquery.js'
          configs.depends[1]
          configs.depends[2]
          'requires/jasmine.js'
          'requires/jquery-test-suite.js'
          'src/foo.js'
          'src/baz.js'
          'src/bar.js'
        ]

      it 'loads the configured server', ->
        expect(args[0].server).toEqual configs.test_server

      it 'loads the configured timeout', ->
        expect(args[0].timeout).toEqual configs.test_timeout

      it 'loads the correct tests', ->
        expect(args[0].test).toEqual [
          'specs/foo_spec.js'
          'specs/bar_spec.js'
        ]

      it 'writes the file to the file JsTestDriver.conf in the root', ->
        expect(args[1]).toEqual process.cwd()+'/JsTestDriver.conf'

      it 'has a callback for after writing the configs', ->
        expect(args[2] instanceof Function).toBeTruthy()


      describe 'if writing the config file fails', ->

        beforeEach ->
          args[2] 'error'

        it 'should exit with an error code 1', ->
          expect(exit).toHaveBeenCalled()
          expect(exit.calls[0].args[0]).toEqual 1

      describe 'after configs have been written', ->

        beforeEach ->
          args[2]()

        it 'should exec the test command', ->
          expect(exec).toHaveBeenCalled()
          expect(exec.calls[0].args[0]).toEqual pack.testCmd

        describe 'when test command fails', ->

          beforeEach ->
            exec.calls[0].args[1] code: 127

          it 'should clean', ->
            expect(fs.unlink).toHaveBeenCalled()
            expect(fs.unlink.calls.length).toEqual 3

          it 'should exit with the given error code', ->
            expect(exit).toHaveBeenCalled()
            expect(exit.calls[0].args[0]).toEqual 127

        describe 'when test command passes', ->
          beforeEach ->
            exec.calls[0].args[1]()

          it 'should clean', ->
            expect(fs.unlink).toHaveBeenCalled()
            expect(fs.unlink.calls.length).toEqual 3

          it 'should exit with a code of 0', ->
            expect(exit).toHaveBeenCalled()
            expect(exit.calls[0].args[0]).toEqual 0

    describe 'building', ->

      dummyExec = undefined
      beforeEach ->
        dummyExec =
          MULTI: -> ->
        pack.build()

      it 'should use flow', ->
        expect(flow.exec).toHaveBeenCalled()

      describe 'first flow action', ->

        beforeEach ->
          flow.exec.calls[0].args[0].apply dummyExec

        it 'should load sources', ->
          expect(fs.readFile).toHaveBeenCalled()
          expect(fs.readFile.calls.length).toEqual 3
          expect(fs.readFile.calls[0].args[0]).toEqual process.cwd()+'/src/foo.js'
          expect(fs.readFile.calls[1].args[0]).toEqual process.cwd()+'/src/baz.js'
          expect(fs.readFile.calls[2].args[0]).toEqual process.cwd()+'/src/bar.js'

      describe 'when the reading fails', ->

        beforeEach ->
          flow.exec.calls[0].args[0].apply dummyExec
          for index, call of fs.readFile.calls
            call.args[1] 'Error', index+1
          flow.exec.calls[0].args[1].apply dummyExec

        it 'should error out', ->
          expect(exit).toHaveBeenCalled()
          expect(exit.calls[0].args[0]).toEqual 1

      describe 'second flow action', ->

        beforeEach ->
          flow.exec.calls[0].args[0].apply dummyExec
          for index, call of fs.readFile.calls
            call.args[1] null, index+1
          flow.exec.calls[0].args[1].apply dummyExec

        it 'should write the contents', ->
          expect(fs.writeFile).toHaveBeenCalled()
          expect(fs.writeFile.calls.length).toEqual 1
          expect(fs.writeFile.calls[0].args[0]).toEqual process.cwd()+'/output.js'
          expect(fs.writeFile.calls[0].args[1]).toEqual "01\n11\n21"

        describe 'when writing succeeds', ->
          beforeEach ->
            flow.exec.calls[0].args[2].apply dummyExec

          it 'should exit with a 0', ->
            expect(exit).toHaveBeenCalled()
            expect(exit.calls[0].args[0]).toEqual 0

        describe 'when writing fails', ->
          beforeEach ->
            flow.exec.calls[0].args[2].apply dummyExec, ['Error']

          it 'should exit with a 1', ->
            expect(exit).toHaveBeenCalled()
            expect(exit.calls[0].args[0]).toEqual 1
