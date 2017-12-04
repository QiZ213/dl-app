# -*- coding: utf-8 -*-
import string

import numpy as np
import tensorflow as tf
from PIL import Image
from keras.models import model_from_json

from codes import PROJECT_HOME


class CaptchaSingleModel:
    def __init__(self, json_path, weight_path):
        self.captcha_model = model_from_json(open(json_path).read())
        self.captcha_model.load_weights(weight_path)
        self.graph = tf.get_default_graph()
        self.alphabet_list = list(string.digits + string.ascii_letters)

    def predict(self, data):
        # transpose
        img_input = np.array(data, dtype=np.float32)
        img_ar = np.zeros((44, 92, 3), dtype=np.float32)
        img_ar[3:41, 1:91] = img_input

        # reshape
        img_reshaped = img_ar.reshape(1, img_ar.shape[0], img_ar.shape[1], img_ar.shape[2])

        # predict
        with self.graph.as_default():
            class_pr = self.captcha_model.predict(img_reshaped)
            answer_list = [self.alphabet_list[i[0].argmax(axis=-1)] for i in class_pr]
            return "".join(answer_list)


class CaptchaModel:
    def __init__(self):
        self.model_10000 = CaptchaSingleModel(PROJECT_HOME + '/test_models/model_10000/10000_v3_structure.json',
                                              PROJECT_HOME + '/test_models/model_10000/10000_v3_1r_12r_best_weight.hdf5')

    def load_model(self):
        pass

    def execute(self, data, batch_size):
        results = []
        for i in range(batch_size):
            image = Image.open(data[i])
            ret = self.model_10000.predict(image)
            results.append(ret)
        return results


class CaptchaModelUCloudWrapper(CaptchaModel):
    def __init__(self, config):
        CaptchaModel.__init__(self)
        self.config = config
