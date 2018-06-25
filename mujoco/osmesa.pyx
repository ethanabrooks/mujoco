include "mujoco/sim.pyx"

from pxd.utilOsmesa cimport initOpenGL, closeOpenGL, GraphicsState, OSMesaContext
from codecs import encode, decode

cdef class SimOsmesa(BaseSim):
    """
    Sim that uses OSMesa functionality for offscreen rendering on CPUs.
    """
    cdef void * buffer

    cdef OSMesaContext ctx

    def init_opengl(self):
        """ Initialize OSMesa. """
        initOpenGL(&self.ctx, &self.buffer, self.height, self.width)

    def close_opengl(self):
        """ Close OSMesa. """
        closeOpenGL(self.ctx, self.buffer)

    def render(self, str camera_name=None, dict labels=None):
        raise RuntimeError("Onscreen rendering with OSMesa is not supported")
