include "util.pxd"

cdef extern from "GL/osmesa.h":
    ctypedef struct OSMesaContext:
        pass

cdef extern from "util.h":
    ctypedef struct State

cdef extern from "utilOsmesa.h":
    ctypedef int GraphicsState

    int initOpenGL(OSMesaContext * ctx, void ** buffer)
    int closeOpenGL(OSMesaContext ctx, void * buffer)
    int renderOnscreen(int camid, GraphicsState window, State * state)
