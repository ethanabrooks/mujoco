from mujoco.sim cimport BaseSim
from mujoco.sim import ObjType
from pxd.simGlfw cimport GraphicsState, initOpenGL, closeOpenGL, renderOnscreen, clearLastKey, clearMouseDy, clearMouseDx

cdef class Sim(BaseSim):
    """ 
    Sim that uses GLFW functionality, which supports both offscreen and onscreen rendering.
    """
    cdef GraphicsState graphics_state

    def init_opengl(self):
        """ Initialize GLFW. """
        initOpenGL(&self.graphics_state, &self.state)

    def close_opengl(self):
        """ Does nothing, because glfwTerminate has a bug. """
        closeOpenGL()

    def render(self, camera_name=None):
        """
        Display the view from camera corresponding to ``camera_name`` in an onscreen GLFW window. 
        """
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(ObjType.CAMERA, camera_name)
        return renderOnscreen(camid, &self.graphics_state)

    def get_last_key_press(self):
        if self.graphics_state.lastKeyPress:
            key = chr(self.graphics_state.lastKeyPress)
            clearLastKey(&self.graphics_state)
            return key

    def get_mouse_dx(self):
        mouse_dx = self.graphics_state.mouseDx
        clearMouseDx(&self.graphics_state)
        return mouse_dx

    def get_mouse_dy(self):
        mouse_dy = self.graphics_state.mouseDy
        clearMouseDy(&self.graphics_state)
        return mouse_dy
