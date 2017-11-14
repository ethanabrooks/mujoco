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
    int renderOffscreen(int camid, unsigned char * rgb, int height, int width,
                        mjModel * m, mjData * d, RenderContext * context)
    int renderOnscreen(int camid, GLFWwindow * window, mjModel * m, mjData * d,
                       RenderContext * context)
    int closeMujoco(mjModel * m, mjData * d, RenderContext * context)


class Types(Enum):
    UNKNOWN = 0         # unknown object type
    BODY = 1         # body
    XBODY = 2         # body  used to access regular frame instead of i-frame
    JOINT = 3         # joint
    DOF = 4         # dof
    GEOM = 5         # geom
    SITE = 6         # site
    CAMERA = 7         # camera
    LIGHT = 8         # light
    MESH = 9         # mesh
    HFIELD = 10         # heightfield
    TEXTURE = 11        # texture
    MATERIAL = 12        # material for rendering
    PAIR = 13        # geom pair to include
    EXCLUDE = 14        # body pair to exclude
    EQUALITY = 15        # equality constraint
    TENDON = 16        # tendon
    ACTUATOR = 17        # actuator
    SENSOR = 18        # sensor
    NUMERIC = 19        # numeric
    TEXT = 20        # text
    TUPLE = 21        # tuple
    KEY = 22        # keyframe


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

    def render_offscreen(self, height, width, camera_name):
        camid = self.get_id(Types.CAMERA, camera_name)
        array = np.zeros(height * width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        renderOffscreen(camid, & view[0], height, width, self.model, self.data,
                        & self.context)
        return array.reshape(height, width, 3)

    def render(self, camera_name=None):
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(Types.CAMERA, camera_name)
        return renderOnscreen(camid, self.window, self.model, self.data, & self.context)

    def step(self):
        mj_step(self.model, self.data)

    def get_id(self, obj_type, name):
        assert type(obj_type) == Types, type(obj_type)
        cdef int id = mj_name2id(self.model, obj_type.value, encode(name))
        return id

    def get_qpos(self, obj, name):
        return self.data.qpos[self.get_id(obj, name)]

    def get_xpos(self, obj, name):
        """ Need to call mj_forward first """
        id = self.get_id(obj, name)
        return [self.data.xpos[3 * (id + i)] for i in range(3)]
