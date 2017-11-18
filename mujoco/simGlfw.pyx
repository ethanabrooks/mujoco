from mujoco.sim cimport Sim
from pxd.renderGlfw cimport GraphicsState, initOpenGL

cdef class Child(Sim):
    cdef GraphicsState graphics_state2

    def init_opengl(self):
        initOpenGL(&self.graphics_state2, &self.state)

    def render(self, camera_name=None):
        raise NotImplemented
        # if camera_name is None:
            # camid = -1
        # else:
            # camid = self.get_id(ObjType.CAMERA, camera_name)
        # return renderOnscreen(camid, self.graphics_state, & self.state)
