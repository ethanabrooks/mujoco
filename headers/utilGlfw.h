#ifndef _UTILGLFW_H
#define _UTILGLFW_H

#include "glfw3.h"
#include "util.h"
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

int addLabel(const char* label, const float* pos, State* s);
int clearLastKey(GraphicsState* state);
int clearMouseDx(GraphicsState* state);
int clearMouseDy(GraphicsState* state);
int initOpenGL(GraphicsState *, State *);
int closeOpenGL(void);
int renderOnscreen(GraphicsState* state);

#endif
