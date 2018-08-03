include "mujoco/sim.pyx"

import numpy as np
from cython cimport view
from codecs import encode
from pxd.util cimport setCamera, addLabel
from pxd.utilGlfw cimport GraphicsState, initOpenGL, closeOpenGL, \
        renderOnscreen, clearLastKey, clearMouseDy, clearMouseDx

cdef class SimGlfw(BaseSim):
    """
    Sim that uses GLFW functionality, which supports both offscreen and onscreen rendering.
    """
    cdef GraphicsState graphics_state

    def init_opengl(self, int height, int width):
        """ Initialize GLFW. """
        initOpenGL(&self.graphics_state, &self.state, height, width)

    def close_opengl(self):
        """ Does nothing, because glfwTerminate has a bug. """
        closeOpenGL()

    def render(self, str camera_name=None, dict labels=None):
        if camera_name is None:
            camid = -1
        else:
            camid = self.get_id(ObjType.CAMERA, camera_name)
        setCamera(camid, &self.state)

        if labels:
            self.add_labels(labels)

        return renderOnscreen(&self.graphics_state)

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
