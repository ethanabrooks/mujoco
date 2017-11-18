from mujoco.sim cimport BaseSim
from mujoco.sim import ObjType
from pxd.renderGlfw cimport GraphicsState, initOpenGL, renderOnscreen

cdef class Sim(BaseSim):
    cdef GraphicsState graphics_state

    def init_opengl(self):
        initOpenGL(&self.graphics_state, &self.state)

    def render(self, camera_name=None):
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(ObjType.CAMERA, camera_name)
        return renderOnscreen(camid, self.graphics_state, & self.state)
