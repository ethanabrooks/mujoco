include "util.pxd"

cdef extern from "util.h":
    ctypedef struct State


cdef extern from "utilOsmesa.h":
    ctypedef int GraphicsState

    int initOpenGL()
    int closeOpenGL()
    int renderOnscreen(int camid, GraphicsState window, State * state);
