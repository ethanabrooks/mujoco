include "mujoco/sim.pyx"

from pxd.utilOsmesa cimport initOpenGL, closeOpenGL
from codecs import encode, decode


cdef class SimEgl(BaseSim):
    """ 
    Sim that uses EGL functionality (faster on the Nvidia GPUs).  Currently supports offscreen but not onscreen rendering.
    """

    def init_opengl(self):
        """ Initialize EGL. """
        initOpenGL()

    def close_opengl(self):
        """ Close EGL. """
        closeOpenGL()

    def render(self, str camera_name=None, dict labels=None):
        raise RuntimeError("Onscreen rendering with EGL is not supported")
