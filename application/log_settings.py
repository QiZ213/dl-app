# -*- coding: utf-8 -*-

import logging
import os
from logging.handlers import TimedRotatingFileHandler

import time

from conf_settings import LOG_DIR
from conf_settings import PROJECT_NAME

# logging setting
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M')

fh = TimedRotatingFileHandler(os.path.join(LOG_DIR, PROJECT_NAME), when='midnight')
fh.suffix = '%Y_%m_%d.log'
logger = logging.getLogger(PROJECT_NAME)
logger.addHandler(fh)


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
