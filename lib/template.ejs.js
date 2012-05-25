(function() {
var x;
<% if (include_depends === true) { %>

  <% depends.forEach(function(src) { %>
  x = new XMLHttpRequest();
  x.open('GET', '<%= url %>/depends/<%= src %>', false);
  x.send();
  (window.execScript||function(data){window["eval"].call(window, data);})(x.responseText);
  <% }); %>
    
<% } %>

<% sources.forEach(function(src) { %>
x = new XMLHttpRequest();
x.open('GET', '<%= url %>/<%= src %>', false);
x.send();
(window.execScript||function(data){window["eval"].call(window, data);})(x.responseText);
<% }); %>
})();
