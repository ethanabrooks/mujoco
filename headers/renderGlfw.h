#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"

typedef struct GLFWwindow GraphicsState;

GraphicsState* initOpenGL(State * state);
int renderOnscreen(int camid, GraphicsState * window, State * state);

#endif
