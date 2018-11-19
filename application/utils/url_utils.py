# -*- coding: utf-8 -*-

from io import BytesIO

from requests import Session, Request

_session = Session()


def get_session():
    return _session


def urlopen(url, timeout):
    req = Request('GET', url)
    prepared = _session.prepare_request(req)
    res = _session.send(prepared, verify=False, timeout=timeout)
    return BytesIO(res.content)
