import config

from mujoco.sim import GeomType, ObjType
if config.use_egl():
    from mujoco.simEgl import Sim
else:
    from mujoco.simGlfw import Sim


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
