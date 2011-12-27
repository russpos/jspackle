describe 'httpGet', ->

  beforeEach ->
    pack.httpGet 'http://www.google.com', response

  it 'should call restler.get', ->
    expect(restler.get).toHaveBeenCalled()
    expect(restler.get.calls[0].args[0]).toEqual 'http://www.google.com'

  describe 'on complete', ->
    it 'should handle the callback', ->
      expect(response.on).toHaveBeenCalled()
      expect(response.on.calls[0].args[0]).toEqual 'complete'
      expect(response.on.calls[0].args[1]).toEqual response

  describe 'on error', ->
    it 'should throw an error', ->
      expect(response.on).toHaveBeenCalled()
      expect(response.on.calls[1].args[0]).toEqual 'error'
      expect(typeof response.on.calls[1].args[1]).toEqual 'function'

    describe 'when an error occurs', ->

      beforeEach ->
        response.on.calls[1].args[1]()

      it 'should exit', ->
        expect(pack.exitCode).toEqual 1

