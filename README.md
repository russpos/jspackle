# jspackle


![Travis-CI Status](https://secure.travis-ci.org/russjp1985/jspackle.png)

`jspackle` is a tool for continuous integration of client-side JavaScript packages. It allows you to define a package
in a simple JSON format, and provides mechanisms for executing basic tasks via a commandline interface.

## Tasks

 * `test` - Load dependencies, test dependencies, sources, and auto-discovered tests and execute tests.  Currently
   supports using the [http://code.google.com/p/js-test-driver/](JsTestDriver) framework for easy CIS integration.
   Makes cross browser TDD for your project a breeze.

 * `build` - Combine, compile, and minify sources. Also has built in support for `coffee-script`.  Uses `uglify-js`
  as its parser.

**NOTE:** In order to use this tool, you need to have JsTestDriver installed, and available
via the command `js-test-driver`

## Usage
To begin using `jspackle` with your project, you must create a jspackle.json file in your
project's root.  Example jspackle.json file:

    {
        "name" : "your-project-name",
        "version" : "1.2.0",
        "test_depends": ["jasmine.js", "jasmine-jstd-adapter.js"],
        "depends": ["jquery.js", "underscore.js"],
        "sources": [
          "first_file.js",
          "second_file.js"
        ]
    }

Assuming you have a project with this structure:

    .
    ├── jspackle.json
    ├── requires
    │   ├── jasmine-jstd-adapter.js
    │   ├── jasmine.js
    │   ├── jquery.js
    │   └── underscore.js
    ├── specs
    │   ├── foo_spec.js
    │   └── second_file.js
    └── src
        ├── first_file.js
        └── second_file.js

You can then simple run `jspackle test` to execute our tests:

    $ jspackle test
    jspackle v1.0.7

    % info    | Executing command: 'test'
    % info    | Executing 2 specs
    % info    |
    % info    | Output:
    % info    |
    % info    | Firefox: Runner reset.
    % info    | Safari: Runner reset.
    % info    | Chrome: Runner reset.
    % info    | ......
    % info    | Total 6 tests (Passed: 6; Fails: 0; Errors: 0) (5.00 ms)
    % info    |   Safari 534.50 Mac OS: Run 2 tests (Passed: 2; Fails: 0; Errors 0) (5.00 ms)
    % info    |   Firefox 8.0.1 Mac OS: Run 2 tests (Passed: 2; Fails: 0; Errors 0) (1.00 ms)
    % info    |   Chrome 16.0.912.41 Mac OS: Run 2 tests (Passed: 2; Fails: 0; Errors 0) (2.00 ms)
    % info    |
    % info    | Cleaning up after jspackle run...

When you are ready to distribute your multifile application, simply run `build`:

    $ jspackle build
    jspackle v1.0.7

    % info    | Executing command: 'build'
    % info    | Found 2 source file
    % info    | Writing processed sources to: 'output.js'


## Configuration

Using both the configuration file `jspackle.json`, there are several options
that you can specify when configuring your project:

### Project configs:
 * `name`           - The name of the project
 * `version`        - Current version string of the project
 * `sources`        - A list of source files, in the correct dependency order
 * `depends`        - A list of dependencies, as filenames relative to the `depends_folder`
 * `test_depends`   - A list of test dependencies, as filenames also relative to the `depends_folder`

Optional configs.  These all have sane default values, but can be tweaked if desired:

 * `test_build_folder` - ("build") Temporary folder to put compiled coffeescript source files to run tests.
 * `depends_folder` - ("requires") Folder that contains dependencies in order for the
    tests to run
 * `source_folder`  - ("src") Folder that contains your application source
 * `spec_folder`    - ("specs") Folder where your tests are located.  Since the order that
    your tests run in should not matter, tests are autodiscovered, rather than forcing you
    to manually specify them.

### Build task configs:
 * `minify`          - (False) Should the output be minified? (uses uglify-js)
 * `include_depends` - (False) Should the output include dependencies?
 * `build_output`    - ("output.js") File name to use when executing `build` task. This argument
   can take mustache style templating variables to include the values of both `name`
   and `version`.  For example: `{{name}}.{{version}}.min.js`

### Test task configs:
 * `test_server`    - ("http://localhost:9876") JsTestDriver server to use for testing
 * `test_timeout`   - (90) Timeout setting (in seconds)
 * `test_args`      - Additional arguments to pass to the underlying tester

## Commandine options
`jspackle` provides several commandline options to customize its usage:

 * `-h, --help`      - Shows help menu
 * `-V, --version`   - Display the version number, then exit
 * `-v, --verbose`   - Include debugging information in the output
 * `-q, --quiet`     - Only print critical errors to the screen
 * `-n, --no-color`  - Disable colors in the output.
 * `-p, --path`      - ("jspackle.json") Path of the config file.  You probably don't want
    to change this, but could be useful in certain scenarios.
 * `-C, --coverage`  - Path to JSTD coverage plugin to use

### Commandline overrides
Any of the task specific configs can be overridden from the commandline.

## Jspackle Connect middleware

This piece of middleware is recommended for development usage only.  For
production deployed systems, combine your package using `jspackle build` and
serve statically.

The connect middleware creates a request handler that will handle all requests that
start with the given `urlPath`, based on the package defined by the Jspackle config
file described in `confPath`. Usage:

    jspackle.connect(confPath, urlPath)

Example:

    var connect = require('connect'),
        jspackle = require('jspackle');
    connect.createServer(jspackle.connect('/path/to/jspackle.json', '/js/my_project.js'), ....);

When a request is made to `/js/my_project.js`, Jspackle serves a JavaScript file that
synchronously loads all of the source files described in `/path/to/jspackle.json`:

    GET: `/js/my_project.js/foo.js`
    GET: `/js/my_project.js/bar.js`

These requests are also caught by the jspackle middleware, which finds the source
files based on the package configs, reads the given source file off of disc, and then
serves it to the browser.  It also handles CoffeeScript files right out of the box.
Sources that end with `.coffee` will be compiled in real-time in memory by the jspackle
middleware and served back to the browser as JavaScript. If `include_depends` is `true`
in the jspackle config the jspackle middleware will serve all dependencies before the
source files.

Here's a full example using the Express framework:

    var jspackle = require('jspackle'),
        express  = require('express');

    app = express.createServer();

    // The rest of your app
    ...

    app.configure('development', function() {
      app.use(jspackle.connect('/path/to/jspackle.json', '/javascripts/my_project.js'));
    });

    // App configuration
    ...

    app.listen(8000);

Assuming your app is set up to serve static files, when your app is in production mode,
requests to `/javascripts/my_project.js` will behave normally, ideally going to the actual
concatenated and minified JavaScript file that `jspackle build` will create. However,
when in development mode, the Jspackle connect middleware intercepts the request and
instead serves the JavaScript needed to load all the sources individually.
