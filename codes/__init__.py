import os
import sys

FILE_PATH = os.path.abspath(os.path.dirname(__file__))
if FILE_PATH not in sys.path:
    sys.path.append(FILE_PATH)

PROJECT_HOME = os.path.abspath(os.path.join(FILE_PATH, os.pardir))
if PROJECT_HOME not in sys.path:
    sys.path.append(PROJECT_HOME)
