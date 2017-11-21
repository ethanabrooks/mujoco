include "mujoco.pxd"
include "mjvisualize.pxd"
include "mjrender.pxd"

cdef extern from "lib.h":
    ctypedef struct State:
        mjModel * m
        mjData * d
        mjvScene scn
        mjrContext con
        mjvCamera cam
        mjvOption opt
        int button_left
        int button_middle
        int button_right
        double lastx
        double lasty
        double dx
        double dy
        char lastkey

    int initMujoco(const char * fullpath, State * state)
    int renderOffscreen(int camid, unsigned char * rgb,
                        int height, int width, State * state)
    int closeMujoco(State * state)

