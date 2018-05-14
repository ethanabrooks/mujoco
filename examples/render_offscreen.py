#! /usr/bin/env python

import mujoco
import numpy as np

sim = mujoco.Sim('xml/humanoid.xml')
while True:
    sim.step()
    sim.ctrl[:] = np.random.random((sim.ctrl.shape))
    print(sim.render_offscreen(4, 5))
