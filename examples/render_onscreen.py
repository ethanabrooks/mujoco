#! /usr/bin/env python

import glfw
import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
while True:
    sim.step()
    sim.render()
