import sys
import os

from mujoco.sim import GeomType, ObjType
if sys.platform in ['linux', 'linux2'] and not os.environ.get('RENDER'):
    # Only use EGL if working in linux and there is no RENDER env variable
    from mujoco.egl import SimEgl as Sim
else:
    from mujoco.glfw import SimGlfw as Sim


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
