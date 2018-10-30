# -*- coding: utf-8 -*-
"""
error tracking utils
"""

__all__ = ['alert_handler']


class BaseAlert(object):
    client_cls = None

    def __init__(self):
        self.client = None

    def init(self, config):
        if self.client_cls is None:
            return
        self.close()
        self._init_client(config)

    def _init_client(self, config):
        """
        init client_cls by extracting necessary arguments from config,
        assign a value to self.client
        Args:
            config: dict, dl-application config.

        Returns:
            None
        """
        raise NotImplementedError

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

    def _init_client(self, config):
        dsn = config.get('sentry_dsn', None)
        if dsn:
            self.client = self.client_cls(dsn)


alert_handler = SentryClient()
