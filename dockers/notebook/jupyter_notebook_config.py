# -*- coding: utf-8 -*-

# Configuration file for jupyter-notebook.
# Get base_url and password from system environment.
import os

from IPython.lib import passwd

c = get_config()
c.NotebookApp.ip = '*'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.base_url = '/' + os.getenv('BASE_URL', 'application') + '/'

# sets a password if PASSWORD is set in the environment
if 'PASSWORD' in os.environ:
    password = os.environ['PASSWORD']
    if password:
        c.NotebookApp.password = passwd(password)
    else:
        c.NotebookApp.password = ''
        c.NotebookApp.token = ''
    del os.environ['PASSWORD']
