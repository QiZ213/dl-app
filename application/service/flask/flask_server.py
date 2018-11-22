# -*- coding: utf-8 -*-
from flask import Flask
from flask import request
from ...alerters.sentry_alerter import SentryAlerter
from ...handlers.infer_handler import InferHandler
from ...loggers import ConfiguredLogger
from ...utils import dump_json

app = Flask(__name__)


@app.route("/")
def hello():
    return 'Hello! Service is running'


@app.route("/hs")
def health_status():
    return "OK"


@app.route("/service", methods=['POST'])
def serve():
    request.get_data()
    mark = request.form.get('mark')
    data = request.files.get('data')
    if not data:
        data = request.form.get('data')
    req_id = request.form.get('req_id')
    params = request.form.to_dict()
    try:
        result = app.handler.handle(req_id, data, mark, params)
    except Exception:
        app.alerter.capture_exception(req_id=req_id, data=data, mark=mark, params=params)
        import traceback
        error_info = traceback.format_exc()
        result = app.handler.fail(req_id, error_info)

    # always return success status,
    return app.response_class(
        response=dump_json(result),
        status=200,
        mimetype='application/json'
    )


def setup_app(application, config):
    application.alerter = SentryAlerter(config)
    application.handler = InferHandler(config)
    ConfiguredLogger(config).reload_config()
    return application
