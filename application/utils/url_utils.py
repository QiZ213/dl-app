# -*- coding: utf-8 -*-

from io import BytesIO

import requests
from requests import Session, Request
from requests.adapters import HTTPAdapter
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

__all__ = ['get_session', 'urlopen']

_session = Session()
_adaptor = HTTPAdapter(max_retries=3)
_session.mount('http://', _adaptor)
_session.mount('https://', _adaptor)


def get_session():
    return _session


def urlopen(url, timeout):
    req = Request('GET', url)
    prepared = _session.prepare_request(req)
    res = _session.send(prepared, verify=False, timeout=timeout)
    if res.status_code != 200:
        raise IOError("fail to open {}".format(url))
    return BytesIO(res.content)
