include "lib.pxd"

cdef extern from "lib.h":
    ctypedef struct State


cdef extern from "renderEgl.h":
    ctypedef int GraphicsState

    int initOpenGL()
    int renderOnscreen(int camid, GraphicsState window, State * state);
