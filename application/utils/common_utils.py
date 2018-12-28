# -*- coding: utf-8 -*-
from functools import wraps

__all__ = ['retry']


def retry(times, logger=None):
    if not isinstance(times, int):
        raise TypeError('invalid times, should be integer')
    if times < 0:
        raise ValueError('invalid times, should be positive integer')

    def retry_func(func):
        @wraps(func)
        def wrapped(*args, **kwargs):
            if times == 1:
                return func(*args, **kwargs)
            for i in xrange(1, times + 1):
                if logger:
                    logger.debug('retry {} {} times '.format(func.__name__, i))
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if i == times:
                        raise e

        return wrapped

    return retry_func
