#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"

#ifndef USE_GLFW
  GLFWwindow *initGlfw(State *state);
  int renderOnscreen(int camid, GLFWwindow * window, State * state);
#else

#endif
int setCamera(int camid, State * state);

#endif
