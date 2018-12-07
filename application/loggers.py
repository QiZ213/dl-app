# -*- coding: utf-8 -*-
import logging
import os
import time
from functools import update_wrapper
from logging.handlers import TimedRotatingFileHandler

from .common_settings import LOG_DIR, PROJECT_NAME
from .configs import Configured, Config

__all__ = [
    'logging'
    , 'cost_time'
    , 'ConfiguredLogger'
]

LOG_LEVEL = {
    u'debug': logging.DEBUG
    , u'info': logging.INFO
    , u'warning': logging.WARNING
    , u'error': logging.ERROR
    , u'critical': logging.CRITICAL
}
MSG_FMT = u'%(asctime)s %(name)-12s %(levelname)-8s %(message)s'
DT_FMT = u'%m-%d %H:%M:%S'
LOG_FILE_SUFFIX = u'%Y_%m_%d.log'
logging.basicConfig(level=logging.INFO, format=MSG_FMT, datefmt=DT_FMT)


def cost_time(logger):
    def get_cost_time(func):
        def decorate(*args, **kwargs):
            start = time.time() * 1000
            result = func(*args, **kwargs)
            logger.debug('{} cost {} millis'.format(func.__name__, time.time() * 1000 - start))
            return result

        return update_wrapper(decorate, func)

    return get_cost_time


class ConfiguredLoggerError(Exception):
    """Raised when configured logger fails"""


class ConfiguredLogger(Configured):
    name = u'logger'

    def __init__(self, config, **kwargs):
        super(ConfiguredLogger, self).__init__(config, **kwargs)
        self.logger_level = self.get_level(self.get_config(u'logger_level', u'info'))
        self.log_dir = self.get_config(u'log_dir', LOG_DIR)
        self.log_file = self.get_config(u'log_file', PROJECT_NAME)
        self.log_file_enabled = self.get_config(u'log_file_enabled', False)
        self.log_file_level = self.get_config(u'log_file_level', u'error')
        self.log_file_handler = self._init_file_handler()

    def get_level(self, level_in_str):
        try:
            level = LOG_LEVEL[level_in_str]
            return level
        except Exception as e:
            raise ConfiguredLoggerError(
                'invalid log type: {}, should be: {}'.format(self.logger_level, LOG_LEVEL.keys()), e)

    def _init_file_handler(self):
        log_file_handler = None
        if self.log_dir and self.log_file and os.path.isdir(self.log_dir):
            try:
                log_file_handler = TimedRotatingFileHandler(os.path.join(self.log_dir, self.log_file)
                                                            , when='midnight'
                                                            , interval=1
                                                            , backupCount=10)
                log_file_handler.setLevel(self.log_file_error)
                log_file_handler.setFormatter(logging.Formatter(MSG_FMT, DT_FMT))
                log_file_handler.suffix = LOG_FILE_SUFFIX
            except Exception as e:
                raise ConfiguredLoggerError('Could not initial log file: {}/{}'.format(self.log_dir, LOG_LEVEL.keys()),
                                            e)
        if self.log_file_enabled and not log_file_handler:
            raise ConfiguredLoggerError('Log file handler should be ready')
        return log_file_handler

    def get_logger(self, logger_name=None):
        logger = logging.getLogger(logger_name) if logger_name else logging.getLogger()
        logger.setLevel(self.logger_level)
        if self.log_file_enabled:
            logger.addHandler(self.log_file_handler)
        return logger

    def reload_config(self):
        self.get_logger()


default_config = Config().set_section("logger", {})
ConfiguredLogger(default_config).reload_config()
