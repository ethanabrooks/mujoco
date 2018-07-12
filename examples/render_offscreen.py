#! /usr/bin/env python

import argparse

from PIL import Image

import mujoco

parser = argparse.ArgumentParser()
parser.add_argument('height', type=int)
parser.add_argument('width', type=int)
# parser.add_argument('--video-path', type=str, default='build/video.mp4')
args = parser.parse_args()

print(args.height, args.width)
path = 'xml/humanoid.xml'

sim = mujoco.Sim(path, height=args.height, width=args.width)
for _ in range(10):
    array = sim.render_offscreen()
Image.fromarray(array).show()
