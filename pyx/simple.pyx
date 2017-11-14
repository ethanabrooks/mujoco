from os.path import join, expanduser
import numpy as np
from cython cimport view
from codecs import encode

# include "pxd/mjdata.pxd"
# include "pxd/mjmodel.pxd"
# include "pxd/mjrender.pxd"
# include "pxd/mjvisualize.pxd"
# include "pxd/mujoco.pxd"


cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow


# cdef extern from "mujoco.h":
    # ctypedef struct mjvScene
    # ctypedef struct mjData
    # ctypedef struct mjvScene
    # ctypedef struct mjvCamera
    # ctypedef struct mjvOption
    # ctypedef struct mjrContext

    # int mj_activate(const char* filename);
    # int mj_step(mjModel* model, mjData* data)
    # mjData* mj_makeData(const mjModel* model);


cdef class Sim(object):
    cdef GLFWwindow* window
    # cdef mjModel* model
    # cdef mjData* data
    # cdef mjvScene* scn
    # cdef mjvCamera* cam
    # cdef mjvOption* opt
    # cdef mjrContext* con

    # def __cinit__(self, filepath):
        # key_path = join(expanduser('~'), '.mujoco', 'mjkey.txt')
        # mj_activate(encode(key_path))
        # self.window = initGlfw()
        # self.model = loadModel(encode(filepath))
        # self.data = mj_makeData(self.model)
        # initMujoco(self.model, self.data, self.scn, self.cam, self.opt, self.con)

    # def __enter__(self):
        # pass

    # def __exit__(self, *args):
        # closeMujoco(self.model, self.data, self.con, self.scn)

    # def render_offscreen(self, height, width):
        # array = np.zeros(height * width * 3, dtype=np.uint8)
        # cdef unsigned char[::view.contiguous] view = array
        # renderOffscreen(&view[0], height, width, self.model, self.data, self.cam)
        # return array.reshape(height, width, 3)

    # def render(self):
        # return renderOnscreen(self.window, self.model, self.data, self.scn,
                # self.con, self.cam, self.opt)
