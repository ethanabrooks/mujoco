#!/usr/bin/env python
# demonstration of markers (visual-only geoms)

import math
import os
import time

import numpy as np

from mujoco import Sim

# from mujoco_py import load_model_from_xml, MjSim, MjViewer

sim = Sim('xml/markers.xml')
step = 0
while True:
    t = time.time()
    x, y = math.cos(t), math.sin(t)
    sim.render(labels={str(t): np.array([x, y, 1])})

    step += 1
    if step > 100 and os.getenv('TESTING') is not None:
        break
