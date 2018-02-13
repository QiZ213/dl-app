import logging
import os
import time

# environment setting


if 'PROJECT_HOME' in os.environ:
    PROJECT_HOME = os.environ['PROJECT_HOME']
else:
    FILE_PATH = os.path.abspath(os.path.dirname(__file__))
    PROJECT_HOME = os.path.abspath(os.path.join(FILE_PATH, os.pardir))

DATA_DIR = os.path.join(PROJECT_HOME, 'data')
if not (os.path.isdir(DATA_DIR)):
    DATA_DIR = os.getenv('DATA_DIR')

LOG_DIR = os.path.join(PROJECT_HOME, 'log')
if not (os.path.isdir(LOG_DIR)):
    LOG_DIR = os.getenv('LOG_DIR')

MODEL_DIR = os.path.join(PROJECT_HOME, 'models')
if not (os.path.isdir(MODEL_DIR)):
    MODEL_DIR = os.getenv('MODEL_DIR')

# logging setting
logging.basicConfig(format='%(asctime)s %(name)-12s %(levelname)-8s %(message)s',
                    datefmt='%m-%d %H:%M')
console = logging.StreamHandler()
console.setLevel(logging.INFO)
logging.getLogger('').addHandler(console)


def cost_time(logger):
    def get_cost_time(func):
        func_name = func.__module__

        def decorate(*args, **kwargs):
            start = time.time() * 1000
            result = func(*args, **kwargs)
            logger.debug('{} cost {} millis'.format(func_name, time.time() * 1000 - start))
            return result

        return decorate

    return get_cost_time
