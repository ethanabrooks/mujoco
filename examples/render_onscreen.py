#! /usr/bin/env python

import numpy as np
import argparse

import mujoco

parser = argparse.ArgumentParser()
parser.add_argument('--height', type=int)
parser.add_argument('--width', type=int)
args = parser.parse_args()
sim = mujoco.Sim('xml/humanoid.xml', n_substeps=1, height=args.height, width=args.width)
try:
    while True:
        sim.step()
        sim.ctrl[:] = -np.ones((sim.ctrl.shape))
        sim.render()
except KeyboardInterrupt:
    pass
