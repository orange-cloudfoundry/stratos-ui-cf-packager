#!/usr/bin/env python

import json
import sys

filename = sys.argv[1]
with open(filename) as f:
    data = json.load(f)

plugin = sys.argv[2]
if not plugin in data["enabledPlugins"]:
    data["enabledPlugins"].append(plugin)

print(json.dumps(data))
