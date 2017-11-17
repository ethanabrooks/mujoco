import os
from os.path import join, expanduser
from codecs import encode, decode
from enum import Enum
from libc.stdlib cimport free
from cython cimport view
from pxd.sim cimport BaseSim
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, \
    mj_id2name, mj_name2id, mj_resetData, mj_forward
from pxd.mjmodel cimport mjModel, mjtObj, mjOption, mjtNum
from pxd.mjdata cimport mjData
from pxd.mjvisualize cimport mjvScene, mjvCamera, mjvOption
from pxd.mjrender cimport mjrContext
from pxd.lib cimport State, initMujoco, renderOffscreen, closeMujoco
from pxd.renderGlfw cimport GraphicsState, initOpenGL, renderOnscreen, GLFWwindow
from libcpp cimport bool

cimport numpy as np
import numpy as np
np.import_array()

cdef class Sim(BaseSim):
    cdef GraphicsState graphics_state

    def render(self, camera_name=None):
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(ObjType.CAMERA, camera_name)
        return renderOnscreen(camid, self.graphics_state, & self.state)
