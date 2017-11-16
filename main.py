#! /usr/bin/env python
from mujoco import Sim, GeomType, ObjType

sim = Sim("xml/humanoid.xml")
# sim = Sim("../zero_shot/environment/models/navigate.xml")

while True: 
    sim.render()
    sim.step()
    sim.render_offscreen(4, 4, 'tracking')
