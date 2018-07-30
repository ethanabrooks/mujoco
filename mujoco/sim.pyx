import os
from os.path import join, expanduser
from codecs import encode, decode
from enum import Enum
from libc.string cimport strncpy
from cython cimport view
from pxd.mujoco cimport mj_activate, mj_makeData, mj_step, mj_id2name, \
        mj_name2id, mj_resetData, mj_forward, mj_fwdPosition, mj_jacBody
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
               start=0,
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
               start=0,
                module=__name__)

"""
``enum`` of different MuJoCo ``geom`` types (corresponds to ``mjtGeom``).
"""
JointType = Enum('JointType',
        (
            ' mjJNT_FREE'  # global position and orientation (quat)       (7)
            ' mjJNT_BALL'  # orientation (quat) relative to parent        (4)
            ' mjJNT_SLIDE' # sliding distance along body-fixed axis       (1)
            ' mjJNT_HINGE' # rotation angle (rad) around body-fixed axis  (1)
        ),
               start=0,
        module=__name__)


cdef as_double_array(double * ptr, size_t size):
    """ Convenience function for converting a pointer to an array of length ``size``"""
    cdef double[:] view = <double[:size] > ptr
    return np.asarray(view)

cdef as_int_array(int * ptr, size_t size):
    """ Convenience function for converting a pointer to an array of length ``size``"""
    cdef int[:] view = <int[:size] > ptr
    return np.asarray(view)


def get_vec(int size, np.ndarray array, int n):
    return array[n * size: (n + 1) * size]

def check_ObjType(obj, argnum):
    assert isinstance(obj, ObjType), \
            'arg {} must be an instance of `ObjType`'.format(argnum)

def activate():
    mj_activate(MJKEY_PATH)


cdef class BaseSim(object):
    """ Base class for the EGL `Sim` and the GLFW `Sim` to inherit from. """

    cdef mjData * data
    cdef mjModel * model
    cdef State state
    cdef int forward_called_this_step
    cdef int n_substeps
    cdef int height
    cdef int width

    def __cinit__(self, str fullpath, 
            int height = 0, int width = 0, 
            int n_substeps = 1):
        """ Activate MuJoCo, initialize OpenGL, load model from xml, and initialize MuJoCo structs.

        Args:
            fullpath (str): full path to model xml file.
            height (int): height of image for rendering.
            width (int): width of image for rendering.
        """
        self.height = height or 800
        self.width = width or 800
        assert self.height > 0 and self.width > 0
        self.init_opengl(height or 800, width or 800)
        initMujoco(encode(fullpath), & self.state)
        self.model = self.state.m
        self.data = self.state.d
        self.n_substeps=n_substeps

    def __enter__(self):
        return self

    def __exit__(self, *args):
        closeMujoco(& self.state)

    def render(self, str camera_name=None, dict labels=None):
        """
        Display the view from camera corresponding to ``camera_name`` in an onscreen GLFW window.
        ``labels`` must be a dict of ``{label: pos}``, where ``label`` is a value that can be
        cast to a ``str`` and ``pos`` is a ``list``, ``tuple``, or ``ndarray`` with elements
        corresponding to ``(x, y, z)``.
        """
        raise RuntimeError("`render` method is only defined for the GLFW version.")

    def render_offscreen(self, camera_name=None, camera_id=None, int grayscale=False):
        """
        Args:
            camera_name (str): Name of camera, as specified in xml file.

        Returns:
            ``height`` x ``width`` image from camera with name ``camera_name``
        """
        if camera_name is not None:
            camera_id = self.name2id(ObjType.CAMERA, camera_name)
        elif camera_id is None:
            camera_id = -1
        array = np.zeros(self.height * self.width * 3, dtype=np.uint8)
        cdef unsigned char[::view.contiguous] view = array
        setCamera(camera_id, & self.state)
        renderOffscreen(& view[0], self.width, self.height, & self.state)
        array = array.reshape(self.height, self.width, 3)
        array = np.flip(array, 0)
        if grayscale:
            return array.mean(axis=2)
        else:
            return array

    def step(self):
        """ Advance simulation one timestep. """
        for _ in range(self.n_substeps):
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
        id = mj_name2id(self.model, obj_type.value, encode(name))
        if id < 0:
            raise RuntimeError("name", name, "not found in model")
        return id

    def id2name(self, obj_type, id):
        """ Get name corresponding to object id. """
        check_ObjType(obj_type, argnum=1)
        buff = mj_id2name(self.model, obj_type.value, id)
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
        assert isinstance(
            key, int), 'If 2nd argument is None, 1st argument must be `int`'
        return key

    def get_jnt_qposadr(self, key):
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

    def get_body_jacr(self, key):
        id = self._key2id(key, ObjType.BODY)
        cdef np.ndarray[double, ndim=1, mode='c'] jacr = np.zeros(3 * self.nv)
        cdef double * jacr_view = &jacr[0]
        mj_jacBody(self.model, self.data, jacr_view, NULL, id)
        return jacr

    def get_body_jacp(self, key):
        id = self._key2id(key, ObjType.BODY)
        cdef np.ndarray[double, ndim=1, mode='c'] jacp = np.zeros(3 * self.nv)
        cdef double * jacp_view = &jacp[0]
        mj_jacBody(self.model, self.data, jacp_view, NULL, id)
        return jacp

    def get_body_xvelr(self, key):
        id = self._key2id(key, ObjType.BODY)
        jacr = self.get_body_jacr(key).reshape((3, self.nv))
        xvelr = np.dot(jacr, self.qvel)
        return xvelr

    def get_body_xvelp(self, key):
        id = self._key2id(key, ObjType.BODY)
        jacp = self.get_body_jacp(key).reshape((3, self.nv))
        xvelp = np.dot(jacp, self.qvel)
        return xvelp

    def get_body_xpos(self, key, qpos=None):
        """ Get xpos (cartesian coordinates) of body corresponding to key. """
        if qpos is None:
            xpos = self.xpos
        else:
            xpos = self.qpos_to_xpos(qpos)
        return get_vec(3, xpos, self._key2id(key, ObjType.BODY))

    def get_body_xmat(self, key):
        """ Get xpos (cartesian coordinates) of body corresponding to key. """
        return get_vec(9, self.xmat, self._key2id(key, ObjType.BODY)).reshape((3, 3))

    def get_body_xquat(self, key):
        """ Get quaternion of body corresponding to key. """
        return get_vec(4, self.xquat, self._key2id(key, ObjType.BODY))

    def get_geom_size(self, key):
        """ Get size of geom corresponding to key. """
        return get_vec(3, self.geom_size, self._key2id(key, ObjType.GEOM))

    def get_geom_pos(self, key):
        """ Get position of geom corresponding to key. """
        return get_vec(3, self.geom_pos, self._key2id(key, ObjType.GEOM))

    def get_dof_jntid(self, key):
        """ joint type """
        if type(key) is str:
            key = self.name2id(ObjType.JOINT, key)
        return self.model.dof_jntid[key]

    def get_jnt_type(self, key):
        """ joint type """
        if type(key) is str:
            key = self.name2id(ObjType.JOINT, key)
        type_number = self.model.jnt_type[key]
        return next(j.name for j in JointType if j.value == type_number)

    @property
    def nsubsteps(self):
        return self.n_substeps

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
    def na(self):
        """ Number of activation states. """
        return self.model.na

    @property
    def nu(self):
        """ Number of actuators/controls. """
        return self.model.nu

    @property
    def njnt(self):
        """ Number of joints. """
        return self.model.njnt

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
        return as_double_array( < double*> self.model.actuator_ctrlrange,
                       self.model.nu * 2).reshape(-1, 2)

    @property
    def qpos(self):
        """ Joint positions. """
        return as_double_array( < double*> self.data.qpos, self.nq)

    @property
    def qvel(self):
        """ Joint velocities. """
        return as_double_array( < double*> self.data.qvel, self.nv)

    @property
    def act(self):
        """ Actuator activation. """
        return as_double_array( < double*> self.data.act, self.na)

    @property
    def ctrl(self):
        """ Joint actuations. """
        return as_double_array( < double*> self.data.ctrl, self.nu)

    @property
    def xpos(self):
        """ Cartesian coordinates of bodies. """
        return as_double_array( < double*> self.data.xpos, self.nbody * 3)

    @property
    def xquat(self):
        """ Quaternions of bodies. """
        return as_double_array( < double*> self.data.xquat, self.nbody * 4)

    @property
    def xmat(self):
        """ Cartesian coordinates of bodies. """
        return as_double_array( < double*> self.data.xmat, self.nbody * 9)

    @property
    def jacp(self):
        return as_int_array( < int*> self.model.jnt_type, self.njnt)

    @property
    def jacr(self):
        jacrs = np.zeros((self.nbody, 3 * self.nv))
        cdef double [:] jacr_view
        for i, jacr in enumerate(jacrs):
            jacr_view = jacr
            mj_jacBody(self.model, self.data, NULL, &jacr_view[0], i)
        return jacrs

    @property
    def sensordata(self):
        """ Quaternions of bodies. """
        return as_double_array( < double*> self.data.sensordata, self.nsensordata)

    @property
    def geom_size(self):
        """ Sizes of geoms. """
        return as_double_array( < double*> self.model.geom_size, self.ngeom * 3)

    @property
    def geom_pos(self):
        """ Positions of geoms. """
        return as_double_array( < double*> self.model.geom_pos, self.ngeom * 3)

    @property
    def mocap_pos(self):
        """ Positions of mocap bodies. """
        return as_double_array( < double*> self.data.mocap_pos, self.nmocap * 3)

    @property
    def mocap_quat(self):
        """ Quaternions of mocap bodies. """
        return as_double_array( < double*> self.data.mocap_quat, self.nmocap * 4)

    @property
    def qfrc_actuator(self):
        """ actuator force. """
        return as_double_array( < double*> self.data.qfrc_actuator, self.nv)

    @property
    def qfrc_unc(self):
        """ net unconstrained force """
        return as_double_array( < double*> self.data.qfrc_unc, self.nv)

    @property
    def qfrc_constraint(self):
        """ net unconstrained force """
        return as_double_array( < double*> self.data.qfrc_constraint, self.nv)

    @property
    def jnt_range(self):
        """ joint range """
        array = as_double_array( <double*> self.model.jnt_range, self.njnt * 2)
        return array.reshape(-1, 2)

    @property
    def jnt_limited(self):
        """ joint limits """
        cdef unsigned char[:] view = <unsigned char[:self.njnt]> self.model.jnt_limited
        return np.asarry(view)

    @property
    def jnt_qposadr(self):
        """ indices of each joint in qpos """
        return as_int_array( < int*> self.model.jnt_qposadr, self.njnt)

    @property
    def jnt_type(self):
        return as_int_array( < int*> self.model.jnt_type, self.njnt)
