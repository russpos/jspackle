Package = require '../lib/package'

describe 'Package', ->

  tools = path = pack = undefined
  beforeEach ->
    tools =
      fs:
        readFileSync: jasmine.createSpy "fs.readFileSync"
    path = './foo/bar/jspackle.json'
    pack = new Package tools, {}

  it 'reads the jspackle.json file', ->
    expect(tools.fs.readFileSync).toHaveBeenCalled()
    expect(tools.fs.readFileSync.calls[0].args[0]).toEqual process.cwd()+'/jspackle.json'



