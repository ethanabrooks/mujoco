from os.path import join, expanduser
from codecs import encode
from enum import Enum
from libc.stdlib cimport free
from cython cimport view
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, mj_name2id, \
    mj_resetData, mj_forward
from pxd.mjmodel cimport mjModel, mjtObj, mjOption, mjtNum
from pxd.mjdata cimport mjData
from pxd.mjvisualize cimport mjvScene, mjvCamera, mjvOption
from pxd.mjrender cimport mjrContext
from libcpp cimport bool 

cimport numpy as np
import numpy as np
np.import_array()

# TODO: integrate with hsr_gym
# TODO: get GPU working

cdef extern from "glfw3.h":
    ctypedef struct GLFWwindow


cdef extern from "render.h":
    ctypedef struct State:
        mjModel * m
        mjData * d
        mjvScene scn
        mjrContext con
        mjvCamera cam
        mjvOption opt
        bool button_left
        bool button_middle
        bool button_right
        double lastx
        double lasty

    GLFWwindow * initGlfw(State * state)
    int initMujoco(const char *fullpath, State * state)
    int renderOffscreen(int camid, unsigned char * rgb,
                        int height, int width, State * state)
    int renderOnscreen(int camid, GLFWwindow * window, State * state)
    int closeMujoco(State * state)


class GeomType(Enum):
    PLANE = 0
    HFIELD = 1
    SPHERE = 2
    CAPSULE = 3
    ELLIPSOID = 4
    CYLINDER = 5
    BOX = 6
    MESH = 7


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


cdef asarray(double * ptr, size_t size):
    cdef double[:] view = <double[:size] > ptr
    return np.asarray(view)

cdef get_vec(double * ptr, int size, int offset):
    return asarray(ptr, offset + size)
    # return np.array([ptr[i] for i in range(offset, offset + size)])

cdef get_vec3(double * ptr, int n):
    return asarray(ptr=ptr + n, size=3)


cdef class Array(np.ndarray):
    cdef double* data_ptr
    cdef int size

    cdef set_data(self, int size, double* data_ptr):
        """ Set the data of the array """
        self.data_ptr = data_ptr
        self.size = size

    def __array__(self):
        cdef np.npy_intp shape[1]
        shape[0] = <np.npy_intp> self.size
        # Create a 1D array, of length 'size'
        return np.PyArray_SimpleNewFromData(1, shape,
                                               np.NPY_INT, self.data_ptr)


cdef class Sim(object):
    cdef GLFWwindow * window
    cdef mjData * data
    cdef mjModel * model
    cdef State state

    cdef double _timestep
    cdef int _nv
    cdef int _nu
    cdef np.ndarray _actuator_ctrlrange
    cdef np.ndarray _qpos
    cdef np.ndarray _qvel
    cdef np.ndarray _ctrl
    cdef Array qpos
    cdef Array qvel
    cdef np.ndarray ctrl

    def __cinit__(self, str fullpath):
        key_path = join(expanduser('~'), '.mujoco', 'mjkey.txt')
        mj_activate(encode(key_path))
        self.window = initGlfw(&self.state)
        initMujoco(encode(fullpath), & self.state)
        self.model = self.state.m
        self.data = self.state.d

        # self.ctrl = asarray(self.data.qpos, self.nq)
        # self.qvel = Array()
        self.ctrl = asarray(self.data.ctrl, self.nu)

        # self.qpos.set_data(self.nq,<double*> self.data.qpos)
        # self.qpos.set_data(self.nq,<double*> self.data.qpos)
        # self.ctrl.set_data(self.nu,<double*> self.data.ctrl)

    def __enter__(self):
        pass

    def __exit__(self, *args):
        closeMujoco(& self.state)

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
        return renderOnscreen(camid, self.window, & self.state)

    def step(self):
        mj_step(self.model, self.data)
        print('read into list', [self.data.ctrl[i] for i in range(3)])
        self.ctrl[1] = .7
        # print(asarray(<double*> self.data.ctrl, 3))
        self.data.ctrl[0] = .5
        print('call to asarray', asarray(<double*> self.data.ctrl, 3))
        print('read into list after assign', [self.data.ctrl[i] for i in range(3)])

    def reset(self):
        mj_resetData(self.model, self.data)

    def forward(self):
        mj_forward(self.model, self.data)

    def get_id(self, obj_type, name):
        assert isinstance(obj_type, ObjType), type(obj_type)
        return mj_name2id(self.model, obj_type.value, encode(name))

    def key2id(self, key, obj=None):
        assert type(key) in [int, str]
        if type(key) is str:
            return self.get_id(obj, key)
        return key

    def get_qpos(self, obj, key):
        return self.data.qpos[self.key2id(key)]

    def get_geom_type(self, key):
        return self.model.geom_type[self.key2id(key)]

    def get_xpos(self, key):
        """ Need to call mj_forward first """
        return get_vec3( < double*> self.data.xpos, self.key2id(key, ObjType.BODY))

    def get_geom_size(self, key):
        return get_vec3( < double*> self.model.geom_size, self.key2id(key, ObjType.GEOM))

    def get_geom_pos(self, key):
        return get_vec3( < double*> self.model.geom_pos, self.key2id(key, ObjType.GEOM))

    @property
    def timestep(self):
        return self.model.opt.timestep

    @property
    def nbody(self):
        return self.model.nbody

    @property
    def nq(self):
        return self.model.nv

    @property
    def nv(self):
        return self.model.nv

    @property
    def nu(self):
        return self.model.nu

    # @property
    # def actuator_ctrlrange(self):
        # return asarray( < double*> self.model.actuator_ctrlrange, self.model.nu).copy()

    # @property
    # def qpos(self):
        # return asarray( < double*> self.data.qpos, self.nq)

    # @property
    # def qvel(self):
        # return asarray( < double*> self.data.qvel, self.nv)

    # @property
    # def ctrl(self):
        # return asarray( < double*> self.data.ctrl, self.nu)
