#ifndef _RENDER_H
#define _RENDER_H

#include "EGL/egl.h"
#include "mujoco.h"

typedef void GraphicsState;

int initOpenGL(GraphicsState *, State *);

#endif
