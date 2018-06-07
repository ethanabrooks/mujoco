#! /usr/bin/env python

import mujoco
import numpy as np
0
sim = mujoco.Sim('xml/humanoid.xml', n_substeps=10)
while True:
    sim.step()
    sim.ctrl[:] = np.random.random((sim.ctrl.shape))
    print(sim.render_offscreen(4, 5))
