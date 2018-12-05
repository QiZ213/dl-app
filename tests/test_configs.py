# -*- coding: utf-8 -*-

import os
import unittest

try:
    import mock as mock
except ImportError:
    import unittest.mock as mock
from application.configs import Config, Configured
from application.configs import NoSectionError

TEST_CONFIG = {
    "str_config": "a"
    , "bool_config": False
    , "int_config": 0
    , "float_config": 0.0
    , "empty_config": ""
    , "none_config": None
    , "raw_config": "raw"
}

UPDATE_CONFIG = {
    "str_config": "b"
    , "bool_config": True
    , "int_config": 1
    , "float_config": 0.1
    , "empty_config": "not empty now"
    , "none_config": "not none now"
    , "new_config": "new"
}


class TestConfig(unittest.TestCase):

    def test_init_config_from_json(self):
        current_dir = os.path.dirname(os.path.abspath(__file__))
        cfg = Config(json_conf=os.path.join(current_dir, "resources", "conf.json"))
        self.assertEqual({"main_class": "", "main_file": "", "infer_method": ""}, cfg.get_section("exec"))

    def test_init_config_from_dict(self):
        cfg = Config().from_dict({"section": TEST_CONFIG})
        self.assertEqual(TEST_CONFIG, cfg.get_section("section"))

    @staticmethod
    def _init_config():
        return Config().from_dict({"section": TEST_CONFIG})

    def test_has_section_should_return_true(self):
        cfg = self._init_config()
        self.assertTrue(cfg.has_section("section"))

    def test_has_section_should_return_false(self):
        cfg = self._init_config()
        self.assertFalse(cfg.has_section("not existed"))

    def test_get_section_should_raise_exception(self):
        cfg = self._init_config()
        with self.assertRaises(NoSectionError):
            cfg.get_section("not existed")

    def test_get_section_should_be_immutable(self):
        cfg = self._init_config()
        self.assertEqual(TEST_CONFIG, cfg.get_section("section"))
        raw = cfg.get_section("section")
        raw["new_config"] = "new"
        self.assertEqual(TEST_CONFIG, cfg.get_section("section"))

    def test_get_config_should_raise_exception(self):
        cfg = self._init_config()
        with self.assertRaises(NoSectionError):
            cfg.get_config("not existed", "str_config")

    def test_get_config_should_return_value(self):
        cfg = self._init_config()
        self.assertEqual("a", cfg.get_config("section", "str_config"))

    def test_get_config_should_return_default(self):
        cfg = self._init_config()
        self.assertEqual("default", cfg.get_config("section", "not existed", "default"))

    def test_set_new_section_should_update(self):
        cfg = self._init_config()
        new_config_dict = {"new_name": "new_value"}
        cfg.set_section("new_config", new_config_dict)
        self.assertEqual(new_config_dict, cfg.get_section("new_config"))

    def test_overwrite_old_section_should_update(self):
        cfg = self._init_config()
        cfg.set_section("section", UPDATE_CONFIG)
        expected_section_config_dict = {
            "str_config": "b"
            , "bool_config": True
            , "int_config": 1
            , "float_config": 0.1
            , "empty_config": "not empty now"
            , "none_config": "not none now"
            , "raw_config": "raw"
            , "new_config": "new"
        }
        self.assertEqual(expected_section_config_dict, cfg.get_section("section"))

    def test_complete_old_section_should_update(self):
        cfg = self._init_config()
        cfg.set_section("section", UPDATE_CONFIG, False)
        expected_section_config_dict = {
            "str_config": "a"
            , "bool_config": False
            , "int_config": 0
            , "float_config": 0.0
            , "empty_config": "not empty now"
            , "none_config": "not none now"
            , "raw_config": "raw"
            , "new_config": "new"
        }
        self.assertEqual(expected_section_config_dict, cfg.get_section("section"))

    def test_overwrite_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "str_config", "b")
        self.assertEqual("b", cfg.get_config("section", "str_config"))

    def test_complete_config_with_new_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "new_config", "new", False)
        self.assertEqual("new", cfg.get_config("section", "new_config"))

    def test_complete_config_with_empty_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "empty_config", "not empty any more", False)
        self.assertEqual("not empty any more", cfg.get_config("section", "empty_config"))

    def test_complete_config_with_none_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "none_config", "not none any more", False)
        self.assertEqual("not none any more", cfg.get_config("section", "none_config"))

    def test_complete_config_with_false_config_should_not_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "bool_config", True, False)
        self.assertEqual(False, cfg.get_config("section", "bool_config"))

    def test_complete_config_with_zero_config_should_not_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "int_config", 1, False)
        self.assertEqual(0, cfg.get_config("section", "int_config"))

    def test_complete_config_with_existed_config_should_not_update(self):
        cfg = self._init_config()
        cfg.set_config("section", "str_config", "b", False)
        self.assertEqual("a", cfg.get_config("section", "str_config"))


class TestConfigured(unittest.TestCase):

    def test_get_config_should_return_config_value(self):
        cmpt = Configured(Config().set_section("dummy", {"config_name": "config_value"}))
        self.assertEqual("config_value", cmpt.get_config("config_name", "default_value"))

    def test_get_config_should_return_default_value(self):
        cmpt = Configured(Config().set_section("dummy", {"config_name": "config_value"}))
        self.assertEqual("default_value", cmpt.get_config("not_existed_config_name", "default_value"))

    def test_get_config_should_return_param_value(self):
        cmpt = Configured(Config().set_section("dummy", {"config_name": "config_value"}), config_name="param_value")
        self.assertEqual("param_value", cmpt.get_config("config_name"))

    @mock.patch('os.getenv', new={"dummy_os_config_name": "os_config_value"}.get, spec_set=True)
    def test_get_config_should_return_os_value(self):
        cmpt = Configured(Config().set_section("dummy", {"config_name": "config_value"}))
        self.assertEqual("os_config_value", cmpt.get_config("os_config_name"))

    @mock.patch('os.getenv', new={"dummy_os_config_name": "os_config_value"}.get, spec_set=True)
    def test_get_config_should_return_none(self):
        cmpt = Configured(Config().set_section("dummy", {"config_name": "config_value"}))
        self.assertIsNone(cmpt.get_config("not_existed_config_name"))
