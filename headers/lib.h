#ifndef _LIB_H
#define _LIB_H

#include "glfw3.h"
#include "mujoco.h"

typedef struct state_t {
  GLFWwindow *window;
	mjModel *m;
	mjData *d;
	mjvScene scn;
	mjrContext con;
	mjvCamera cam;
	mjvOption opt;
  int button_left;
  int button_middle;
  int button_right;
	double lastx;
	double lasty;
} State;

int initMujoco(const char *filepath, State * state);
int renderOffscreen(int camid, unsigned char *rgb,
		    int height, int width, State *);
int closeMujoco(State * state);

#endif
