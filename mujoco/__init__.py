import os


def print_green(str):
    OKGREEN = '\033[92m'
    BOLD = '\033[1m'
    ENDC = '\033[0m'
    print(OKGREEN + BOLD + str + ENDC)


# Public API:
__all__ = ['Sim', 'GeomType', 'ObjType']

if os.environ.get('EGL') == '1':
    try:
        from mujoco.egl import SimEgl as Sim, GeomType, ObjType, activate
        __all__.insert(0, 'SimEgl')
        print_green("Using EGL version of mujoco.")
    except ImportError:
        print(
            'EGL library could not be imported. Either specify `opengl-dir` '
            'in config.yml (to build EGL version of mujoco) or make sure the '
            'environment variable `EGL` is not set to 1, to use either '
            'the GLFW version or the OSMesa version.')
        exit()
else:
    try:
        from mujoco.glfw import SimGlfw as Sim, GeomType, ObjType, activate
        __all__.insert(0, 'SimGlfw')
        print_green("Using GLFW version of mujoco.")
    except ImportError:
        from mujoco.osmesa import SimOsmesa as Sim, GeomType, ObjType, activate
        __all__.insert(0, 'SimOsmesa')
        print_green("Using OSMesa version of mujoco.")
    except ImportError:
        from mujoco.egl import SimEgl as Sim, GeomType, ObjType, activate
        __all__.insert(0, 'SimEgl')
        print_green("Using EGL version of mujoco.")
    except ImportError:
        print('Could not import GLFW, OSMesa, or EGL version of mujoco. '
              'Try rebuilding (rerun `make`).')
        exit()

activate()
