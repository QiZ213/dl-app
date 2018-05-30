# -*- coding: utf-8 -*-
from base_inferencer import BaseModelResult


class ModelLog(BaseModelResult):
    SUCCESS_INFO = u'success'
    FAIL_INFO = u'fail'

    def __init__(self, data, uniq_id, info=None):
        self.Data = {}
        self.unique_id = uniq_id

        if data is not None:
            if isinstance(data, BaseModelResult) and not data.validate():
                self.info = self.FAIL_INFO
            else:
                self.Data = data
                self.info = self.SUCCESS_INFO
        else:
            self.info = info if info is not None else self.FAIL_INFO

    def validate(self):
        return self.info == ModelLog.SUCCESS_INFO
