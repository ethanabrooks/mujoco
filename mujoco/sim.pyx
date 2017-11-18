RENDER = False #os.environ.get('RENDER') is not None

import os
from os.path import join, expanduser
from codecs import encode, decode
from enum import Enum
from libc.stdlib cimport free
from cython cimport view
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, \
    mj_id2name, mj_name2id, mj_resetData, mj_forward
from pxd.mjmodel cimport mjModel, mjtObj, mjOption, mjtNum
from pxd.mjdata cimport mjData
from pxd.mjvisualize cimport mjvScene, mjvCamera, mjvOption
from pxd.mjrender cimport mjrContext
from pxd.lib cimport State, initMujoco, renderOffscreen, closeMujoco
# if RENDER:
from pxd.renderGlfw cimport initOpenGL, renderOnscreen
# else:
# from pxd.renderEgl cimport GraphicsState, initOpenGL, renderOnscreen
from libcpp cimport bool

cimport numpy as np
import numpy as np
np.import_array()

# TODO: get GPU working
# TODO: Better Visualizer
# TODO: get floats working?
# TODO: b + w

class ObjType(Enum):
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


class GeomType(Enum):
    PLANE = 0
    HFIELD = 1
    SPHERE = 2
    CAPSULE = 3
    ELLIPSOID = 4
    CYLINDER = 5
    BOX = 6
    MESH = 7


cdef asarray(double * ptr, size_t size):
    cdef double[:] view = <double[:size] > ptr
    return np.asarray(view)


def get_vec(size, array, n):
    return array[n * size: (n + 1) * size]

cdef class Sim(object):

    def __cinit__(self, str fullpath):
        key_path = join(expanduser('~'), '.mujoco', 'mjkey.txt')
        mj_activate(encode(key_path))
        self.init_opengl()
        initMujoco(encode(fullpath), & self.state)
        self.model = self.state.m
        self.data = self.state.d
        self.forward_called_this_step = False

    def __enter__(self):
        pass

    def __exit__(self, *args):
        closeMujoco( & self.state)

    def init_opengl(self):
        initOpenGL(&self.graphics_state, &self.state)

    def render_offscreen(self, height, width, camera_name):
        camid = self.get_id(ObjType.CAMERA, camera_name)
        array = np.empty(height * width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        renderOffscreen(camid, & view[0], height, width, & self.state)
        return array.reshape(height, width, 3)

    def render(self, camera_name=None):
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(ObjType.CAMERA, camera_name)
        return renderOnscreen(camid, self.graphics_state, & self.state)

    def step(self):
        mj_step(self.model, self.data)
        self.forward_called_this_step = False

    def reset(self):
        mj_resetData(self.model, self.data)
        self.forward_called_this_step = False

    def forward(self):
        mj_forward(self.model, self.data)
        self.forward_called_this_step = True

    def get_id(self, obj_type, name):
        assert isinstance(obj_type, ObjType)
        return mj_name2id(self.model, obj_type.value, encode(name))

    def get_name(self, obj_type, id):
        assert isinstance(obj_type, ObjType), type(obj_type)
        buff = mj_id2name(self.model, obj_type.value, id)
        if buff is not NULL:
            return decode(buff)

    def key2id(self, key, obj_type=None):
        if type(key) is str:
            assert isinstance(obj_type, ObjType)
            return self.get_id(obj_type, key)
        else:
            assert isinstance(key, int)
            return key

    def get_qpos(self, obj, key):
        return self.data.qpos[self.key2id(key)]

    def get_geom_type(self, key):
        return self.model.geom_type[self.key2id(key)]

    def get_xpos(self, key):
        if not self.forward_called_this_step:
            self.forward()
        return get_vec(3, self.xpos, self.key2id(key, ObjType.BODY))

    def get_xquat(self, key):
        if not self.forward_called_this_step:
            self.forward()
        return get_vec(4, self.xquat, self.key2id(key, ObjType.BODY))

    def get_geom_size(self, key):
        return get_vec(3, self.geom_size, self.key2id(key, ObjType.GEOM))

    def get_geom_pos(self, key):
        return get_vec(3, self.geom_pos, self.key2id(key, ObjType.GEOM))

    @property
    def timestep(self):
        return self.model.opt.timestep

    @property
    def nbody(self):
        return self.model.nbody

    @property
    def ngeom(self):
        return self.model.ngeom

    @property
    def nq(self):
        return self.model.nv

    @property
    def nv(self):
        return self.model.nv

    @property
    def nu(self):
        return self.model.nu

    @property
    def actuator_ctrlrange(self):
        return asarray(< double*> self.model.actuator_ctrlrange, self.model.nu)

    @property
    def qpos(self):
        return asarray(< double*> self.data.qpos, self.nq)

    @property
    def qvel(self):
        return asarray(< double*> self.data.qvel, self.nv)

    @property
    def ctrl(self):
        return asarray(< double*> self.data.ctrl, self.nu)

    @property
    def xpos(self):
        return asarray(< double*> self.data.xpos, self.nbody * 3)

    @property
    def xquat(self):
        return asarray(< double*> self.data.xquat, self.nbody * 4)

    @property
    def geom_size(self):
        return asarray(< double*> self.model.geom_size, self.ngeom * 3)

    @property
    def geom_pos(self):
        return asarray(< double*> self.model.geom_pos, self.ngeom * 3)
