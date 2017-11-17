include "lib.pxd"

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow

cdef extern from "render.h":
    int initOpenGL(State * state)
    int renderOnscreen(int camid, State * state)
