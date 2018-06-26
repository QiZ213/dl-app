# -*- coding: utf-8 -*-
import os

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
    DATA_DIR = os.path.join(PROJECT_HOME, 'data')

LOG_DIR = os.getenv('LOG_DIR')
if not LOG_DIR:
    LOG_DIR = os.path.join(PROJECT_HOME, 'log')

MODEL_DIR = os.getenv('MODEL_DIR')
if not MODEL_DIR:
    MODEL_DIR = os.path.join(PROJECT_HOME, 'models')
