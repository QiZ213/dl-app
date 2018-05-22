# -*- coding: utf-8 -*-
class BaseInferencer:

    # method to initialize service
    # put works need initialization only once here
    def __init__(self):
        pass

    # method to load model
    # put works need re-initialization regularly here
    def load_model(self, *args, **kwargs):
        pass

    # method to execute inference
    def execute(self, data, mark, unique_id):
        raise NotImplementedError

    # method to validate mark of request
    def validate_mark(self, mark):
        pass
