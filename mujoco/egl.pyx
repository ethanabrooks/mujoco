from mujoco.sim cimport BaseSim
from pxd.renderEgl cimport initOpenGL, closeOpenGL

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

    def render(self):
        raise RuntimeError("Onscreen rendering with EGL is not currently supported")
