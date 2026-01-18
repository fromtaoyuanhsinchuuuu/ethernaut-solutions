#!/usr/bin/env python3
import os, sys

prefix = os.environ.get("PREFIX")
if not prefix:
    sys.exit("PREFIX not set")

hexstr = prefix[2:] if prefix.startswith("0x") else prefix
if len(hexstr) % 2:
    sys.exit("PREFIX hex length is odd; check value")

print("PREFIX bytes:", len(hexstr) // 2)