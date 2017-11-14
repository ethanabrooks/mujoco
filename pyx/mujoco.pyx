from os.path import join, expanduser
import numpy as np
from codecs import encode
from enum import Enum

from cython cimport view
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, mj_name2id
from pxd.mjmodel cimport mjModel, mjtObj
from pxd.mjdata cimport mjData
from pxd.mjvisualize cimport mjvScene, mjvCamera, mjvOption
from pxd.mjrender cimport mjrContext


# TODO: integrate with hsr_gym
# TODO: get GPU working

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow


cdef extern from "render.h":
    ctypedef struct RenderContext:
        mjvScene scn
        mjrContext con
        mjvCamera cam
        mjvOption opt

    GLFWwindow * initGlfw()
    mjModel * loadModel(const char * filepath)
    int initMujoco(mjModel * m, mjData * d, RenderContext * context)
    int renderOffscreen(unsigned char * rgb, int height, int width,
                        mjModel * m, mjData * d, RenderContext * context)
    int renderOnscreen(GLFWwindow * window, mjModel * m, mjData * d,
                       RenderContext * context)
    int closeMujoco(mjModel * m, mjData * d, RenderContext * context)


class MjtObj(Enum):
    UNKNOWN = 0         # unknown object type
    BODY = 1         # body
    XBODY = 2         # body  used to access regular frame instead of i-frame
    JOINT = 3         # joint
    DOF = 4         # dof
    GEOM = 5         # geom
    SITE = 5         # site
    CAMERA = 6         # camera
    LIGHT = 7         # light
    MESH = 8         # mesh
    HFIELD = 9         # heightfield
    TEXTURE = 10        # texture
    MATERIAL = 11        # material for rendering
    PAIR = 12        # geom pair to include
    EXCLUDE = 13        # body pair to exclude
    EQUALITY = 14        # equality constraint
    TENDON = 15        # tendon
    ACTUATOR = 16        # actuator
    SENSOR = 17        # sensor
    NUMERIC = 18        # numeric
    TEXT = 19        # text
    TUPLE = 20        # tuple
    KEY = 21        # keyframe


cdef class Sim(object):
    cdef GLFWwindow * window
    cdef mjModel * model
    cdef mjData * data
    cdef RenderContext context

    def __cinit__(self, filepath):
        key_path = join(expanduser('~'), '.mujoco', 'mjkey.txt')
        mj_activate(encode(key_path))
        self.window = initGlfw()
        self.model = loadModel(encode(filepath))
        self.data = mj_makeData(self.model)
        initMujoco(self.model, self.data, & self.context)

    def __enter__(self):
        pass

    def __exit__(self, *args):
        closeMujoco(self.model, self.data, & self.context)

    def render_offscreen(self, height, width):
        array = np.zeros(height * width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        renderOffscreen( & view[0], height, width, self.model, self.data,
                &self.context)
        return array.reshape(height, width, 3)

    def render(self):
        return renderOnscreen(self.window, self.model, self.data, &self.context)

    def step(self):
        mj_step(self.model, self.data)

    def get_id(self, obj, name):
        assert type(obj) == MjtObj, type(obj)
        cdef int id = mj_name2id(self.model, obj.value, encode(name))
        return id

    def get_qpos(self, obj, name):
        return self.data.qpos[self.get_id(obj, name)]

    def get_xpos(self, obj, name):
        """ Need to call mj_forward first """
        id = self.get_id(obj, name)
        return [self.data.xpos[3 * (id + i)] for i in range(3)]
