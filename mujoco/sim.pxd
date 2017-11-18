include "../pxd/renderGlfw.pxd"

cdef class Sim(object):
    cdef GraphicsState graphics_state
    cdef mjData * data
    cdef mjModel * model
    cdef State state
    cdef int forward_called_this_step


