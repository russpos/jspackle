describe 'httpGet', ->

  beforeEach ->
    pack.httpGet 'http://www.google.com', returned.response

  it 'should call restler.get', ->
    expect(stub.stubs.restler.get).toHaveBeenCalled()
    expect(stub.stubs.restler.get.calls[0].args[0]).toEqual 'http://www.google.com'

  describe 'on complete', ->
    it 'should handle the callback', ->
      expect(returned.response.on).toHaveBeenCalled()
      expect(returned.response.on.calls[0].args[0]).toEqual 'complete'
      expect(returned.response.on.calls[0].args[1]).toEqual returned.response

  describe 'on error', ->
    it 'should throw an error', ->
      expect(returned.response.on).toHaveBeenCalled()
      expect(returned.response.on.calls[1].args[0]).toEqual 'error'
      expect(typeof returned.response.on.calls[1].args[1]).toEqual 'function'

    describe 'when an error occurs', ->

      beforeEach ->
        returned.response.on.calls[1].args[1]()

      it 'should exit', ->
        expect(pack.exitCode).toEqual 1

