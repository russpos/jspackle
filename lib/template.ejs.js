(function() {
var x;
<% sources.forEach(function(src) { %>
x = new XMLHttpRequest();
x.open('GET', '<%= url %>/<%= src %>', false);
x.send();
(window.execScript||function(data){window["eval"].call(window, data);})(x.responseText);
<% }); %>
})();
