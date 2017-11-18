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
from libcpp cimport bool

cimport numpy as np
import numpy as np
np.import_array()

# TODO: docs
# TODO: Better Visualizer
# TODO: get floats working?
# TODO: b + w


class ObjType(Enum):
    """ 
    ``enum`` of different MuJoCo object types (corresponds to ``mjtObj``). 
    Some of ``Sim``'s getter methods take this as an argument e.g. ``get_name`` and ``get_id``.
    """
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
    """ 
    ``enum`` of different MuJoCo ``geom`` types (corresponds to ``mjtGeom``). 
    """
    PLANE = 0
    HFIELD = 1
    SPHERE = 2
    CAPSULE = 3
    ELLIPSOID = 4
    CYLINDER = 5
    BOX = 6
    MESH = 7


cdef asarray(double * ptr, size_t size):
    """ Convenience function for converting a pointer to an array of length ``size``"""
    cdef double[:] view = <double[:size] > ptr
    return np.asarray(view)


def get_vec(size, array, n):
    return array[n * size: (n + 1) * size]


cdef class BaseSim(object):
    """ Base class for the EGL `Sim` and the GLFW `Sim` to inherit from. """

    def __cinit__(self, str fullpath):
        """ Activate MuJoCo, initialize OpenGL, load model from xml, and initialize MuJoCo structs.

        Args:
            fullpath (str): full path to model xml file.
        """
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
        closeMujoco(& self.state)

    def render_offscreen(self, height, width, camera_name):
        """
        Args:
            height (int): height of image to return.
            width (int): width of image to return.
            camera_name (str): Name of camera, as specified in xml file.

        Returns:
            ``height`` x ``width`` image from camera with name ``camera_name`` 
        """

        camid = self.get_id(ObjType.CAMERA, camera_name)
        array = np.empty(height * width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        renderOffscreen(camid, & view[0], height, width, & self.state)
        return array.reshape(height, width, 3)

    def step(self):
        """ Advance simulation one timestep. """
        mj_step(self.model, self.data)
        self.forward_called_this_step = False

    def reset(self):
        """ Reset simulation to starting state. """
        mj_resetData(self.model, self.data)
        self.forward_called_this_step = False

    def forward(self):
        """ Calculate forward kinematics. """
        mj_forward(self.model, self.data)
        self.forward_called_this_step = True

    def get_id(self, obj_type, name):
        """ 
        Get numerical ID corresponding to object type and name. Useful for indexing arrays.
        """
        assert isinstance(obj_type, ObjType)
        return mj_name2id(self.model, obj_type.value, encode(name))

    def get_name(self, obj_type, id):
        """ Get name corresponding to object id. """
        assert isinstance(obj_type, ObjType), type(obj_type)
        buff = mj_id2name(self.model, obj_type.value, id)
        if buff is not NULL:
            return decode(buff)

    def _key2id(self, key, obj_type=None):
        """ 
        Args:
            key (str|int): name or id of object 
            obj_type (ObjType): type of object (ignored if key is an id)  
        Returns:
            id of object
        """
        if type(key) is str:
            assert isinstance(obj_type, ObjType)
            return self.get_id(obj_type, key)
        else:
            assert isinstance(key, int)
            return key

    def get_qpos(self, key):
        """ Get qpos (joint values) of object corresponding to key. """
        return self.data.qpos[self._key2id(key)]

    def get_geom_type(self, key):
        """ Get type of geom corresponding to key. """
        return self.model.geom_type[self._key2id(key)]

    def get_xpos(self, key):
        """ Get xpos (cartesian coordinates) of body corresponding to key. """
        if not self.forward_called_this_step:
            self.forward()
        return get_vec(3, self.xpos, self._key2id(key, ObjType.BODY))

    def get_xquat(self, key):
        """ Get quaternion of body corresponding to key. """
        if not self.forward_called_this_step:
            self.forward()
        return get_vec(4, self.xquat, self._key2id(key, ObjType.BODY))

    def get_geom_size(self, key):
        """ Get size of geom corresponding to key. """
        return get_vec(3, self.geom_size, self._key2id(key, ObjType.GEOM))

    def get_geom_pos(self, key):
        """ Get position of geom corresponding to key. """
        return get_vec(3, self.geom_pos, self._key2id(key, ObjType.GEOM))

    @property
    def timestep(self):
        """ Length of simulation timestep. """
        return self.model.opt.timestep

    @property
    def nbody(self):
        """ Number of bodies in model. """
        return self.model.nbody

    @property
    def ngeom(self):
        """ Number of geoms in model. """
        return self.model.ngeom

    @property
    def nq(self):
        """ Number of position coordinates. """
        return self.model.nq

    @property
    def nv(self):
        """ Number of degrees of freedom. """
        return self.model.nv

    @property
    def nu(self):
        """ Number of actuators/controls. """
        return self.model.nu

    @property
    def actuator_ctrlrange(self):
        """ Range of controls (low, high). """
        return asarray( < double*> self.model.actuator_ctrlrange, self.model.nu * 2)

    @property
    def qpos(self):
        """ Joint positions. """
        return asarray( < double*> self.data.qpos, self.nq)

    @property
    def qvel(self):
        """ Joint velocities. """
        return asarray( < double*> self.data.qvel, self.nv)

    @property
    def ctrl(self):
        """ Joint actuations. """
        return asarray( < double*> self.data.ctrl, self.nu)

    @property
    def xpos(self):
        """ Cartesian coordinates of bodies. """
        return asarray( < double*> self.data.xpos, self.nbody * 3)

    @property
    def xquat(self):
        """ Quaternions of bodies. """
        return asarray( < double*> self.data.xquat, self.nbody * 4)

    @property
    def geom_size(self):
        """ Sizes of geoms. """
        return asarray( < double*> self.model.geom_size, self.ngeom * 3)

    @property
    def geom_pos(self):
        """ Positions of geoms. """
        return asarray( < double*> self.model.geom_pos, self.ngeom * 3)
