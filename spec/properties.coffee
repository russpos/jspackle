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
    expect(stub.stubs['./readdir']).toHaveBeenCalled()
    expect(stub.stubs['./readdir'].calls[0].args[0]).toEqual opts.root+'specs'
    expect(tests.length).toEqual 2
    expect(tests[0]).toEqual 'specs/foo_spec.js'
    expect(tests[1]).toEqual 'specs/bar_spec.js'

  it 'should have a custom testCmd', ->
    cmd = pack.testCmd
    expect(cmd.indexOf(configs.test_args)).toBeGreaterThan 0


