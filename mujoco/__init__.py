import sys
import os


def print_green(str):
    OKGREEN = '\033[92m'
    BOLD = '\033[1m'
    ENDC = '\033[0m'
    print(OKGREEN + BOLD + str + ENDC)


if sys.platform in ['linux', 'linux2'] and os.environ.get('EGL') == 1:
    # Only use EGL if working in linux and there is no RENDER env variable
    print_green("Using EGL version of mujoco.")
    from mujoco.egl import SimEgl as Sim, GeomType, ObjType
else:
    print_green("Using GLFW version of mujoco.")
    from mujoco.glfw import SimGlfw as Sim, GeomType, ObjType


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']
