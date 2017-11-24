#ifndef _LIB_H
#define _LIB_H

#include "glfw3.h"
#include "mujoco.h"

typedef struct state_t {
	mjModel *m;
	mjData *d;
	mjvScene scn;
	mjrContext con;
	mjvCamera cam;
	mjvOption opt;
  //int buttonLeft;
  //int buttonMiddle;
  //int buttonRight;
	//double mouseLastX;
	//double mouseLastY;
	//double mouseDx;
	//double mouseDy;
  //char lastKeyPress;
} State;

int initMujoco(const char *filepath, State * state);
int setCamera(int camid, State * state);
int renderOffscreen(int camid, unsigned char *rgb,
		    int height, int width, State *);
int closeMujoco(State * state);

#endif
