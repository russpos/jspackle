describe 'running tests', ->

  args = undefined
  beforeEach ->
    pack.test()
    #args = yaml.dump.calls[0].args

  it 'starts a flow', ->
    expect(flow.exec).toHaveBeenCalled()
    expect(flow.exec.calls.length).toEqual 1

  describe 'first step', ->

    dummyExec = undefined
    beforeEach ->
      dummyExec = ->
      dummyExec.MULTI = -> ->
      flow.exec.calls[0].args[0] dummyExec

    it 'dumps the YAML configs', ->
      expect(yaml.dump).toHaveBeenCalled()

    it 'loads depends, test_depends, then sources', ->
      expect(yaml.dump.calls[0].args[0].load).toEqual [
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
      expect(yaml.dump.calls[0].args[0].server).toEqual configs.test_server

    it 'loads the configured timeout', ->
      expect(yaml.dump.calls[0].args[0].timeout).toEqual configs.test_timeout

    it 'loads the correct tests', ->
      expect(yaml.dump.calls[0].args[0].test).toEqual [
        'specs/foo_spec.js'
        'specs/bar_spec.js'
      ]

    it 'writes the file to the file JsTestDriver.conf in the root', ->
      expect(yaml.dump.calls[0].args[1]).toEqual process.cwd()+'/JsTestDriver.conf'


    describe 'if writing the config file fails', ->

      beforeEach ->
        flow.exec.calls[0].args[1].apply dummyExec, ['error']

      it 'should exit with an error code 1', ->
        expect(pack.exitCode).toEqual 1
      describe 'after configs have been written', ->

        beforeEach ->
          flow.exec.calls[0].args[1].apply dummyExec, []

        it 'should exec the test command', ->
          expect(childProcess.exec).toHaveBeenCalled()
          expect(childProcess.exec.calls[0].args[0]).toEqual pack.testCmd

        describe 'when test command fails', ->

          beforeEach ->
            flow.exec.calls[0].args[2].apply dummyExec, [127]
            flow.exec.calls[0].args[3].apply dummyExec, []
          it 'should clean', ->
            expect(fs.unlink).toHaveBeenCalled()
            expect(fs.unlink.calls.length).toEqual 3

          it 'should exit with the provided error code', ->
            expect(pack.exitCode).toEqual 127

        describe 'when test command passes', ->
          beforeEach ->
            flow.exec.calls[0].args[2].apply dummyExec, []
            flow.exec.calls[0].args[3].apply dummyExec, []

          it 'should clean', ->
            expect(fs.unlink).toHaveBeenCalled()
            expect(fs.unlink.calls.length).toEqual 3

          it 'should exit with a code of 0', ->
            expect(pack.exitCode).toEqual 0
