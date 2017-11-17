#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"

typedef GLFWwindow* GraphicsState;

int initOpenGL(GraphicsState *, State *);
int renderOnscreen(int camid, GraphicsState window, State * state);

#endif
