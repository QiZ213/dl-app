# -*- coding: utf-8 -*-
__all__ = [
    'read_img_by_cv2'
    , 'write_img_by_cv2'
]

import os

import cv2
import numpy as np

import url_utils


def read_img_by_cv2(fp, timeout=1):
    """ read image as opencv formatted image

    Args:
        fp: file name, url address or byte streaming

    Returns:
        opencv formatted image
    """
    fp_name = ""
    if isinstance(fp, (bytes, str, unicode)):
        if fp.startswith(u'http://') or fp.startswith(u'https://'):
            fp = url_utils.urlopen(fp, timeout=timeout)
        elif os.path.isfile(fp):
            fp_name = fp

    if fp_name:
        img = cv2.imread(fp_name)
    else:
        img_array = np.asarray(bytearray(fp.read()), dtype=np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)


def write_img_by_cv2(data, base_dir, file_name, check_path=False):
    """ write down object of image to specified path

    Args:
        data: object of image
        base_dir: base dir to store image
        file_name: file name of image to be written
        check_path: whether need to check existence of base dir

    Returns:
        file path of written image
    """
    if check_path and not os.path.isdir(base_dir):
        raise IOError('{} is not dir'.format(base_dir))
    file_path = os.path.join(base_dir, file_name)
    data = cv2.cvtColor(data, cv2.COLOR_RGB2BGR)
    cv2.imwrite(file_path, data)
    return file_path
