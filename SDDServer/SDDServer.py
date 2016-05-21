from flask import Flask, send_from_directory
import os.path

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
