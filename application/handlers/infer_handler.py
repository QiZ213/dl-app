# -*- coding: utf-8 -*-

import time
import os

from . import BaseHandler
from application.utils.alert_utils import alert_handler

EMPTY_REQ_ID = u"0"
SUCCESS_INFO = u'success'
FAIL_INFO = u'fail'


def build_context(req_id, data, mark, params):
    app_name = os.getenv("PROJECT_NAME", "anonymous")

    data = {
        "extra": {
            "req_id": req_id,
            "data": data,
            "mark": mark,
            "params": params
        },
        "tags": {
            "app_name": app_name
        }
    }
    return data


class InferHandler(BaseHandler):

    def __init__(self, inferencer, infer_method=None):
        self.inferencer = inferencer
        if infer_method:
            self.inferencer.infer = infer_method

    def handle(self, req_id, data, mark, params):
        req_id = req_id if req_id else EMPTY_REQ_ID

        if not data:
            return "no data in request"

        try:
            metas = {}
            start = time.time() * 1000
            result = self.inferencer.infer(data, mark, params, metas)
            metas['latency'] = time.time() * 1000 - start
            model_log = ModelLog(result, req_id, metas=metas)
            return model_log
        except Exception:
            ctx = build_context(req_id, data, mark, params)
            alert_handler.captureException(**ctx)
            import traceback
            error_info = traceback.format_exc()
            model_log = ModelLog(None, req_id, info=error_info)

        return model_log


class ModelLog(object):

    def __init__(self, result, req_id, info=None, metas=None):
        self.result = {}
        self.req_id = req_id
        self.metas = metas if metas else {}

        if result is not None:
            self.result = result
            self.info = SUCCESS_INFO
        else:
            self.info = info if info else FAIL_INFO

    def validate(self):
        return self.info == SUCCESS_INFO
