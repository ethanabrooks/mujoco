#ifndef _UTILEGL_H
#define _UTILEGL_H

#include "EGL/egl.h"
#include "mujoco.h"
#include "util.h"

typedef int GraphicsState;

int initOpenGL(void);
int closeOpenGL(void);
int renderOnscreen(int camid, GraphicsState window, State * state);

#endif
