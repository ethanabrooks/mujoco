import sys
import os

from mujoco.sim import GeomType, ObjType
if sys.platform in ['linux', 'linux2'] and not os.environ.get('RENDER'):
    # Only use EGL if working in linux and there is no RENDER env variable
    from mujoco.simEgl import SimEgl
    Sim = SimEgl
else:
    from mujoco.simGlfw import SimGlfw
    Sim = SimGlfw


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
