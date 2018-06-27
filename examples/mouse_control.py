#! /usr/bin/python3
"""Agent that executes random actions"""
# import gym
import numpy as np

import mujoco

sim = mujoco.Sim('xml/humanoid.xml')
action = np.zeros(sim.ctrl.shape)
i = 0
print('Select different actuators with the number keys.')
print('Activate the actuator by moving the mouse up and down in the window.')

while True:
    lastkey = sim.get_last_key_press()
    action[i] += sim.get_mouse_dy()

    for k in range(10):
        if lastkey == str(k):
            i = k - 1
            print(sim.id2name(mujoco.ObjType.ACTUATOR, i))

    sim.ctrl[:] = action
    sim.step()
    sim.render()
