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
    if res.status_code != 200:
        raise IOError("fail to open {}".format(url))
    return BytesIO(res.content)
