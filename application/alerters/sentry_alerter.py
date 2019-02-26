# -*- coding: utf-8 -*-
import os

from .base_alerter import BaseAlerter, AlerterError


class SentryAlerter(BaseAlerter):
    _client = None

    def __init__(self, config, **kwargs):
        super(SentryAlerter, self).__init__(config, **kwargs)

        default_app_name = os.getenv("PROJECT_NAME", "anonymous")
        self.app_name = self.get_config("app_name", default_app_name)
        self.tag_ctx = {"app_name": self.app_name}

        if self.is_enabled():
            self.dsn = self.get_config("sentry_dsn")
            if not self.dsn:
                raise AlerterError("fail to get config: sentry_dsn")
            try:
                from raven import Client
                self._client = Client(self.dsn)
            except Exception as e:
                raise AlerterError("fail to init sentry client", e)

    def capture_exception(self, **kwargs):
        if self.is_enabled():
            self._client.captureException(extra=kwargs, tags=self.tag_ctx)

    def capture_message(self, message, **kwargs):
        if self.is_enabled():
            self._client.captureMessage(message, extra=kwargs, tags=self.tag_ctx)
