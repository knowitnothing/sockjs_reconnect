import time
from tornado import web, ioloop, httpserver
from sockjs.tornado import SockJSRouter, SockJSConnection

class IndexHandler(web.RequestHandler):
    def get(self):
        return self.render('reconnect_example.html')

class Connection(SockJSConnection):
    def on_message(self, msg):
        if msg == 'ping':
            self.send('pong @ %s' % time.ctime())

def main():
    Router = SockJSRouter(Connection, '/sock')
    app = web.Application([
        ('/', IndexHandler),
        (r'/static/(.*)', web.StaticFileHandler, {'path': './'})] +
        Router.urls)

    port_host = (4242, '0.0.0.0')
    http = httpserver.HTTPServer(app)
    http.listen(*port_host)

    print "Listening @", port_host

    ioloop.IOLoop.instance().start()

main()
