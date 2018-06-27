#! /usr/bin/env python

import argparse

from PIL import Image

import mujoco

parser = argparse.ArgumentParser()
parser.add_argument('height', type=int)
parser.add_argument('width', type=int)
args = parser.parse_args()

print(args.height, args.width)
sim = mujoco.Sim('xml/humanoid.xml', height=args.height, width=args.width)
for _ in range(10):
    array = sim.render_offscreen()
Image.fromarray(array).show()
