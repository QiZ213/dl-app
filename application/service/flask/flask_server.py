# -*- coding: utf-8 -*-
import argparse
import json
from importlib import import_module
from inspect import isclass

from application import logging
from application.handlers.infer_handler import InferHandler
from application.utils import dump_json
from application.utils.alert_utils import alert_handler
from flask import Flask
from flask import request

app = Flask(__name__)


@app.route("/")
def hello():
    return 'Hello! Service is running'


@app.route("/service", methods=['POST'])
def serve():
    request.get_data()
    mark = request.form.get('mark')
    data = request.files.get('data')
    if not data:
        data = request.form.get('data')
    req_id = request.form.get('req_id')
    params = request.form.to_dict()
    result = app.handler.handle(req_id, data, mark, params)

    # always return success status,
    return app.response_class(
        response=dump_json(result),
        status=200,
        mimetype='application/json'
    )


def parse_cmd():
    parser = argparse.ArgumentParser(description='service configuration parser')
    parser.add_argument("--json_conf", default="json.conf", dest="json_conf", help="json configure file")
    parser.add_argument("--port", default=8080, type=int, dest="port", help="http server port")
    args = parser.parse_args()

    config = {"port": args.port}

    try:
        with open(args.json_conf) as f:
            dict_conf = json.load(f)
    except Exception as e:
        logging.error("Fail to parse json conf: {}".format(args.json_conf))
        raise e

    if "exec" not in dict_conf:
        logging.error("Fail to find exec conf")

    for key, val in dict_conf.items():
        if not isinstance(val, dict):
            raise TypeError("{} conf should be a dict".format(key))
        config.update(val)
    return config


def setup_app(flask_app, config):
    main_file = config.get("main_file")
    main_class = config.get("main_class")
    infer_method = config.get("infer_method")
    sentry_dsn = config.get("sentry_dsn")

    try:
        file_obj = import_module(main_file)
        if main_class:
            main_class = getattr(file_obj, main_class)
            if not isclass(main_class):
                logging.warn("main class should be python class")
            inferencer = main_class()
        else:
            inferencer = file_obj
        infer_method = getattr(inferencer, infer_method)

        if sentry_dsn:
            alert_handler.init(sentry_dsn)

        flask_app.handler = InferHandler(inferencer, infer_method=infer_method)
    except ImportError as e:
        logging.error("Fail to import {}".format(main_file))
        raise e
    except Exception as e:
        logging.error("Fail to init inferencer")
        raise e

    return flask_app


if __name__ == "__main__":
    parsed_config = parse_cmd()
    app = setup_app(app, parsed_config)
    app.run(host='0.0.0.0', port=parsed_config.get("port"), threaded=True)
