# ifndef _RENDER_H
# define _RENDER_H

# include "mujoco.h"
# include "glfw3.h"

typedef struct render_context_t {
    mjvScene scn;
    mjrContext con;
    mjvCamera cam;
    mjvOption opt;
} RenderContext;

GLFWwindow * initGlfw();
mjModel * loadModel(const char * filepath);
int initMujoco(mjModel * m, mjData * d, RenderContext * context);
int renderOffscreen(int camid, unsigned char * rgb, int height, int width,
                    mjModel * m, mjData * d, RenderContext *);
int renderOnscreen(int camid, GLFWwindow * window,
                   mjModel * m, mjData * d, RenderContext * context);
int closeMujoco(mjModel * m, mjData * d, RenderContext * context);

# endif
