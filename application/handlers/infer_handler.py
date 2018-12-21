# -*- coding: utf-8 -*-

import time
from importlib import import_module
from inspect import isclass

from .base_handler import BaseHandler, HandlerError
from ..handlers import *


class InferHandler(BaseHandler):

    def __init__(self, config, **kwargs):
        super(BaseHandler, self).__init__(config, **kwargs)
        main_file = self.get_config("main_file")
        main_class = self.get_config("main_class")
        infer_method = self.get_config("infer_method")
        try:
            file_obj = import_module(main_file)
            if main_class:
                inferencer_class = getattr(file_obj, main_class)
                if not isclass(inferencer_class):
                    raise TypeError('{} not a python class'.format(main_class))
                inferencer = inferencer_class()
            else:
                inferencer = file_obj
            self.inferencer = inferencer
            self.inferencer.infer = getattr(inferencer, infer_method)
        except Exception as e:
            raise HandlerError("Fail to init infer handler from module: {}, class: {}, method: {}".format(
                main_file, main_class, infer_method), e)

    def handle(self, req_id, data, mark, params):
        req_id = req_id if req_id else EMPTY_REQ_ID
        metas = {}
        start = time.time() * 1000
        result = self.inferencer.infer(data, mark, params, metas)
        metas['latency'] = time.time() * 1000 - start
        return ModelLog(result, req_id, metas=metas)

    def fail(self, req_id, error_info):
        return ModelLog(None, req_id, info=error_info)


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
