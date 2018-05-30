# -*- coding: utf-8 -*-

from application import cost_time, logger
from .base_inferencer import BaseInferencer
from .model_log import ModelLog


class Inferencer(BaseInferencer):
    def __init__(self):
        import application.poem_model as poem_model
        self.model = poem_model

    def load_model(self):
        pass

    @staticmethod
    def validate_mark(mark):
        return True

    @cost_time(logger)
    def execute(self, data, mark, uniq_id, params):
        model_result = None
        try:
            word = params.get('word')
            result = self.model.write_poem(word)
            model_log = ModelLog(result, uniq_id)
        except Exception:
            import traceback
            error_info = traceback.format_exc()
            model_log = ModelLog(model_result, uniq_id, error_info)

        return model_log
