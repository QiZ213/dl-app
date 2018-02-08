import logging
import os
import sys
import time

# environment setting
FILE_PATH = os.path.abspath(os.path.dirname(__file__))
if FILE_PATH not in sys.path:
    sys.path.append(FILE_PATH)

PROJECT_HOME = os.path.abspath(os.path.join(FILE_PATH, os.pardir))
if PROJECT_HOME not in sys.path:
    sys.path.append(PROJECT_HOME)

DATA_DIR = os.environ.get('DATA_DIR', PROJECT_HOME + '/data')
LOG_DIR = os.environ.get('LOG_DIR', PROJECT_HOME + '/log')
MODEL_DIR = os.environ.get('MODEL_DIR', PROJECT_HOME + '/models')

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
