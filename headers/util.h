#ifndef _UTIL_H
#define _UTIL_H

#include "stdio.h"
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

typedef struct __sFILE FILE;

int openFile(FILE ** fp);
int closeFile(FILE ** fp);
int addLabel(const char* label, const float* pos, State* s);
int initMujoco(const char *filepath, State * state);
int setCamera(int camid, State * state);
int renderOffscreen(unsigned char *rgb, int height, int width, State * state, FILE ** fp);
int closeMujoco(State * state);

#endif
