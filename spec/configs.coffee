describe 'Package configuration precedence', ->

  it 'should take on config file options', ->
    expect(pack.opts.third).toBe 'c'

  it 'should replace config file arguments with commandline options', ->
    expect(pack.opts.first).toBe 'a'

  it 'should replace base options with command specific options', ->
    expect(pack.opts.second).toBe 'x'
