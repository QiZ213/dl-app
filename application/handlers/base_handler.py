# -*- coding: utf-8 -*-
from ..configs import Configured


class HandlerError(Exception):
    """Raised when handler fails"""


class BaseHandler(Configured):
    name = "handler"

    def handle(self, *args, **kwargs):
        """
        Method to handle request, will be executed for every request.
        """
        raise NotImplementedError

    def fail(self, *args, **kwargs):
        """
        Method to call when handle fails
        """
        pass
