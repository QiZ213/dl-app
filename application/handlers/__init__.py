# -*- coding: utf-8 -*-
class BaseHandler:

    def __init__(self, *args, **kwargs):
        """
        Method to initialize handler, will be executed only once.
        """
        pass

    def reload(self, *args, **kwargs):
        """
        Method to reload configurations of handler, will be executed regularly.
        """
        pass

    def handle(self, *args, **kwargs):
        """
        Method to handle request, will be executed for every request.
        """
        raise NotImplementedError
