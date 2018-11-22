# -*- coding: utf-8 -*-

import os
import unittest

try:
    import mock as mock
except ImportError:
    import unittest.mock as mock
from application.configs import Config, Configured
from application.configs import NoSectionError


class TestConfig(unittest.TestCase):

    def test_init_config_from_json(self):
        cfg = Config(json_conf=os.path.join("tests/resources", "conf.json"))
        self.assertEqual({"main_class": "", "main_file": "", "infer_method": ""}, cfg.get_section("exec"))

    def test_init_config_from_dict(self):
        cfg = Config().from_dict({"exec": {"main_class": "inferencer"}})
        self.assertEqual({"main_class": "inferencer"}, cfg.get_section("exec"))

    @staticmethod
    def _init_config():
        return Config().from_dict({"exec": {"main_class": "inferencer", "main_file": "", "infer_method": ""}})

    def test_has_section_should_return_true(self):
        cfg = self._init_config()
        self.assertTrue(cfg.has_section("exec"))

    def test_has_section_should_return_false(self):
        cfg = self._init_config()
        self.assertFalse(cfg.has_section("not existed"))

    def test_get_section_should_raise_exception(self):
        cfg = self._init_config()
        with self.assertRaises(NoSectionError):
            cfg.get_section("not existed")

    def test_get_section_should_be_immutable(self):
        cfg = self._init_config()
        expected = {"main_class": "inferencer", "main_file": "", "infer_method": ""}
        self.assertEqual(expected, cfg.get_section("exec"))
        raw = cfg.get_section("exec")
        raw["new_method"] = "new"
        self.assertEqual(expected, cfg.get_section("exec"))

    def test_get_config_should_raise_exception(self):
        cfg = self._init_config()
        with self.assertRaises(NoSectionError):
            cfg.get_config("not existed", "infer_method")

    def test_get_config_should_return_empty(self):
        cfg = self._init_config()
        self.assertEqual("", cfg.get_config("exec", "infer_method"))

    def test_get_config_should_return_value(self):
        cfg = self._init_config()
        self.assertEqual("inferencer", cfg.get_config("exec", "main_class"))

    def test_get_config_should_return_default(self):
        cfg = self._init_config()
        self.assertEqual("default", cfg.get_config("exec", "not existed", "default"))

    def test_set_new_section_shold_update(self):
        cfg = self._init_config()
        new_config_dict = {"new_name": "new_value"}
        cfg.set_section("new_config", new_config_dict)
        self.assertEqual(new_config_dict, cfg.get_section("new_config"))

    def test_overwrite_old_section_should_update(self):
        cfg = self._init_config()
        new_exec_config_dict = {"main_class": "a", "main_file": "b", "new_method": "new"}
        cfg.set_section("exec", new_exec_config_dict)
        expected_exec_config_dict = {
            "main_class": "a"
            , "main_file": "b"
            , "infer_method": ""
            , "new_method": "new"
        }
        self.assertEqual(expected_exec_config_dict, cfg.get_section("exec"))

    def test_complete_old_section_with_new_config_should_update(self):
        cfg = self._init_config()
        new_exec_config_dict = {"new_method1": "new1", "new_method2": "new2"}
        cfg.set_section("exec", new_exec_config_dict, False)
        expected_exec_config_dict = {
            "main_class": "inferencer"
            , "main_file": ""
            , "infer_method": ""
            , "new_method1": "new1"
            , "new_method2": "new2"
        }
        self.assertEqual(expected_exec_config_dict, cfg.get_section("exec"))

    def test_complete_old_section_with_empty_config_should_update(self):
        cfg = self._init_config()
        new_exec_config_dict = {"main_file": "a"}
        cfg.set_section("exec", new_exec_config_dict, False)
        expected_exec_config_dict = {"main_class": "inferencer", "main_file": "a", "infer_method": ""}
        self.assertEqual(expected_exec_config_dict, cfg.get_section("exec"))

    def test_complete_old_section_with_config_should_not_update(self):
        cfg = self._init_config()
        new_exec_config_dict = {"main_class": "a"}
        cfg.set_section("exec", new_exec_config_dict, False)
        expected_exec_config_dict = {"main_class": "inferencer", "main_file": "", "infer_method": ""}
        self.assertEqual(expected_exec_config_dict, cfg.get_section("exec"))

    def test_overwrite_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("exec", "main_class", "a")
        self.assertEqual("a", cfg.get_config("exec", "main_class"))

    def test_complete_config_with_new_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("exec", "new_method", "new", False)
        self.assertEqual("new", cfg.get_config("exec", "new_method"))

    def test_complete_config_with_empty_config_should_update(self):
        cfg = self._init_config()
        cfg.set_config("exec", "main_file", "b", False)
        self.assertEqual("b", cfg.get_config("exec", "main_file"))

    def test_complete_config_with_config_should_not_update(self):
        cfg = self._init_config()
        cfg.set_config("exec", "main_class", "a", False)
        self.assertEqual("inferencer", cfg.get_config("exec", "main_class"))


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
