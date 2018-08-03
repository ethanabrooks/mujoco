include "util.pxd"

cdef extern from "pthread.h":
    ctypedef struct pthread_mutex_t:
        pass

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow

cdef extern from "utilGlfw.h":
    ctypedef struct GraphicsState:
        State* state
        GLFWwindow* window
        pthread_mutex_t mutex
        int buttonLeft
        int buttonMiddle
        int buttonRight
        double mouseLastX
        double mouseLastY
        double mouseDx
        double mouseDy
        char lastKeyPress

    int clearLastKey(GraphicsState* state)
    int clearMouseDx(GraphicsState* state)
    int clearMouseDy(GraphicsState* state)
    int initOpenGL(GraphicsState *, State *, int, int)
    int closeOpenGL()
    int renderOnscreen(GraphicsState* state)
