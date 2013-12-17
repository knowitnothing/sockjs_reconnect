SockJS Reconnector
==================

This is a small module for handling disconnects in the client while using
SockJS. The reconnection proceeds in the following manner (by default):

  * When ```onclose``` is triggered, it first tries to reconnect
	immediately.
  * If it remains unconnected, another attempt is done after ```t = 1500 + x```
	milliseconds, and then at ```2 * t```, ```4 * t```, ..., ```32 * t```.
  * If it is still unconnected, the multiplier is reset to ```1``` and the
	process is repeated.
  * If it does not connect after ```30``` attempts, it stops trying
	and performs a page reload.
  * In case ```onopen``` is triggered at any point, the parameters are
	reset to the initial values.


All the parameters used above are configurable, and here is an example
using the module (try stopping/starting the server):

```html
<!DOCTYPE html>
<html>
<head>
  <script src="http://cdnjs.cloudflare.com/ajax/libs/zepto/1.0/zepto.min.js"></script>
  <script src="http://cdn.sockjs.org/sockjs-0.3.min.js"></script>
  <script src="/static/sockjs_reconnect.js"></script>
  <script>
    /* Example usage. */

    on_message = function (msg) {
      console.log(arguments);
      $('#last-message').text(msg.data);
      setTimeout(function () { if (sock.conn) { sock.send('ping'); } },
          150);
    };

    var sock = new SockReconnect('/sock');

    sock
        .on('message', on_message)
        .on('open', function () {
          $('#status').text("Connected")
        })
        .on('close', function () {
          $('#status').text("Disconnected")
        })
        .on('connect reconnect', function () {
          $('#status').text("Connecting...")
        })
        .on('open', function () {
          sock.send('ping');
        });

    if (window.addEventListener) {
      window.addEventListener('load', sock.connect, false);
    } else {
      window.attachEvent('onload', sock.connect);
    }
  </script>
</head>
<body>
<p>Connection status: <span id="status">Disconnected</span></p>

<p>Last message: <span id="last-message"></span></p>
</body>
</html>
```

Events
=======

To attach listeners to events use `.on(event, handler)` methods.  
`event` - string, containing one or several events (separated by whitespace)  
`handler` - function.

###Currently supported events

`open` - connection is established    
`close` - connection is closed    
`connect` - fires on all connection attempts    
`reconnect` - fires only on reconnection attempts    
`message` - message received. Handler is called with the same arguments as `websocket.onmessage`