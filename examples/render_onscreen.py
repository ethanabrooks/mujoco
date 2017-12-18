#! /usr/bin/env python

import numpy as np
import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
while True:
    sim.step()
    sim.ctrl[:] = -np.ones((sim.ctrl.shape))
    sim.render()
