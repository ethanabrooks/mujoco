from mujoco.sim cimport BaseSim
from pxd.renderEgl cimport initOpenGL

cdef class Sim(BaseSim):

    def init_opengl(self):
        initOpenGL()
