# -*- coding: utf-8 -*-
import os
import traceback

import cv2
import numpy as np

import url_utils

__all__ = [
    'read_img_by_cv2'
    , 'write_img_by_cv2'
    , 'read_imgs_by_cv2'
]

DEFAULT_TIMEOUT = (0.1, 1)
SEPARATOR = ','


def read_imgs_by_cv2(fps, timeout=DEFAULT_TIMEOUT, params=None):
    """

    Args:
        fps: comma-separated filename,
             comma-separated url address,
             byte streaming,
             ndarray_bytes with comma-separated shape in params
        timeout: timeout for reading image from url, by default is 1s each url
        params: None or dict contains comma-separated shape of ndarray_bytes and dtype of ndarray_bytes,

    Returns: list of image array. if catch exception with I/O, the image is replaced by None.

    """

    params = params if params is not None else {}

    if hasattr(fps, 'read'):
        if params.get('shape'):
            fps_to_img_list = array_bytes_to_img_list
        else:
            fps_to_img_list = file_like_to_img_list
    elif isinstance(fps, (bytes, str, unicode)):
        if fps.startswith(u'http://') or fps.startswith(u'https://'):
            fps_to_img_list = urls_to_img_list
        else:
            fps_to_img_list = pathes_to_img_list
    else:
        raise TypeError('Failed to read images from unsupported type')

    img_list = fps_to_img_list(fps, timeout, params)
    return img_list


def array_bytes_to_img_list(fps, timeout, params):
    dtype = params.get('dtype', 'uint8')
    shape = params.get('shape')
    shape = [int(i) for i in shape.split(SEPARATOR)]
    if len(shape) not in [3, 4]:
        raise TypeError('Dimension of image array expects 3 or 4',
                        ', got ({!r})'.format(len(shape)))

    array_bytes = fps.read()
    array = np.frombuffer(array_bytes, dtype=np.dtype(dtype))
    array = array.reshape(shape)
    if len(shape) == 3:
        return [array]
    else:
        return [a for a in array]


def file_like_to_img_list(fps, timeout=None, params=None):
    img_array = np.asarray(bytearray(fps.read()), dtype=np.uint8)
    img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    return [cv2.cvtColor(img, cv2.COLOR_BGR2RGB)]


def pathes_to_img_list(fps, timeout=None, params=None):
    path_list = fps.split(SEPARATOR)
    img_list = []
    for path in path_list:
        try:
            img = cv2.imread(path)
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        except Exception:
            traceback.print_exc()
            img = None
        img_list.append(img)
    return img_list


def urls_to_img_list(fps, timeout, params=None):
    url_list = fps.split(SEPARATOR)
    img_list = []
    for url in url_list:
        try:
            bytes = url_utils.urlopen(url, timeout=timeout)
            img = file_like_to_img_list(bytes)[0]
        except Exception:
            traceback.print_exc()
            img = None
        img_list.append(img)
    return img_list


def read_img_by_cv2(fp, timeout=DEFAULT_TIMEOUT):
    """ read image as opencv formatted image

    Args:
        fp: file name, url address or byte streaming
        timeout: timeout for reading image from url, by default is 1s

    Returns:
        opencv formatted image
    """
    img_list = read_imgs_by_cv2(fp, timeout=timeout)
    if len(img_list) == 0 or img_list[0] is None:
        raise IOError('can not read image from {!r}'.format(fp))
    return img_list[0]


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
