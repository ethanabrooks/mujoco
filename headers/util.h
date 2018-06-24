#ifndef _UTIL_H
#define _UTIL_H

#include "glfw3.h"
#include "mujoco.h"

typedef struct state_t {
	mjModel *m;
	mjData *d;
	mjvScene scn;
	mjrContext con;
	mjvCamera cam;
	mjvOption opt;
} State;

int initMujoco(const char *filepath, State * state);
int setCamera(int camid, State * state);
int renderOffscreen(unsigned char *rgb, int height, int width, State *);
int closeMujoco(State * state);
int count_zeros(unsigned char *rgb, size_t size);

#endif
