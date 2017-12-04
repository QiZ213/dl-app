from __future__ import print_function

import argparse
import json
import logging
import os
from importlib import import_module

from flask import Flask
from flask import request

SERVICE_NAME = os.path.basename(os.path.dirname(__file__))

logger = logging.getLogger(SERVICE_NAME)
logger.setLevel(logging.ERROR)
handler = logging.StreamHandler()
handler.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

app = Flask(__name__)


@app.route("/")
def hello():
    return 'hello_world!'


@app.route("/service", methods=['POST'])
def do_service():
    data = [request.stream]
    result = app.my_model.execute(data, 1)[0]
    return result


def parse_cmd():
    """
    Parse command line options to start server
    """
    parser = argparse.ArgumentParser(description='service configuration parser')
    parser.add_argument("--json_conf", default="json.conf", dest="json_conf", help="json configure file")
    parser.add_argument("--port", default="8080", dest="port", help="http server port")
    args = parser.parse_args()

    if os.path.isfile(args.json_conf):
        with open(args.json_conf) as data_file:
            data = json.load(data_file)

    parsed_conf = {"port": args.port}
    try:
        http_server_config = data["http_server"]
        main_file = http_server_config["exec"]["main_file"]
        parsed_conf["main_file"] = main_file
        main_class = http_server_config["exec"]["main_class"]
        parsed_conf["main_class"] = main_class
        if "gunicorn" in http_server_config:
            parsed_conf.update(http_server_config["gunicorn"])
    except Exception as e:
        logger.error("Fail to parse cmd")
        return
    return parsed_conf


def setup_app(app, config):
    """
    Add main file and main class to app from external configuration
    """
    file_obj = import_module(config.get("main_file"))
    app.my_model = getattr(file_obj, config.get("main_class"))()
    return app


if __name__ == "__main__":
    config = parse_cmd()
    app = setup_app(app, config)
    app.run(host='0.0.0.0', port=config.get("port"), threaded=True)
