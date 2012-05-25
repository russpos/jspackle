connect = require '../lib/connect'
path    = require 'path'

xhrs = []
window = undefined

class XMLHttpRequest

  @clear: ->
    xhrs = []

  constructor: ->
    xhrs.push @

    @opened = no
    @sent   = no
    @responseText = no

  open: -> @opened = [].splice.call arguments, 0
  send: ->
    @sent = yes
    @responseText = "h.push('#{@opened[1]}');"

describe 'connect', ->

  it 'should be a function', ->
    expect(typeof connect).toBe 'function'

  describe 'using express', ->

    handler = undefined
    beforeEach ->
      XMLHttpRequest.clear()
      window =
        eval: jasmine.createSpy "eval"

      handler = connect path.join(__dirname, 'fixtures/jspackle.json'), '/javascripts/project_name.js'

    it 'should return a function', ->
      expect(typeof handler).toBe 'function'

    describe  'handling a request', ->

      req = res = next = undefined
      beforeEach ->
        next = jasmine.createSpy 'next'
        req =
          url: '/something/else'
        res =
          statusCode: undefined
          setHeader: jasmine.createSpy "res.setHeader"
          end:       jasmine.createSpy "res.end"

      describe 'request does not match', ->

        beforeEach ->
          handler req, res, next

        it 'moves to next middleware', ->
          expect(next).toHaveBeenCalled()

      describe 'request matches exactly', ->

        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js'
          handler req, res, next

        it 'should send a JavaScript result', ->
          expect(res.statusCode).toEqual 200
          expect(res.setHeader).toHaveBeenCalled()
          expect(res.setHeader.calls.length).toEqual 1
          expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
          expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
          expect(res.end).toHaveBeenCalled()

        describe 'using the JavaScript result', ->

          beforeEach ->
            eval res.end.calls[0].args[0]

          it 'should have made XHRs', ->
            expect(xhrs.length).toEqual 3
            expect(xhrs[0].opened).toEqual ['GET', '/javascripts/project_name.js/foo.js', false]
            expect(xhrs[1].opened).toEqual ['GET', '/javascripts/project_name.js/bar.js', false]
            expect(xhrs[2].opened).toEqual ['GET', '/javascripts/project_name.js/baz.js', false]

          it 'should have sent all XHRs', ->
            expect(xhrs[0].sent).toBeTruthy()
            expect(xhrs[1].sent).toBeTruthy()
            expect(xhrs[2].sent).toBeTruthy()

          it 'should have evaluated all XHR response', ->
            expect(window.eval).toHaveBeenCalled()
            expect(window.eval.calls.length).toEqual 3
            expect(window.eval.calls[0].args[0]).toEqual "h.push('#{xhrs[0].opened[1]}');"
            expect(window.eval.calls[1].args[0]).toEqual "h.push('#{xhrs[1].opened[1]}');"
            expect(window.eval.calls[2].args[0]).toEqual "h.push('#{xhrs[2].opened[1]}');"


      describe 'request only matches begining of URL', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/foo.js'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000

      describe 'request matches a coffee-script file', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/baz.coffee'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000

      describe 'request matches a file with querystring', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/baz.coffee?version=1.0.3'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000

  describe 'using express with depends file', ->

    handler = undefined
    beforeEach ->
      XMLHttpRequest.clear()
      window =
        eval: jasmine.createSpy "eval"

      handler = connect path.join(__dirname, 'fixtures/jspackle-depends.json'), '/javascripts/project_name.js'

    it 'should return a function', ->
      expect(typeof handler).toBe 'function'

    describe  'handling a request', ->

      req = res = next = undefined
      beforeEach ->
        next = jasmine.createSpy 'next'
        req =
          url: '/something/else'
        res =
          statusCode: undefined
          setHeader: jasmine.createSpy "res.setHeader"
          end:       jasmine.createSpy "res.end"

      describe 'request does not match', ->

        beforeEach ->
          handler req, res, next

        it 'moves to next middleware', ->
          expect(next).toHaveBeenCalled()

      describe 'request matches exactly', ->

        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js'
          handler req, res, next

        it 'should send a JavaScript result', ->
          expect(res.statusCode).toEqual 200
          expect(res.setHeader).toHaveBeenCalled()
          expect(res.setHeader.calls.length).toEqual 1
          expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
          expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
          expect(res.end).toHaveBeenCalled()

        describe 'using the JavaScript result', ->

          beforeEach ->
            eval res.end.calls[0].args[0]

          it 'should have made XHRs', ->
            expect(xhrs.length).toEqual 5

            expect(xhrs[0].opened).toEqual ['GET', '/javascripts/project_name.js/depends/jquery.js', false]
            expect(xhrs[1].opened).toEqual ['GET', '/javascripts/project_name.js/depends/underscore.js', false]
            expect(xhrs[2].opened).toEqual ['GET', '/javascripts/project_name.js/foo.js', false]
            expect(xhrs[3].opened).toEqual ['GET', '/javascripts/project_name.js/bar.js', false]
            expect(xhrs[4].opened).toEqual ['GET', '/javascripts/project_name.js/baz.js', false]

          it 'should have sent all XHRs', ->
            expect(xhrs[0].sent).toBeTruthy()
            expect(xhrs[1].sent).toBeTruthy()
            expect(xhrs[2].sent).toBeTruthy()
            expect(xhrs[3].sent).toBeTruthy()
            expect(xhrs[4].sent).toBeTruthy()

          it 'should have evaluated all XHR response', ->
            expect(window.eval).toHaveBeenCalled()
            expect(window.eval.calls.length).toEqual 5
            expect(window.eval.calls[0].args[0]).toEqual "h.push('#{xhrs[0].opened[1]}');"
            expect(window.eval.calls[1].args[0]).toEqual "h.push('#{xhrs[1].opened[1]}');"
            expect(window.eval.calls[2].args[0]).toEqual "h.push('#{xhrs[2].opened[1]}');"
            expect(window.eval.calls[3].args[0]).toEqual "h.push('#{xhrs[3].opened[1]}');"
            expect(window.eval.calls[4].args[0]).toEqual "h.push('#{xhrs[4].opened[1]}');"


      describe 'request only matches begining of URL', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/foo.js'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000

      describe 'request matches a coffee-script file', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/baz.coffee'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000

      describe 'request matches a file with querystring', ->
        h = undefined
        beforeEach ->
          h = []
          req.url = '/javascripts/project_name.js/baz.coffee?version=1.0.3'
          handler req, res, next

        it 'should send a JavaScript result', ->
          waits 10
          runs ->
            expect(res.statusCode).toEqual 200
            expect(res.setHeader).toHaveBeenCalled()
            expect(res.setHeader.calls.length).toEqual 1
            expect(res.setHeader.calls[0].args[0]).toEqual 'Content-type'
            expect(res.setHeader.calls[0].args[1]).toEqual 'text/javascript'
            expect(res.end).toHaveBeenCalled()
            eval res.end.calls[0].args[0]
            expect(h[0]).toEqual 1000
