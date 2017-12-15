#! /usr/bin/env python

import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
while True:
    sim.step()
    print(sim.render_offscreen(4, 5, 'rgb'))
