#ifndef _UTILOSMESA_H
#define _UTILOSMESA_H

#include <GL/osmesa.h>
#include "mujoco.h"
#include "util.h"

typedef int GraphicsState;

int initOpenGL(OSMesaContext*);
int closeOpenGL(OSMesaContext*);
int renderOnscreen(int camid, GraphicsState window, State * state);

#endif
