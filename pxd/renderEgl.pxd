include "lib.pxd"

cdef extern from "renderEgl.h":
    ctypedef int GraphicsState

    int initOpenGL()
