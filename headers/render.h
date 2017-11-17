#ifndef _RENDER_H
#define _RENDER_H

#include "glfw3.h"
#include "lib.h"

int initGlfw(State *state);
int renderOnscreen(int camid, State * state);
int setCamera(int camid, State * state);

#endif
