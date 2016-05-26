from flask import Flask, send_from_directory
import os.path
import socket
# patch socket module
socket.socket._bind = socket.socket.bind
def my_socket_bind(self, *args, **kwargs):
    self.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    return socket.socket._bind(self, *args, **kwargs)
socket.socket.bind = my_socket_bind

app = Flask(__name__)


@app.route('/')
def hello_world():
    return 'Hello World!'


@app.route('/app/config/<configName>', methods=['GET'])
def get_app_config(configName):
    configDir = os.path.join(app.root_path, 'config')
    return send_from_directory(configDir, '%s' %configName)


if __name__ == '__main__':
    app.run(host='192.168.1.116')
