#! /usr/bin/env python
from mujoco import Sim, GeomType, ObjType

sim = Sim("xml/humanoid.xml")
# print(sim.get_xpos(MjtObj.BODY, 'worldbody'))
# print(sim.get_xpos(MjtObj.BODY, 'left_lower_arm'))

while True: 
    sim.render()
    sim.step()
    sim.render_offscreen(4, 4, 'tracking')
