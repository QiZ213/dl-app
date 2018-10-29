# -*- coding: utf-8 -*-
"""
error tracking utils
"""

__all__ = ['alert_handler']


class BaseAlert(object):
    client_cls = None

    def __init__(self):
        self.client = None

    def init(self, *args, **kwargs):
        if self.client_cls is None:
            return
        self.close()
        self.client = self.client_cls(*args, **kwargs)

    def close(self):
        self.client = None

    def captureException(self, *args, **kwargs):
        if self.client is None:
            return
        self.client.captureException(*args, **kwargs)

    def captureMessage(self, *args, **kwargs):
        if self.client is None:
            return
        self.client.captureMessage(*args, **kwargs)


class SentryClient(BaseAlert):
    try:
        from raven import Client
        client_cls = Client
    except ImportError:
        client_cls = None


alert_handler = SentryClient()
