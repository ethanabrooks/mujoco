from mujoco.sim cimport BaseSim
from pxd.renderEgl cimport initOpenGL

cdef class Sim(BaseSim):

    def init_opengl(self):
        initOpenGL()

    def render(self):
        raise RuntimeError("Onscreen rendering with EGL is not currently supported")
