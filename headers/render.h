#ifndef _RENDER_H
#define _RENDER_H

#include "mujoco.h"
#include "glfw3.h"

struct Foo {
  int bar;
};
mjModel* m;
mjData* d;

// MuJoCo visualization
mjvScene scn;
mjvCamera cam;
mjvOption opt;
mjrContext con;

GLFWwindow* initGlfw();
mjModel* loadModel(const char* filepath);
int initMujoco(mjModel* m, mjData* d, mjvScene* scn, 
    mjvCamera* cam, mjvOption* opt, mjrContext* con);
int renderOffscreen(unsigned char* rgb, int height, int width, mjModel* m, mjData* d,
    mjvScene* scn, mjrContext* con, mjvCamera* cam, mjvOption* opt);
int renderOnscreen(GLFWwindow* window, mjModel* m, mjData* d, 
    mjvScene* scn, mjrContext* con, mjvCamera* cam, mjvOption* opt);
int closeMujoco(mjModel* m, mjData* d, mjrContext* con, mjvScene* scn);

#endif
