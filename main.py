#! /usr/bin/env python
from mujoco import Sim
import os

print(os.path.realpath(os.path.curdir))


sim = Sim("xml/humanoid.xml")

# while True: sim.render_offscreen(80, 80)
