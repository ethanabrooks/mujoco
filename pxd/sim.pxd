include "mujoco.pxd"
include "lib.pxd"

cdef class BaseSim:
    cdef mjData * data
    cdef mjModel * model
    cdef State state
    cdef int forward_called_this_step
