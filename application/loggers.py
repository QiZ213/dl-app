# -*- coding: utf-8 -*-
import json
import logging
import logging.config
import os
import time
from functools import update_wrapper

from .common_settings import *
from .configs import Configured, Config

__all__ = [
    'ConfiguredLogger'
    , 'get_logger'
    , 'cost_time'
]

DEFAULT_LOG_CONFIG_DICT = {
    'disable_existing_loggers': False,
    'version': 1,
    'formatters': {
        'default': {
            'format': '%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
            'datefmt': '%Y-%m-%d %H:%M:%S'
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'formatter': 'default',
            'class': 'logging.StreamHandler',
        },
        'error_file': {
            'level': 'ERROR',
            'formatter': 'default',
            'class': 'logging.handlers.TimedRotatingFileHandler',
            'filename': os.path.join(LOG_DIR, PROJECT_NAME),
            'when': 'midnight',
            'interval': 1,
            'backupCount': 10
        }
    },
    'root': {
        'handlers': ['console', 'error_file'],
        'level': 'ERROR'
    }
}


class ConfiguredLoggerError(Exception):
    """Raised when configured logger fails"""


class ConfiguredLogger(Configured):
    name = u'logger'

    def __init__(self, config, **kwargs):
        super(ConfiguredLogger, self).__init__(config, **kwargs)
        self.level = self.get_config('level')
        self.json_config = self.get_config('json_config')
        self.dict_config = None
        self.load()

    def load(self):
        if not self.dict_config:
            self.reload_config()

    def reload_config(self):
        try:
            if not self.json_config:
                self.dict_config = DEFAULT_LOG_CONFIG_DICT
            else:
                json_config_file = os.path.join(PROJECT_HOME, 'confs', self.json_config)
                self.dict_config = json.load(json_config_file)
            logging.config.dictConfig(self.dict_config)
        except Exception as e:
            raise ConfiguredLoggerError('fail to load from json config: {}'.format(self.json_config), e)

    def get_logger(self, logger_name):
        logger = logging.getLogger(logger_name)
        logger.setLevel(self.level)
        return logger


log_config = Config().from_dict({'logger': {'level': 'WARNING'}})
log = ConfiguredLogger(log_config)


def get_logger(logger_name):
    return log.get_logger(logger_name)


def cost_time(logger):
    def get_cost_time(func):
        def decorate(*args, **kwargs):
            start = time.time() * 1000
            result = func(*args, **kwargs)
            logger.debug('{} cost {} millis'.format(func.__name__, time.time() * 1000 - start))
            return result

        return update_wrapper(decorate, func)

    return get_cost_time
