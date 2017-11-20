import os
import sys

from mujoco.sim import GeomType, ObjType
if sys.platform in ['linux', 'linux2'] and not os.environ.get('RENDER'):
    from mujoco.simEgl import Sim
else:
    from mujoco.simGlfw import Sim


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
