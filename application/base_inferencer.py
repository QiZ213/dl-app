# -*- coding: utf-8 -*-
class BaseInferencer:

    # method to initialize service
    # put works need initialization only once here
    def __init__(self, *args, **kwargs):
        pass

    # method to validate mark of request
    @staticmethod
    def validate_mark(mark):
        pass

    # method to load model
    # put works need re-initialization regularly here
    def load_model(self, *args, **kwargs):
        pass

    # method to execute inference
    def execute(self, data, mark, unique_id, params):
        raise NotImplementedError


class BaseModelResult:

    def __init__(self, *args, **kwargs):
        pass

    # method to check the result is successful or not

    def validate(self):
        raise NotImplementedError
