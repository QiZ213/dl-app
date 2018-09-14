# -*- coding: utf-8 -*-

from setuptools import setup, find_packages

print(find_packages())
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
    ]
    , entry_points={
        'console_scripts': ['dl_service=application.service.flask.gunicorn_server:main']
    }
)
