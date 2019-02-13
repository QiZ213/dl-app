# -*- coding: utf-8 -*-

import os

from setuptools import setup, find_packages

# set index_url of easy_install to PYPI if PYPI existed in os environment
setup_cfg_file = os.path.join(os.path.dirname(__file__), 'setup.cfg')
if not os.path.exists(setup_cfg_file) and 'PYPI' in os.environ:
    with open(setup_cfg_file, 'w') as f:
        f.write('[easy_install]\n')
        f.write('index_url = ' + os.environ['PYPI'])

setup(
    name='dl_application'
    , version='1.0.0'
    , description='helper for deep learning application'
    , packages=find_packages(exclude=["*.tests", "*.tests.*", "tests.*", "tests"])
    , install_requires=[
        'flask'
        , 'gunicorn'
        , 'gevent'
        , 'future'
        , 'requests'
        , 'raven==6.6.0'
        , 'six==1.11.0'
    ]
    , entry_points={
        'console_scripts': ['dl_service=application.service.flask.gunicorn_server:main']
    }
)
