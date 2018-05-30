# -*- coding: utf-8 -*-
import os

import cv2
import numpy as np

from application import cost_time, logger


class Image:
    BY_CV2 = u'cv2'
    IMAGE_PROCESSING_METHODS = [BY_CV2]

    def __init__(self, fp, tag):
        if tag not in self.IMAGE_PROCESSING_METHODS:
            raise NotImplementedError('un-supported image processing method :{}'.format(tag))
        self.tag = tag
        self.img = self.read_img(fp)

    @cost_time(logger)
    def read_img(self, fp):
        if self.tag == self.BY_CV2:
            return self.read_img_by_cv2(fp)

    @cost_time(logger)
    def write_img(self, base_dir, file_name, check_path=False):
        if self.img is None:
            raise IOError('No image loaded')
        if self.tag == self.BY_CV2:
            self.write_img_by_cv2(self.img, base_dir, file_name, check_path)

    @staticmethod
    def read_img_by_cv2(fp):
        """ read file or byte streaming to opencv formatted image

        Args:
            fp: file name or streaming

        Returns:
            opencv formatted image
        """
        fp_name = ""
        if isinstance(fp, (bytes, str)) and os.path.isfile(fp):
            fp_name = fp

        if fp_name:
            img = cv2.imread(fp_name)
        else:
            img_array = np.asarray(bytearray(fp.read()), dtype=np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    @staticmethod
    def write_img_by_cv2(data, base_dir, file_name, check_path=False):
        """ write byte streaming to local

        Args:
            data: image file
            base_dir: base dir of image file to store
            file_name: file name of image file to store
            check_path: whether need to check dir existence

        Returns:

        """
        if check_path and not os.path.isdir(base_dir):
            raise IOError('{} is not dir'.format(base_dir))
        file_path = os.path.join(base_dir, file_name)
        cv2.imwrite(file_path, data)
