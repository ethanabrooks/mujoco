from pxd.renderEgl cimport initOpenGL

cdef class Sim(BaseSim):

    def init_opengl(self):
        initOpenGL(&self.graphics_state2, &self.state)
