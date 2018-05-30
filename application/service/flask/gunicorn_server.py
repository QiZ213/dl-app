# -*- coding: utf-8 -*-
from flask_server import app
from flask_server import parse_cmd
from flask_server import setup_app
from gunicorn.app.base import Application
from gunicorn.six import iteritems


class ConfiguredApplication(Application):
    def __init__(self, application, config=None):
        self.application = application
        self.config = config or {}
        super(ConfiguredApplication, self).__init__()

    def init(self, parser, opts, args):
        pass

    def load_config(self):
        for key, value in iteritems(self.config):
            if key in self.cfg.settings and value is not None:
                self.cfg.set(key.lower(), value)

    def load(self):
        self.application = setup_app(app, config)
        return self.application


if __name__ == "__main__":
    config = parse_cmd()
    ConfiguredApplication(app, config=config).run()
