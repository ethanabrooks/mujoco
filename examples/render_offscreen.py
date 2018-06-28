#! /usr/bin/env python

import argparse

from PIL import Image

import mujoco
import subprocess
import os

parser = argparse.ArgumentParser()
parser.add_argument('height', type=int)
parser.add_argument('width', type=int)
parser.add_argument('--video-path', type=str, default='build/video.mp4')
args = parser.parse_args()

command = [    'ffmpeg',
          '-nostats',
          '-loglevel',
          'error',  # suppress warnings
          '-y',
          # '-r',
          # '%d' % self.frames_per_sec,

          # input
          '-f',
          'rawvideo',
          '-s:v',
          '{}x{}'.format(args.height, args.width),
          '-pix_fmt',
          'rgb32',
          '-i',
          '-',  # this used to be /dev/stdin, which is not Windows-friendly

          # output
          '-vcodec',
          'libx264',
          '-pix_fmt',
          'yuv420p',
          args.video_path]
subprocess.Popen(command, stdin=subprocess.PIPE,
                 preexec_fn=os.setsid)  # TODO: do we need this?

print(args.height, args.width)
sim = mujoco.Sim('xml/humanoid.xml', height=args.height, width=args.width)
for _ in range(10):
    array = sim.render_offscreen()
Image.fromarray(array).show()
