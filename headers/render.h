#ifndef _RENDER_H
#define _RENDER_H

#include "mujoco.h"
#include "glfw3.h"

typedef struct state_t {
  mjModel* m;
  mjData* d;
	mjvScene scn;
	mjrContext con;
	mjvCamera cam;
	mjvOption opt;
	int lastx;
	int lasty;
} State;

GLFWwindow *initGlfw();
int initMujoco(const char *filepath,State * state);
int renderOffscreen(int camid, unsigned char *rgb, 
    int height, int width, State *);
int renderOnscreen(int camid, GLFWwindow * window, State * state);
int closeMujoco(State * state);

#endif
