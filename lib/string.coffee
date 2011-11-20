String::isHTTP = ->
  @substring(0, 7) == 'http://' or @substring(0, 8) == 'https://'

String::isScript = ->
  this.substring(this.length-2) is 'js' or this.substring(this.length-6) is 'coffee'
