# -*- coding: utf-8 -*-
import json


def serialize_instance(obj):
    d = {}
    d.update(vars(obj))
    return d


def dump_json(obj):
    """ Dump object into json format of string

    Args:
        obj: python object

    Returns:
        json formatted string of python object
    """
    return json.dumps(obj, default=serialize_instance, ensure_ascii=False).encode('utf8')
