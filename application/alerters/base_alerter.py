# -*- coding: utf-8 -*-

from ..configs import Configured


class AlerterError(Exception):
    """Raised when alerter fails"""


class BaseAlerter(Configured):
    name = "alerter"

    def __init__(self, config, **kwargs):
        super(BaseAlerter, self).__init__(config, **kwargs)
        self.enabled = self.cfg.get("enabled", True)

    def is_enabled(self):
        return self.enabled

    def capture_exception(self, **kwargs):
        raise NotImplementedError

    def capture_message(self, **kwargs):
        raise NotImplementedError
