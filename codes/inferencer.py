# -*- coding: utf-8 -*-

import time

from base_inferencer import BaseInferencer
from codes import DATA_DIR
from codes import cost_time
from codes import logger
from codes.data.image import Image


class ModelLog:
    SUCCESS_INFO = u'success'
    FAIL_INFO = u'fail'

    def __init__(self, data, uniq_id, info=None):
        self.Data = {}
        self.uniq_id = uniq_id

        if data is not None:
            if data.validate():
                self.Data = data
                self.info = self.SUCCESS_INFO
            else:
                self.info = self.FAIL_INFO
        else:
            self.info = info if info is not None else self.FAIL_INFO

    def is_success(self):
        return self.info == ModelLog.SUCCESS_INFO


class Inferencer(BaseInferencer):
    def __init__(self):
        # this.model = model
        pass

    def load_model(self):
        pass

    @staticmethod
    def validate_mark(mark):
        return True

    @cost_time(logger)
    def execute(self, data, mark, uniq_id):
        model_result = None
        try:
            img_by_cv2 = Image(data, Image.BY_CV2)
            # model_result = self.model.predict(img_by_cv2.img)
            file_name = str(uniq_id) + '_' + str(int(time.time())) + '.jpg'
            img_by_cv2.write_img(DATA_DIR, file_name)
        except Exception:
            import traceback
            error_info = traceback.format_exc()
            model_log = ModelLog(model_result, uniq_id, error_info)

        return model_log
