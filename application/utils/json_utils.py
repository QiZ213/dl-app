# -*- coding: utf-8 -*-
import json

__all__ = [
    'dump_json'
    , 'load_json'
]


def dump_json(obj):
    """ Dump python object into json format of string.

    Args:
        obj: python object

    Returns:
        json formatted string of python object
    """

    def serialize_instance(o):
        d = {}
        d.update(vars(o))
        return d

    return json.dumps(obj, default=serialize_instance, ensure_ascii=False).encode('utf8')


def load_json(json_str, cls=None):
    """ Load json string into a python object or a dict.
    Args:
        json_str: json formatted string
        cls: python class inherited from object,
            if cls is None, this method will return a dict

    Returns:
        python object with attributes from json string
    """

    def deserialize_object(d):
        if cls:
            obj = cls.__new__(cls)
            for key, value in d.items():
                setattr(obj, key, value)
            return obj
        return d

    return json.loads(json_str, object_hook=deserialize_object)
