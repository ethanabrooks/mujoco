#ifndef _LIB_H
#define _LIB_H

#include "glfw3.h"
#include "render.h"
#include "mujoco.h"

int initMujoco(const char *filepath, State * state);
int renderOffscreen(int camid, unsigned char *rgb,
		    int height, int width, State *);
int closeMujoco(State * state);

#endif
