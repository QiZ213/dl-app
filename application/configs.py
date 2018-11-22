# -*- coding: utf-8 -*-
import json
import os


class ConfigLoadError(Exception):
    """Raised when config file loading failed"""


class NoSectionError(Exception):
    """Raised when cannot find section in config"""


class Config(object):
    PREFIX_SEPARATOR = '_'

    def __init__(self, json_conf=None):
        self._sections = {}
        if json_conf:
            self.from_json(json_conf)

    def from_json(self, file_path, overwrite=True):
        try:
            with open(file_path) as f:
                json_obj = json.loads(f.read())
        except Exception as e:
            raise IOError("fail to load json conf file: {}".format(file_path), e)
        return self.from_dict(json_obj, overwrite)

    def from_dict(self, dictionary, overwrite=True):
        for section, section_dict in dictionary.items():
            try:
                section = str(section)
                self.set_section(section, section_dict, overwrite)
            except Exception as e:
                raise ConfigLoadError("fail to load section: {}".format(section), e)
        return self

    def sections(self):
        return self._sections

    def has_section(self, section):
        return section in self._sections

    def get_section(self, section):
        if not self.has_section(section):
            raise NoSectionError("cannot find {}".format(section))
        return self._sections[section].copy()

    def get_config(self, section, name, default=None):
        if not self.has_section(section):
            raise NoSectionError("cannot find {}".format(section))
        return self._sections[section].get(name, default)

    def set_section(self, section, dictionary, overwrite=True):
        section_dict = self._sections.setdefault(section, {})
        if overwrite:
            updated = dictionary
        else:
            updated = {k: v for k, v in dictionary.items() if k not in section_dict or not section_dict[k]}
        section_dict.update(updated)
        return self

    def set_config(self, section, name, value, overwrite=True):
        section_dict = self._sections.setdefault(section, {})
        if overwrite or name not in section_dict or not section_dict[name]:
            section_dict[name] = value
        return self

    def __str__(self):
        return self._sections.__str__()


class Configured(object):
    cfg = {}
    name = "dummy"

    def __init__(self, config, **kwargs):
        self.cfg = config.get_section(self.name)
        self.cfg.update(kwargs)

    def get_config(self, name, default_value=None):
        val = self.cfg.get(name, default_value)
        if not val:
            val = os.getenv(self.name + '_' + name)
        return val
