# -*- coding: utf-8 -*-

import logging
import os
import time
from logging.handlers import TimedRotatingFileHandler

from .conf_settings import LOG_DIR
from .conf_settings import PROJECT_NAME

__all__ = [
    'logging'
    , 'cost_time'
]


_level = os.getenv('LOGGING_LEVEL') or 'ERROR'
LEVEL = logging.getLevelName(_level.upper())

# logging setting

logging.basicConfig(level=logging.INFO
                    , format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s'
                    , datefmt='%m-%d %H:%M:%S')
formatter = logging.Formatter('%(asctime)s %(name)-12s %(levelname)-8s %(message)s'
                              , '%m-%d %H:%M:%S')
root = logging.getLogger()
if os.path.isdir(LOG_DIR):
    fh = TimedRotatingFileHandler(os.path.join(LOG_DIR, PROJECT_NAME)
                                  , when='midnight'
                                  , interval=1
                                  , backupCount=10)
    fh.setLevel(LEVEL)
    fh.setFormatter(formatter)
    fh.suffix = '%Y_%m_%d.log'
    root.addHandler(fh)


def cost_time(logger):
    def get_cost_time(func):
        func_name = func.__name__

        def decorate(*args, **kwargs):
            start = time.time() * 1000
            result = func(*args, **kwargs)
            logger.debug('{} cost {} millis'.format(func_name, time.time() * 1000 - start))
            return result

        return decorate

    return get_cost_time
