# -*- coding: utf-8 -*-
import argparse
import json
import os
from importlib import import_module

from application import dump_json, logger
from application.inferencer import Inferencer
from flask import Flask
from flask import request

app = Flask(__name__)


@app.route("/")
def hello():
    return 'Hello! Service is running'


@app.route("/service", methods=['POST'])
def do_service():
    request.get_data()
    mark = request.form.get('mark', u'empty')
    if not Inferencer.validate_mark(mark):
        return 'not assigned'
    data = request.files.get('data')
    series_num = request.form.get('serieNo', u'0')
    params = request.form.to_dict()
    result = app.my_model.execute(data, mark, series_num, params)

    # always return success status,
    # and return error message out
    return app.response_class(
        response=dump_json(result),
        status=200,
        mimetype='application/json'
    )


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
        if "service" in http_server_config:
            parsed_conf.update(http_server_config["service"])
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
