jspackle
========

`jspackle` is a tool for continuous integration of client-side JavaScript packages. It allows you to define a package
in a simple JSON format, and provides mechanisms for executing basic tasks:

 * `test` - Load dependencies, test dependencies, sources, and auto-discovered tests and execute tests.  Currently
   supports using the [http://code.google.com/p/js-test-driver/](JsTestDriver) framework for easy CIS integration.

 * `build` - Combine, compile, and minify sources. Also has built in support for `coffee-script`.

 * `serve` - Serve the package in either production or development mode.  This feature is not yet complete.
