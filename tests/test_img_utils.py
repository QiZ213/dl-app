# -*- coding: utf-8 -*-

import sys
import os
import unittest
from io import BytesIO

import numpy as np

PROJECT_HOME = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(PROJECT_HOME, 'application'))
from application.utils import read_imgs_by_cv2
from application.utils import read_img_by_cv2


IMAGE_PATH = os.path.join(PROJECT_HOME, 'tests/resources/dog.jpg')
COMMA_SEP_IMG_PATH = ','.join([IMAGE_PATH] * 2)
IMAGE_PATH_CONTAINS_ERROR = ','.join([IMAGE_PATH, 'not_existed', IMAGE_PATH])

IMAGE_URL = 'http://paifenle-tars-faces.oss-cn-shanghai.aliyuncs.com/images/b45dd875-f573-4ec9-8509-15fd1bee4e8c_face_3.jpg'
COMMA_SEP_IMG_URL = ','.join([IMAGE_URL] * 2)
IMAGE_URL_CONTAINS_ERROR = ','.join([IMAGE_URL, 'http://not_exist', IMAGE_URL])


def array_to_bytes(array):
    shape = array.shape
    dtype_name = array.dtype.name
    array_bytes = BytesIO(array.tobytes())
    return array_bytes, shape, dtype_name


class TestReadImgs(unittest.TestCase):

    def __test_single_img_should_be_valid(self, img_list):
        self.assertEqual(len(img_list), 1)
        self.assertIsInstance(img_list[0], np.ndarray)
        self.assertGreater(img_list[0].size, 0)

    def __test_multi_img_should_be_valid(self, img_list):
        self.assertEqual(len(img_list), len(COMMA_SEP_IMG_PATH.split(',')))
        self.assertTrue(all(isinstance(i, np.ndarray) for i in img_list))

    def __test_contains_error(self, img_list):
        self.assertEqual(len(img_list), len(IMAGE_PATH_CONTAINS_ERROR.split(',')))

        self.assertIsInstance(img_list[0], np.ndarray)
        self.assertIs(img_list[1], None)  # from error path, is replaced by None
        self.assertIsInstance(img_list[2], np.ndarray)

    def __test_read_array_bytes(self, shape_type='list'):
        origin_img_list = read_imgs_by_cv2(COMMA_SEP_IMG_PATH)
        batch_img = np.array(origin_img_list)

        array_bytes, shape, dtype = array_to_bytes(batch_img)
        if shape_type == 'list':
            pass
        elif shape_type == 'string':
            shape = ','.join(str(i) for i in shape)
        else:
            raise TypeError('Invalid shape_type')

        img_list = read_imgs_by_cv2(array_bytes, params={'shape': shape, 'dtype': dtype})
        for old, new in zip(origin_img_list, img_list):
            self.assertTrue((old == new).all())

    def test_read_single_url(self):
        img_list = read_imgs_by_cv2(IMAGE_URL)
        self.__test_single_img_should_be_valid(img_list)

    def test_read_urls(self):
        img_list = read_imgs_by_cv2(COMMA_SEP_IMG_URL)
        self.__test_multi_img_should_be_valid(img_list)

    def test_read_urls_contains_error(self):
        img_list = read_imgs_by_cv2(IMAGE_URL_CONTAINS_ERROR)
        self.__test_contains_error(img_list)

    def test_read_single_path(self):
        img_list = read_imgs_by_cv2(IMAGE_PATH)
        self.__test_single_img_should_be_valid(img_list)

    def test_read_pathes(self):
        img_list = read_imgs_by_cv2(COMMA_SEP_IMG_PATH)
        self.__test_multi_img_should_be_valid(img_list)

    def test_read_pathes_contains_error(self):
        img_list = read_imgs_by_cv2(IMAGE_PATH_CONTAINS_ERROR)  # can print exception traceback
        self.__test_contains_error(img_list)

    def test_read_array_bytes(self):
        self.__test_read_array_bytes(shape_type='list')
        self.__test_read_array_bytes(shape_type='string')

    def test_read_bytes(self):
        with open(IMAGE_PATH, 'rb') as f:
            img_list = read_imgs_by_cv2(f)
            self.__test_single_img_should_be_valid(img_list)

        img_list_from_path = read_imgs_by_cv2(IMAGE_PATH)
        for old, new in zip(img_list_from_path, img_list):
            self.assertTrue((old == new).all())

    def test_read_from_unsupported_type(self):
        with self.assertRaises(Exception):  # None is unsupported
            read_imgs_by_cv2(None)

        with self.assertRaises(Exception):  # list is unsupported
            read_imgs_by_cv2([IMAGE_PATH] * 4)

    def test_read_array_bytes_error(self):
        invalid_dimension_array = np.ones(10)  # dimension of array is not 3 or 4
        array_bytes, shape, dtype = array_to_bytes(invalid_dimension_array)
        with self.assertRaises(TypeError):
            read_imgs_by_cv2(array_bytes, params={'shape': shape, 'dtype': dtype})


class TestReadImg(unittest.TestCase):
    def __test_valid_img(self, img):
        self.assertIsInstance(img, np.ndarray)
        self.assertGreater(img.size, 0)

    def test_read_img(self):
        self.__test_valid_img(read_img_by_cv2(IMAGE_URL))  # from url
        self.__test_valid_img(read_img_by_cv2(IMAGE_PATH))  # from path

        with open(IMAGE_PATH, 'rb') as f:
            self.__test_valid_img(read_img_by_cv2(f))  # from file-like

    def test_read_error_img(self):
        error_img_path = 'not_existed'
        with self.assertRaises(IOError):
            read_img_by_cv2(error_img_path)


if __name__ == '__main__':
    unittest.main()
