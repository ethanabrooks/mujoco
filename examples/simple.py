#! /usr/bin/env python

import glfw
import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
while not sim.should_close
    sim.step()
    sim.render()
