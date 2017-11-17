include "lib.pxd"

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow

cdef extern from "renderGlfw.h":
    ctypedef unsigned long ULong
    ctypedef struct GraphicsState:
        pass

    GraphicsState* initOpenGL(State * state)
    int renderOnscreen(int camid, GraphicsState * window, State * state)
