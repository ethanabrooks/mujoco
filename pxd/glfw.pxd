include "lib.pxd"

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow

cdef extern from "render.h":
    GLFWwindow * initGlfw(State * state)
    int renderOnscreen(int camid, GLFWwindow * window, State * state)
