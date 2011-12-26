Package = require '../lib/package'
logging = require '../lib/logging'

module.exports = (jasmine)->
  h = {}
  h.ast = {}
  h.configs =
    first: 'z'
    third: 'c'
    test_args: " --forceReset"
    depends: ['jquery.js',
              'http://www.example.com/underscore.js',
              'https://myprivate.server.net/my_lib.latest.js']
    test_depends: ['jasmine.js', 'jquery-test-suite.js']
    sources: ['foo.js', 'baz.js', 'bar.js']
    test_server: 'http://localhost:9876'
    test_timeout: 90

  h.coffee =
    compile: jasmine.createSpy "coffee.compile"

  h.compiled = {}

  h.opts =
    root: process.cwd()+'/'
    path: 'jspackle.json'
    first: 'a'
    second: 'b'

  h.cmd =
    second: 'x'

  h.uglify =
    parser:
      parse:       jasmine.createSpy "uglify.parser.parse"
    uglify:
      ast_mangle:  jasmine.createSpy "uglify.uglify.ast_mangle"
      ast_squeeze: jasmine.createSpy "uglify.uglify.ast_squeeze"
      gen_code:    jasmine.createSpy "uglify.uglify.gen_code"


  # Stub logs
  logging.critical = jasmine.createSpy "logging.critical"
  logging.info     = jasmine.createSpy "logging.info"
  logging.warn     = jasmine.createSpy "logging.warn"

  h.exec = jasmine.createSpy "childProcess.exec"

  h.yaml =
    dump: jasmine.createSpy "yaml.dump"

  h.minify = jasmine.createSpy "minify"

  # Stub fs module
  h.fs =
    readFile:      jasmine.createSpy "fs.readFile"
    readFileSync:  jasmine.createSpy "fs.readFileSync"
    unlink:        jasmine.createSpy "fs.unlink"
    writeFile:     jasmine.createSpy "fs.writeFile"
    writeFileSync: jasmine.createSpy "fs.writeFileSync"

  # Stub flow
  h.flow =
    exec: jasmine.createSpy "flow.exec"

  # Stub other things that interact with the process
  h.exit = jasmine.createSpy "process.exit"
  h.readDir = jasmine.createSpy "readDir"

  Package.prototype.complete = h.exit
  Package.prototype.exec = h.exec
  Package.prototype.yaml = h.yaml
  Package.prototype.flow = h.flow
  Package.prototype.readDir = ->
    h.readDir.apply this, arguments
    retVal =
      files: [h.opts.root+'specs/foo_spec.js',
              h.opts.root+'specs/image.img',
              h.opts.root+'specs/bar_spec.js']

  Package.prototype.coffee =
    compile: ->
        h.coffee.compile.apply this, arguments
        h.compiled

  Package.prototype.fs =
    readFile: h.fs.readFile
    readFileSync: ->
      h.fs.readFileSync.apply this, arguments
      JSON.stringify h.configs
    writeFile: h.fs.writeFile
    writeFileSync: ->
      h.fs.writeFileSync.apply this, arguments
    unlink: h.fs.unlink

  h.Package = Package
  return h
