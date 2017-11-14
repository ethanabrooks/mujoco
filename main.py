#! /usr/bin/env python
from mujoco import Sim, MjtObj

sim = Sim("xml/humanoid.xml")
print(sim.get_qpos(MjtObj.BODY, 'torso'))

# while True: 
    # sim.render()
    # sim.step()
    # print(sim.render_offscreen(4, 4))
