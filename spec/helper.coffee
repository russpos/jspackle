Stubble = require 'stubble'
logging = require '../lib/logging'

module.exports =
  generateStub: (configs, opts, retVals)->
    coffee =
      compile: jasmine.createSpy("coffee.compile").andReturn retVals.compiled

    restler =
      get: jasmine.createSpy('restler.get').andReturn retVals.response

    uglify =
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

    childProcess =
      exec: jasmine.createSpy "childProcess.exec"

    yaml =
      dump: jasmine.createSpy("yaml.dump").andReturn true

    # Stub fs module
    fs =
      readFile:      jasmine.createSpy "fs.readFile"
      readFileSync:  jasmine.createSpy("fs.readFileSync").andReturn JSON.stringify configs
      unlink:        jasmine.createSpy "fs.unlink"
      writeFile:     jasmine.createSpy "fs.writeFile"
      writeFileSync: jasmine.createSpy "fs.writeFileSync"
      mkdirSync: jasmine.createSpy "fs.mkdirSync"

    # Stub flow
    flow =
      exec: jasmine.createSpy "flow.exec"

    # Stub other things that interact with the process
    readDir = jasmine.createSpy("readDir").andReturn files: [opts.root+'specs/foo_spec.js',
                                                             opts.root+'specs/image.img',
                                                             opts.root+'specs/bar_spec.js']

    stubs =
       'node-fs': fs
       flow: flow
       "uglify-js": uglify
       restler: restler
       pyyaml: yaml
       child_process: childProcess
       "./readdir": readDir
       "coffee-script" : coffee

    stub = new Stubble stubs
