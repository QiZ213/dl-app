# -*- coding: utf-8 -*-
import os

__all__ = [
    'PROJECT_HOME'
    , 'PROJECT_NAME'
    , 'RESOURCE_DIR'
    , 'DATA_DIR'
    , 'LOG_DIR'
    , 'MODEL_DIR'
]


def contains_bin_or_scripts(path):
    bin_path = os.path.join(path, 'bin')
    scripts_path = os.path.join(path, 'scripts')
    return os.path.exists(bin_path) or os.path.exists(scripts_path)


PROJECT_HOME = None
search_path = os.path.abspath(os.curdir)
while os.path.basename(search_path):
    if contains_bin_or_scripts(search_path):
        PROJECT_HOME = search_path
        break
    search_path = os.path.abspath(os.path.join(search_path, os.pardir))

if not PROJECT_HOME:
    PROJECT_HOME = os.getenv('PROJECT_HOME')

if not PROJECT_HOME:
    raise IOError("Cannot find bin or scripts, "
                  + "please create folder named \"bin\" or \"scripts\" under root of your project")

PROJECT_HOME = os.path.normpath(PROJECT_HOME)
PROJECT_NAME = os.path.basename(PROJECT_HOME)
RESOURCE_DIR = os.path.join(PROJECT_HOME, 'resources')

DATA_DIR = os.getenv('DATA_DIR')
if not DATA_DIR:
    DATA_DIR = os.path.join(PROJECT_HOME, 'data')

LOG_DIR = os.getenv('LOG_DIR')
if not LOG_DIR:
    LOG_DIR = os.path.join(PROJECT_HOME, 'log')

MODEL_DIR = os.getenv('MODEL_DIR')
if not MODEL_DIR:
    MODEL_DIR = os.path.join(PROJECT_HOME, 'models')
