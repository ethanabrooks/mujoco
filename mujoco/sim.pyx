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
from pxd.lib cimport State, initMujoco, renderOffscreen, closeMujoco
from libcpp cimport bool

cimport numpy as np
import numpy as np
np.import_array()

# TODO: make access synchronized
# TODO: fix RENDER compilation issues
# TODO: get floats working?
# TODO: docs


""" 
``enum`` of different MuJoCo object types (corresponds to ``mjtObj``). 
Some of ``Sim``'s getter methods take this as an argument e.g. ``get_name`` and ``get_id``.
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
               module=__name__,
               qualname='mujoco.ObjType')

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
                module=__name__,
                qualname='mujoco.GeomType')


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

    def __enter__(self):
        return self

    def __exit__(self, *args):
        closeMujoco(& self.state)

    def render_offscreen(self, height, width, camera_name, grayscale=False):
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
        setCamera(camid, & self.state)
        renderOffscreen(& view[0], height, width, & self.state)
        array = array.reshape(height, width, 3)
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

    def qpos_to_xpos(self, qpos):
        old_qpos = self.joint_qpos.copy()
        self.joint_qpos[:] = qpos
        mj_fwdPosition(self.model, self.data)
        xpos = self.body_xpos.copy()
        self.joint_qpos[:] = old_qpos
        self.forward()
        return xpos

    def get_id(self, obj_type, name):
        """ 
        Get numerical ID corresponding to object type and name. Useful for indexing arrays.
        """
        assert isinstance(
            obj_type, ObjType), '`obj_type` must be an instance of `ObjType`'
        return mj_name2id(self.model, obj_type.value - 1, encode(name))

    def get_name(self, obj_type, id):
        """ Get name corresponding to object id. """
        assert isinstance(obj_type, ObjType), type(obj_type)
        buff = mj_id2name(self.model, obj_type.value - 1, id)
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
            assert isinstance(
                obj_type, ObjType), '2nd argument must have type `ObjType`'
            return self.get_id(obj_type, key)
        else:
            assert isinstance(
                key, int), 'If 2nd argument is None, 1st argument must be `int`'
            return key

    def get_joint_id(self, key):
        if type(key) is str:
            key = self.get_id(ObjType.JOINT, key)
        return self.model.jnt_qposadr[key]

    def get_joint_qpos(self, key):
        """ Get qpos (joint values) of object corresponding to key. """
        return self.data.qpos[self.get_joint_id(key)]

    def get_joint_qvel(self, key):
        """ Get qvel (joint velocities) of object corresponding to key. """
        return self.data.qvel[self._key2id(key, ObjType.JOINT)]

    def get_geom_type(self, key):
        """ Get type of geom corresponding to key. """
        return self.model.geom_type[self._key2id(key, ObjType.JOINT)]

    def get_body_xpos(self, key):
        """ Get xpos (cartesian coordinates) of body corresponding to key. """
        return get_vec(3, self.body_xpos, self._key2id(key, ObjType.BODY))

    def get_body_xquat(self, key):
        """ Get quaternion of body corresponding to key. """
        return get_vec(4, self.body_xquat, self._key2id(key, ObjType.BODY))

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
    def actuator_ctrlrange(self):
        """ Range of controls (low, high). """
        return asarray( < double*> self.model.actuator_ctrlrange, self.model.nu * 2)

    @property
    def joint_qpos(self):
        """ Joint positions. """
        return asarray( < double*> self.data.qpos, self.nq)

    @property
    def joint_qvel(self):
        """ Joint velocities. """
        return asarray( < double*> self.data.qvel, self.nv)

    @property
    def actuator_ctrl(self):
        """ Joint actuations. """
        return asarray( < double*> self.data.ctrl, self.nu)

    @property
    def body_xpos(self):
        """ Cartesian coordinates of bodies. """
        return asarray( < double*> self.data.xpos, self.nbody * 3)

    @property
    def body_xquat(self):
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
