Package = require '../lib/package'

configs =
  first: 'z'
  third: 'c'

opts =
  root: process.cwd()+'/'
  path: 'jspackle.json'
  first: 'a'
  second: 'b'

cmd =
  second: 'x'

describe 'Package', ->

  tools = pack = fs = undefined
  beforeEach ->
    fs =
      readFileSync:  jasmine.createSpy "fs.readFileSync"
      writeFileSync: jasmine.createSpy "fs.writeFileSync"

    Package.prototype.fs =
      readFileSync: ->
        fs.readFileSync.apply this, arguments
        JSON.stringify configs
      writeFileSync: ->
        fs.writeFileSync.apply this, arguments

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


