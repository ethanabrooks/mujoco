#ifndef _RENDER_H
#define _RENDER_H

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


int initOpenGL(State *state);
int renderOnscreen(int camid, State * state);
int setCamera(int camid, State * state);

#endif
