import os
from os.path import join, expanduser
from codecs import encode, decode
from enum import Enum
from libc.string cimport strncpy
from cython cimport view
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, \
    mj_id2name, mj_name2id, mj_resetData, mj_forward, mj_fwdPosition
from pxd.mjmodel cimport mjModel, mjtObj, mjOption, mjtNum
from pxd.mjdata cimport mjData
from pxd.mjvisualize cimport mjvScene, mjvCamera, mjvOption
from pxd.mjrender cimport mjrContext
from pxd.util cimport State, initMujoco, renderOffscreen, closeMujoco, setCamera

cdef extern from *:  # defined as macro
    char* MJKEY_PATH

cimport numpy as np
import numpy as np
np.import_array()

# TODO: make access synchronized
# TODO: get floats working?
# TODO: docs


""" 
``enum`` of different MuJoCo object types (corresponds to ``mjtObj``). 
Some of ``Sim``'s getter methods take this as an argument e.g. ``id2name`` and ``name2id``.
"""
ObjType = Enum('ObjType',
               (
                   ' UNKNOWN'  # unknown object type
                   ' BODY'  # body
                   ' XBODY'  # body  used to access regular frame instead of i-frame
                   ' JOINT'  # joint
                   ' DOF'  # dof
                   ' GEOM'  # geom
                   ' SITE'  # site
                   ' CAMERA'  # camera
                   ' LIGHT'  # light
                   ' MESH'  # mesh
                   ' HFIELD'  # heightfield
                   ' TEXTURE'  # texture
                   ' MATERIAL'  # material for rendering
                   ' PAIR'  # geom pair to include
                   ' EXCLUDE'  # body pair to exclude
                   ' EQUALITY'  # equality constraint
                   ' TENDON'  # tendon
                   ' ACTUATOR'  # actuator
                   ' SENSOR'  # sensor
                   ' NUMERIC'  # numeric
                   ' TEXT'  # text
                   ' TUPLE'  # tuple
                   ' KEY'  # keyframe
               ),
               module=__name__)

""" 
``enum`` of different MuJoCo ``geom`` types (corresponds to ``mjtGeom``). 
"""
GeomType = Enum('GeomType',
                (
                    ' PLANE'
                    ' HFIELD'
                    ' SPHERE'
                    ' CAPSULE'
                    ' ELLIPSOID'
                    ' CYLINDER'
                    ' BOX'
                    ' MESH'
                ),
                module=__name__)


cdef asarray(double * ptr, size_t size):
    """ Convenience function for converting a pointer to an array of length ``size``"""
    cdef double[:] view = <double[:size] > ptr
    return np.asarray(view)


def get_vec(int size, np.ndarray array, int n):
    return array[n * size: (n + 1) * size]

def check_ObjType(obj, argnum):
    assert isinstance(obj, ObjType), \
            'arg {} must be an instance of `ObjType`'.format(argnum)


cdef class BaseSim(object):
    """ Base class for the EGL `Sim` and the GLFW `Sim` to inherit from. """

    cdef mjData * data
    cdef mjModel * model
    cdef State state
    cdef int forward_called_this_step

    def __cinit__(self, str fullpath):
        """ Activate MuJoCo, initialize OpenGL, load model from xml, and initialize MuJoCo structs.

        Args:
            fullpath (str): full path to model xml file.
        """
        mj_activate(MJKEY_PATH)
        self.init_opengl()
        initMujoco(encode(fullpath), & self.state)
        self.model = self.state.m
        self.data = self.state.d

    def __enter__(self):
        return self

    def __exit__(self, *args):
        closeMujoco(& self.state)

    def render_offscreen(self, int height, int width, camera_name=None, camera_id=None, int grayscale=False):
        """
        Args:
            height (int): height of image to return.
            width (int): width of image to return.
            camera_name (str): Name of camera, as specified in xml file.

        Returns:
            ``height`` x ``width`` image from camera with name ``camera_name`` 
        """
        if camera_name is not None:
            camera_id = self.name2id(ObjType.CAMERA, camera_name)
        elif camera_id is None:
            camera_id = -1
        array = np.empty(height * width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        setCamera(camera_id, & self.state)
        renderOffscreen(& view[0], height, width, & self.state)
        array = array.reshape(height, width, 3)
        array = np.flip(array, 0)
        if grayscale:
            return array.mean(axis=2)
        else:
            return array

    def step(self):
        """ Advance simulation one timestep. """
        mj_step(self.model, self.data)

    def reset(self):
        """ Reset simulation to starting state. """
        mj_resetData(self.model, self.data)

    def forward(self):
        """ Calculate forward kinematics. """
        mj_forward(self.model, self.data)

    def qpos_to_xpos(self, np.ndarray qpos):
        old_qpos = self.qpos.copy()
        self.qpos[:] = qpos
        mj_fwdPosition(self.model, self.data)
        xpos = self.xpos.copy()
        self.qpos[:] = old_qpos
        self.forward()
        return xpos

    def name2id(self, obj_type, str name):
        """ 
        Get numerical ID corresponding to object type and name. Useful for indexing arrays.
        """
        check_ObjType(obj_type, argnum=1)
        id = mj_name2id(self.model, obj_type.value - 1, encode(name))
        if id < 0:
            raise RuntimeError("name", name, "not found in model")
        return id

    def id2name(self, obj_type, id):
        """ Get name corresponding to object id. """
        check_ObjType(obj_type, argnum=1)
        buff = mj_id2name(self.model, obj_type.value - 1, id)
        if buff is not NULL:
            return decode(buff)
        else:
            raise RuntimeError("id", id, "not found in model")

    def _key2id(self, key, obj_type=None):
        """ 
        Args:
            key (str|int): name or id of object 
            obj_type (ObjType): type of object (ignored if key is an id)  
        Returns:
            id of object
        """
        if type(key) is str:
            check_ObjType(obj_type, argnum=2)
            return self.name2id(obj_type, key)
        else:
            assert isinstance(
                key, int), 'If 2nd argument is None, 1st argument must be `int`'
            return key

    def jnt_qposadr(self, key):
        if type(key) is str:
            key = self.name2id(ObjType.JOINT, key)
        return self.model.jnt_qposadr[key]

    def get_joint_qpos(self, key):
        """ Get qpos (joint values) of object corresponding to key. """
        return self.data.qpos[self.jnt_qposadr(key)]

    def get_joint_qvel(self, key):
        """ Get qvel (joint velocities) of object corresponding to key. """
        return self.data.qvel[self._key2id(key, ObjType.JOINT)]

    def get_geom_type(self, key):
        """ Get type of geom corresponding to key. """
        return self.model.geom_type[self._key2id(key, ObjType.JOINT)]

    def get_body_xpos(self, key, qpos=None):
        """ Get xpos (cartesian coordinates) of body corresponding to key. """
        if qpos is None:
            xpos = self.xpos
        else:
            xpos = self.qpos_to_xpos(qpos)
        return get_vec(3, xpos, self._key2id(key, ObjType.BODY))

    def get_body_xquat(self, key):
        """ Get quaternion of body corresponding to key. """
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
        """ Number of generalized coordinates. """
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
    def nsensordata(self):
        """ Number of actuators/controls. """
        return self.model.nsensordata

    @property
    def nmocap(self):
        """ Number of mocap bodies."""
        return self.model.nmocap

    @property
    def actuator_ctrlrange(self):
        """ Range of controls (low, high). """
        return asarray( < double*> self.model.actuator_ctrlrange, 
                       self.model.nu * 2).reshape(-1, 2)


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
    def sensordata(self):
        """ Quaternions of bodies. """
        return asarray( < double*> self.data.sensordata, self.nsensordata)

    @property
    def geom_size(self):
        """ Sizes of geoms. """
        return asarray( < double*> self.model.geom_size, self.ngeom * 3)

    @property
    def geom_pos(self):
        """ Positions of geoms. """
        return asarray( < double*> self.model.geom_pos, self.ngeom * 3)

    @property
    def mocap_pos(self):
        """ Positions of mocap bodies. """
        return asarray( < double*> self.data.mocap_pos, self.nmocap * 3)

    @property
    def mocap_quat(self):
        """ Quaternions of mocap bodies. """
        return asarray( < double*> self.data.mocap_quat, self.nmocap * 4) 
