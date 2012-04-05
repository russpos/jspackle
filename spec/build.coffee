describe 'building', ->

  dummyExec = undefined
  beforeEach ->
    dummyExec =
      MULTI: -> ->
    pack.build()

  it 'should use flow', ->
    expect(stub.stubs.flow.exec).toHaveBeenCalled()

  describe 'first flow action', ->

    describe 'with include_depends', ->

      beforeEach ->
        pack.httpGet = jasmine.createSpy 'http.get'
        pack.opts.include_depends = yes
        stub.stubs.flow.exec.calls[0].args[0].apply dummyExec

      it 'should load sources', ->
        expect(stub.stubs['node-fs'].readFile).toHaveBeenCalled()
        expect(stub.stubs['node-fs'].readFile.calls.length).toEqual 4
        expect(stub.stubs['node-fs'].readFile.calls[0].args[0]).toEqual process.cwd()+'/requires/jquery.js'
        expect(stub.stubs['node-fs'].readFile.calls[1].args[0]).toEqual process.cwd()+'/src/foo.js'
        expect(stub.stubs['node-fs'].readFile.calls[2].args[0]).toEqual process.cwd()+'/src/baz.js'
        expect(stub.stubs['node-fs'].readFile.calls[3].args[0]).toEqual process.cwd()+'/src/bar.js'

      it 'should fetch HTTP sources', ->
        expect(pack.httpGet).toHaveBeenCalled()
        expect(pack.httpGet.calls[0].args[0]).toEqual pack.depends[1]
        expect(pack.httpGet.calls[1].args[0]).toEqual pack.depends[2]

    describe 'without include_depends', ->

      beforeEach ->
        stub.stubs.flow.exec.calls[0].args[0].apply dummyExec

      it 'should load sources', ->
        expect(stub.stubs['node-fs'].readFile).toHaveBeenCalled()
        expect(stub.stubs['node-fs'].readFile.calls.length).toEqual 3
        expect(stub.stubs['node-fs'].readFile.calls[0].args[0]).toEqual process.cwd()+'/src/foo.js'
        expect(stub.stubs['node-fs'].readFile.calls[1].args[0]).toEqual process.cwd()+'/src/baz.js'
        expect(stub.stubs['node-fs'].readFile.calls[2].args[0]).toEqual process.cwd()+'/src/bar.js'

  describe 'when the reading fails', ->

    beforeEach ->
      stub.stubs.flow.exec.calls[0].args[0].apply dummyExec
      for index, call of stub.stubs['node-fs'].readFile.calls
        call.args[1] 'Error', index+1
      stub.stubs.flow.exec.calls[0].args[1].apply dummyExec

    it 'should error out', ->
      expect(pack.exitCode).toEqual 1

  describe 'second flow action', ->

    processExec = output = undefined
    beforeEach ->
      pack.minify = (str)->
        minify str
        str
      processExec = (f, fs, exec)->
        ###
        Stubs out the asynchronous file reads to our source files.
        For each stub.stubs['node-fs'].readFile call, execute its callback as if it loaded
        the a single line, setting a single letter variable to the string
        of the name of the file, eg:

        a = '/home/you/src/foo.js';

        Execute the multistep callback so that all the flow actions are
        registered as complete, then return the concatenated sources.
        ###
        letters = ['a', 'b', 'c']
        f.exec.calls[0].args[0].apply exec
        lines = []
        for index, call of fs.readFile.calls
          text = "#{letters[index]} = '#{call.args[0]}';"
          lines[index] = text
          call.args[1] null, text
        f.exec.calls[0].args[1].apply exec
        lines.join "\n"

    describe 'when minification is on', ->

      beforeEach ->
        pack.opts.minify = on
        output = processExec stub.stubs.flow, stub.stubs['node-fs'], dummyExec

      it 'should pass the data through the minifier', ->
        expect(minify).toHaveBeenCalled()
        expect(minify.calls[0].args[0]).toEqual output

    describe 'when using a templated file path', ->
      output = undefined
      beforeEach ->
        pack.opts.name = 'russ'
        pack.opts.version = '2.0'
        pack.opts.build_output = "{{name}}.{{version}}.js"
        output = processExec stub.stubs.flow, stub.stubs['node-fs'], dummyExec

      it 'should write the contents', ->
        expect(stub.stubs['node-fs'].writeFile).toHaveBeenCalled()
        expect(stub.stubs['node-fs'].writeFile.calls.length).toEqual 1
        expect(stub.stubs['node-fs'].writeFile.calls[0].args[0]).toEqual process.cwd()+'/russ.2.0.js'


    describe 'when minification is off', ->

      output = undefined
      beforeEach ->
        pack.opts.minify = off
        output = processExec stub.stubs.flow, stub.stubs['node-fs'], dummyExec

      it 'should write the contents', ->
        expect(stub.stubs['node-fs'].writeFile).toHaveBeenCalled()
        expect(stub.stubs['node-fs'].writeFile.calls.length).toEqual 1
        expect(stub.stubs['node-fs'].writeFile.calls[0].args[0]).toEqual process.cwd()+'/output.js'
        expect(stub.stubs['node-fs'].writeFile.calls[0].args[1]).toEqual output

      describe 'when writing succeeds', ->
        beforeEach ->
          stub.stubs.flow.exec.calls[0].args[2].apply dummyExec

        it 'should exit with a 0', ->
          expect(pack.exitCode).toEqual 0

      describe 'when writing fails', ->
        beforeEach ->
          stub.stubs.flow.exec.calls[0].args[2].apply dummyExec, ['Error']

        it 'should exit with a 1', ->
          expect(pack.exitCode).toEqual 1
