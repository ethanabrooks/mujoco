#! /usr/bin/env python

import mujoco
from mujoco.sim import GeomType, ObjType, BaseSim
print('dir(mujoco.simGlfw)', dir(mujoco))
# import mujoco.simGlfw
# from mujoco.simGlfw import Sim

Sim = BaseSim

# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType', '__version__']
