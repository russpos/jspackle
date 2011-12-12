# jspackle


`jspackle` is a tool for continuous integration of client-side JavaScript packages. It allows you to define a package
in a simple JSON format, and provides mechanisms for executing basic tasks via a commandline interface.

## Tasks

 * `test` - Load dependencies, test dependencies, sources, and auto-discovered tests and execute tests.  Currently
   supports using the [http://code.google.com/p/js-test-driver/](JsTestDriver) framework for easy CIS integration.
   Makes cross browser TDD for your project a breeze.

 * `build` - Combine, compile, and minify sources. Also has built in support for `coffee-script`.  Uses `uglify-js`
  as its parser.

 * `serve` - Serve the package in either production or development mode.  Great for testing your
   project as part of your website.  This feature is not yet complete.

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
    jspackle v1.0.4

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
    jspackle v1.0.4

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

 * `coffee`         - (False) Is this project written in CoffeeScript? Any truthy value will
    flip jspackle to run in CoffeeScript mode
 * `depends_folder` - ("requires") Folder that contains dependencies in order for the
    tests to run
 * `source_folder`  - ("src") Folder that contains your application source
 * `spec_folder`    - ("specs") Folder where your tests are located.  Since the order that
    your tests run in should not matter, tests are autodiscovered, rather than forcing you
    to manually specify them.

### Build task configs:
 * `minify`         - (False) Should the output be minified? (uses uglify-js)
 * `build_output`   - ("output.js") File name to use when executing `build` task

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

### Commandline overrides
Any of the task specific configs can be overridden from the commandline.

