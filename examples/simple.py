#! /usr/bin/env python

import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
while True:
    sim.step()
    sim.render()
