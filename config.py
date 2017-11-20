#! /usr/bin/env python
import sys
import os


def use_egl():
    return sys.platform in ['linux', 'linux2'] and not os.environ.get('RENDER')
