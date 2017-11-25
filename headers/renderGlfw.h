#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"
#include "pthread.h"

typedef struct graphics_state_t {
  State* state;
  GLFWwindow* window;
  pthread_mutex_t mutex;
  int buttonLeft;
  int buttonMiddle;
  int buttonRight;
	double mouseLastX;
	double mouseLastY;
	double mouseDx;
	double mouseDy;
  char lastKeyPress;
} GraphicsState;

//typedef GLFWwindow* GraphicsState;

int clearLastKey(GraphicsState* state);
int clearMouseDx(GraphicsState* state);
int clearMouseDy(GraphicsState* state);
int initOpenGL(GraphicsState *, State *);
int closeOpenGL(void);
int renderOnscreen(int camid, GraphicsState* state);

#endif
