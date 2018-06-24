#! /usr/bin/env python

import numpy as np
import mujoco
from PIL import Image
import sys

height, width = map(int, sys.argv[1:])
sim = mujoco.Sim('xml/humanoid.xml')
for _ in range(10):
    array = sim.render_offscreen(height, width)
Image.fromarray(array).show()
