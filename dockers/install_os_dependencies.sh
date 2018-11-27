#!/bin/bash

# install os dependencies
apt-get update \
&& apt-get install -yq --no-install-recommends \
    libgtk2.0-dev \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*