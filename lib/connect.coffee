Package = require './package'
_       = require 'underscore'
coffee  = require 'coffee-script'
ejs     = require 'ejs'
fs      = require 'fs'
path    = require 'path'

template = fs.readFileSync(path.join __dirname, 'template.ejs.js').toString().replace(/\n/g, '')

###
Jspackle connect middleware

This piece of a middleware is recommended for development usage only.  For
production deployed systems, combine your pacakge using `jspackle build` and
serve statically.

Creates a request handler that will handle all requests that start with
the given `urlPath`, based on the package defined by the jspackle config
file described in `confPath`.

Eg:
connect.createServer(jspackle.connect('/path/to/jspackle.json', '/js/my_project.js'), ....);

When a request is made to `/js/my_project.js`, Jspackle serves a JavaScript file that
synchronously loads all of the source files described in `/path/to/jspackle.json`:

  GET: `/js/my_project.js/foo.js`
  GET: `/js/my_project.js/bar.js`

These requests are also caught by the jspackle middleware, which finds the source
files based on the package configs, reads the given source file off of disc and
serves it to the browser.  Using CoffeeScript?  That's fine! Sources that end with
`.coffee` will be compiled in real-time in memory by the jspackle middleware and
served back as JavaScript.
###


###
Serves the provided string of JavaScript source to as
the result of request object provided.
###
serveJavaScript = (res, source='')->
  res.statusCode = 200
  res.setHeader 'Content-type', 'text/javascript'
  res.end source

###
Returns a 500 error
###
error = (err, res)->
  console.error err
  res.statusCode = 500
  res.end err

###
Compiles the provided CoffeeScript source and send it as the
response.
###
serveCoffeeScript = (res, source)->
  try
    source = coffee.compile source
    serveJavaScript res, source
  catch e
    error e, res

###
Loads the source at the given path.
###
loadSource = (sourcePath, res)->
  try
    fs.readFile sourcePath, (err, data)->
      return error err, res if err
      data = data.toString()
      serve = if sourcePath.match new RegExp '\.coffee$' then serveCoffeeScript else serveJavaScript
      serve res, data
  catch e
    error e, res

###
A function generator:
Creates a middleware function for serving jspackle packages in 'development'
mode.
###
module.exports = (confPath, urlPath)->

  configs =
    url: urlPath
    include_depends: false

  package = JSON.parse fs.readFileSync confPath
  packageObj = new Package root: path.dirname(confPath)+'/', path: path.basename(confPath)

  ###
  Creates a main JavaScript file which synchronously loads all the
  development sources in order via XHR
  ###
  _.extend configs, package
  main = ejs.render template, configs

  (req, res, next)->
    url = req.url.split('?')[0]
    if url is urlPath
      serveJavaScript res, main
    else if url.match new RegExp "^#{urlPath}"
      source = url.replace(urlPath, '')
      if source.match /^\/depends/
        source = source.replace /^\/depends/, ''
        folder = packageObj.opts.depends_folder
      else
        folder = packageObj.opts.source_folder
      srcPath = path.join packageObj.opts.root, folder, source
      loadSource srcPath, res
    else
      next()
