#ifndef _RENDER_H
#define _RENDER_H

#include "EGL/egl.h"
#include "mujoco.h"
#include "lib.h"

typedef int GraphicsState;

int initOpenGL();
int renderOnscreen(int camid, GraphicsState window, State * state);

#endif
