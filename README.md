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
    <script src="http://cdnjs.cloudflare.com/ajax/libs/zepto/1.0/zepto.min.js">
    </script>
    <script src="http://cdn.sockjs.org/sockjs-0.3.min.js"></script>
    <script src="/static/sockjs_reconnect.min.js"></script>
    <script>
      /* Example usage. */

      new_status = function(status) {
        $('#status').text(status);
        if (status === 'connected') {
          sock.conn.send('ping');
        }
      }
      on_message = function(msg) {
        $('#last-message').text(msg.data);
        setTimeout(function() { if (sock.conn) { sock.conn.send('ping'); } },
          150);
      }

      var sock = new SockReconnect('/sock', new_status, on_message);
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
