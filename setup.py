# -*- coding: utf-8 -*-

from setuptools import setup

setup(
    name='dl_application'
    , version='1.0.0'
    , description='helper for deep learning application'
    , packages=['application']

    , install_requires=[
        'flask'
        , 'gunicorn'
        , 'gevent'
        , 'future'
    ]
)
