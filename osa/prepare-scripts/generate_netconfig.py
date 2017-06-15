#!/usr/bin/python3
# -*- coding: utf-8 -*-

"""
This script generates a netconfig for osa node
"""

import os, sys
from jinja2 import Environment, FileSystemLoader
import re
import netifaces
import socket
from yaml import load, dump, YAMLError
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper
#
# get mac mapping
#
macs = {}
for intf in netifaces.interfaces():
    print(intf)
    # only recover phsical interfaces
    if (intf.startswith('en') or intf.startswith('eth')) and '.' not in intf:
        mac = netifaces.ifaddresses(intf)[netifaces.AF_LINK][0]
        print(mac)
        if 'addr' in mac.keys():
            macs[mac['addr']] = intf

#
# Set Path and configs path
#

# Capture our current directory
TPL_DIR = os.path.dirname(os.path.abspath(__file__))+'/'

#
# Config import
#

# Load Config
with open("net-config.yaml", 'r') as stream:
    try:
        config = load(stream)
    except yaml.YAMLError as exc:
        print(exc)
config['macs'] = macs
config['srv'] = socket.gethostname()


# pp(config)

#
# Transform template to bundle.yaml according to config
#

# Create the jinja2 environment.
env = Environment(loader=FileSystemLoader(TPL_DIR),
                  trim_blocks=True)
template = env.get_template('osa.cfg')

# Render the template
for br in config['net_config'].keys():
    config['bridge'] = br
    output = template.render(**config)
    with open('/etc/network/interfaces.d/{}.cfg'.format(br), 'w') as f:
        f.write(output)
