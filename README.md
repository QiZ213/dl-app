# DL-APPLICATION

## Prerequisites

Access a linux server, and download this project.
```bash
$ git clone http://git.ppdaicorp.com/bird/dl-application
$ cd dl-application
```
Install dl-application.
```bash
$ pip install setuptools
$ python setup.py install
```
## Develop Guides

### Direct Mode
Make sure all dependencies of your code is installed locally.

#### Create your project
- put all source codes into folder with user-defined module name
- put all resource files into "resources", such as pre-trained models, vocabulary dictionaries
- put all scripts into "scripts", including common_settings.sh

#### Use module "application"

Examples
- path definition compatible for all modes 
  ```python
  import os
  from application import RESOURCE_DIR
  model_name='model file name'
  model_file = os.path.join(RESOURCE_DIR, model_name)
  ```

- dump json from python object
  ```python
  from application.utils import dump_json
  obj = object() # use your python object
  text = dump_json(obj)
  ```

### Stand-alone Mode


### Remote Mode