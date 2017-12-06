import sys
import os

if sys.platform in ['linux', 'linux2'] and not os.environ.get('RENDER'):
    # Only use EGL if working in linux and there is no RENDER env variable
    from mujoco.egl import SimEgl as Sim, GeomType, ObjType
else:
    from mujoco.glfw import SimGlfw as Sim, GeomType, ObjType


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
