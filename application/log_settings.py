# -*- coding: utf-8 -*-

import logging
import os
import time
from logging.handlers import TimedRotatingFileHandler

from .conf_settings import LOG_DIR
from .conf_settings import PROJECT_NAME, PROJECT_HOME

__all__ = [
    'logging'
    , 'cost_time'
]


def get_level():
    DEFAULT_LEVEL = logging.ERROR
    MAPPING = {
        'DEBUG': logging.DEBUG,
        'INFO': logging.INFO,
        'WARN': logging.WARNING,
        'WARNING': logging.WARNING,
        'ERROR': logging.ERROR,
        'CRITICAL': logging.CRITICAL,
        'FATAL': logging.FATAL,
    }

    user_defined_level = os.getenv('LOGGING_LEVEL')
    if not user_defined_level:
        level = DEFAULT_LEVEL
    else:
        try:
            level = MAPPING[user_defined_level.upper()]
        except KeyError:
            raise IOError('Invalid setting `LOGGING_LEVEL`, got `%s`,' \
                          '\n  Please check it from %s/scripts/common_setting.sh' \
                          % (user_defined_level, PROJECT_HOME))
    return level


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
    fh.setLevel(get_level())
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
