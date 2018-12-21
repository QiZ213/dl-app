# -*- coding: utf-8 -*-
import argparse

from gunicorn.six import iteritems

from gunicorn.app.base import Application
from .flask_server import app, setup_app
from ...configs import Config


class ConfiguredApplication(Application):
    name = "gunicorn"

    def __init__(self, application, config=None, **kwargs):
        self.application = application
        self.config = config or {}
        self.config.set_section(self.name, kwargs)
        super(ConfiguredApplication, self).__init__()

    def load_config(self):
        for key, value in iteritems(self.config.get_section(self.name)):
            if key in self.cfg.settings and value is not None:
                self.cfg.set(key.lower(), value)

    def load(self):
        return setup_app(self.application, self.config)


def main():
    parser = argparse.ArgumentParser(description='service configuration parser')
    parser.add_argument("--base_json_conf", dest="base_json_conf", required=True,
                        help="indicates framework configuration file in json")
    parser.add_argument("--update_json_confs", dest="update_json_confs", required=False,
                        help="define user defined configuration files in json separated by comma")
    parser.add_argument("--port", default=8080, type=int, dest="port", help="server port")
    args = parser.parse_args()

    config = Config(args.base_json_conf)
    if args.update_json_confs:
        for update_json_conf in args.update_json_confs.split(','):
            config.from_json(update_json_conf)

    ConfiguredApplication(app, config=config, port=args.port).run()


if __name__ == "__main__":
    main()
