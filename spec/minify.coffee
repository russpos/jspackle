describe 'Package.minify', ->

  source = minified = evalAndAssert = undefined
  beforeEach ->
    source = "var a = 'bar';\nvar b = {};\nvar c = { foo: b };"
    evalAndAssert = (src, expect)->
      eval src
      expect(a).toEqual 'bar'
      expect(b).toEqual {}
      expect(c.foo).toBe b

  describe 'with stubs', ->

    beforeEach ->
      minified = pack.minify source

    it 'should parse the source', ->
      expect(stub.stubs['uglify-js'].parser.parse).toHaveBeenCalled()
      expect(stub.stubs['uglify-js'].parser.parse.calls[0].args[0]).toEqual source

    it 'should mangle the tokens', ->
      expect(stub.stubs['uglify-js'].uglify.ast_mangle).toHaveBeenCalled()

    it 'should squeeze the mangled tokens', ->
      expect(stub.stubs['uglify-js'].uglify.ast_squeeze).toHaveBeenCalled()

    it 'should generate code from the mangled, squeezed tokens', ->
      expect(stub.stubs['uglify-js'].uglify.gen_code).toHaveBeenCalled()
