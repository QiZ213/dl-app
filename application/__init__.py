import json
import logging
import os
import time
from logging.handlers import TimedRotatingFileHandler

# environment setting
if 'PROJECT_HOME' in os.environ:
    PROJECT_HOME = os.environ['PROJECT_HOME']
else:
    FILE_PATH = os.path.abspath(os.path.dirname(__file__))
    PROJECT_HOME = os.path.abspath(os.path.join(FILE_PATH, os.pardir))
PROJECT_HOME = os.path.normpath(PROJECT_HOME)

PROJECT_NAME = os.path.basename(PROJECT_HOME)
RESOURCE_DIR = os.path.join(PROJECT_HOME, 'resources')

DATA_DIR = os.getenv('DATA_DIR')
if not DATA_DIR:
    DATA_DIR = os.path.join(PROJECT_HOME, 'io')

LOG_DIR = os.getenv('LOG_DIR')
if not LOG_DIR:
    LOG_DIR = os.path.join(PROJECT_HOME, 'log')

MODEL_DIR = os.getenv('MODEL_DIR')
if not MODEL_DIR:
    MODEL_DIR = os.path.join(PROJECT_HOME, 'models')

# logging setting
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
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


def get_timestamp():
    return str(int(time.time()))


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
