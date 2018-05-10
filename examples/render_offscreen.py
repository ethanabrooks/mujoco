#! /usr/bin/env python

import mujoco
from PIL import Image
import sys

height, width = map(int, sys.argv[1:])
sim = mujoco.Sim('xml/humanoid.xml')
for _ in range(100):
    print(height, width)
    array = sim.render_offscreen(height, width)
Image.fromarray(array).show()
