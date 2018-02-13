# -*- coding: utf-8 -*-

import cv2
import numpy as np
from keras.models import load_model

from codes import MODEL_DIR
from codes import cost_time
from codes import logging
from codes.base_inferencer import BaseInferencer

logger = logging.getLogger(__name__)


class OCRModel:
    def __init__(self, model_path1, model_path2):
        self.model_class2 = load_model(model_path1)
        self.model_class10 = load_model(model_path2)

    # Predict fake sample to avoid keras model issues.
    # Please refer to: https://zhuanlan.zhihu.com/p/27101000
    def fake_predict(self):
        self.model_class2.predict(np.zeros(shape=(1, 215, 150, 3)))
        self.model_class10.predict(np.zeros(shape=(1, 215, 150, 3)))
        logger.info("fake print done!")

    # open img from local path, or file streaming.
    @staticmethod
    def open_img(fp):
        fp_name = ""
        if isinstance(fp, (bytes, str)) and os.path.isfile(fp):
            fp_name = fp

        if fp_name:
            return cv2.imread(fp_name)

        img_array = np.asarray(bytearray(fp.read()), dtype=np.uint8)
        return cv2.imdecode(img_array, cv2.IMREAD_COLOR)

    @cost_time(logger)
    def predict(self, img):
        # transpose
        x = self.open_img(img)
        x = cv2.resize(x, (150, 215))
        x = x / 255
        x = x.reshape((1,) + x.shape)
        pre_class2 = self.model_class2.predict(x)
        max_prob_class2 = max((pre_class2[0]))
        prediction_class2 = np.argmax((pre_class2[0]))
        if prediction_class2 == 0:
            prediction_class10 = -1
            max_prob_class10 = -1

        if prediction_class2 == 1:
            pre_class10 = self.model_class10.predict(x)
            max_prob_class10 = max((pre_class10[0]))
            prediction_class10 = np.argmax((pre_class10[0]))

        return prediction_class2, max_prob_class2, prediction_class10, max_prob_class10


class Inferencer(BaseInferencer):
    def __init__(self):
        self.model_class2_class10 = OCRModel(
            MODEL_DIR + '/Xception_model/transfer_model_Keras_Xception_class2/model_weights.h5',
            MODEL_DIR + '/Xception_model/transfer_model_Keras_Xception_class10/model_weights.h5')
        self.model_class2_class10.fake_predict()
        logger.info("init done!")

    def load_model(self):
        pass

    def execute(self, img):
        prediction_class2, max_prob_class2, prediction_class10, max_prob_class10 \
            = self.model_class2_class10.predict(img)
        ret = '{},{},{},{}'.format(prediction_class2, max_prob_class2, prediction_class10, max_prob_class10)
        return ret
