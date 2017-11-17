include "lib.pxd"

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow

cdef extern from "renderGlfw.h":
    ctypedef GLFWwindow* GraphicsState

    int initOpenGL(GraphicsState *, State *)
    int renderOnscreen(int camid, GraphicsState window, State * state)
