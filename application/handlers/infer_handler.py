# -*- coding: utf-8 -*-

import time

from . import BaseHandler

EMPTY_REQ_ID = u"0"
SUCCESS_INFO = u'success'
FAIL_INFO = u'fail'


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
