#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"

GLFWwindow *initGlfw(State *state);
int renderOnscreen(int camid, GLFWwindow * window, State * state);

#endif
