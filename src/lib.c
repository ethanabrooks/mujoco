#include "lib.h"
#ifdef MJ_EGL
#include "renderEgl.h"
#else
#include "renderGlfw.h"
#endif
#include "mujoco.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"

int initMujoco(const char *filepath, State * state)
{
	char error[1000] = "Could not load xml model";
	state->m = mj_loadXML(filepath, 0, error, 1000);
	if (!state->m)
		mju_error_s("Load model error: %s", error);
	state->d = mj_makeData(state->m);

	mj_forward(state->m, state->d);
	mjv_makeScene(&state->scn, 1000);
	mjv_defaultCamera(&state->cam);
	mjv_defaultOption(&state->opt);
	mjr_defaultContext(&state->con);
	mjr_makeContext(state->m, &state->con, 200);
}

int setCamera(int camid, State * state)
{
	mjvScene *scn = &(state->scn);
	mjvCamera *cam = &(state->cam);
	mjvOption *opt = &(state->opt);

	cam->fixedcamid = camid;
	if (camid == -1) {
		cam->type = mjCAMERA_FREE;
	} else {
		cam->type = mjCAMERA_FIXED;
	}

	mjv_updateScene(state->m, state->d, opt, NULL, cam, mjCAT_ALL, scn);
}

int
renderOffscreen(int camid, unsigned char *rgb,
		int height, int width, State * state)
{
	setCamera(camid, state);

	mjvScene scn = state->scn;
	mjrContext con = state->con;
	mjvCamera cam = state->cam;
	mjvOption opt = state->opt;
	mjrRect viewport = { 0, 0, height, width };

	// write offscreen-rendered pixels to file
	mjr_setBuffer(mjFB_OFFSCREEN, &con);
	if (con.currentBuffer != mjFB_OFFSCREEN)
		printf
		    ("Warning: offscreen rendering not supported, using default/window framebuffer\n");
	mjr_render(viewport, &scn, &con);
	mjr_readPixels(rgb, NULL, viewport, &con);
}

int closeMujoco(State * state)
{
	mjvScene scn = state->scn;
	mjrContext con = state->con;

	mj_deleteData(state->d);
	mj_deleteModel(state->m);
	mjr_freeContext(&con);
	mjv_freeScene(&scn);
	mj_deactivate();
}

//-------------------------------- main function ----------------------------------------

int main(int argc, const char **argv)
{
	int H = 800;
	int W = 800;
	/*char const *filepath = "../zero_shot/environment/models/navigate.xml"; */
	char const *filepath = "xml/humanoid.xml";
	char const *keypath = "../.mujoco/mjkey.txt";
	mjModel *m;
	mjData *d;
	State state;
#ifdef MJ_EGL
	initOpenGL();
#else
  GraphicsState window;
	initOpenGL(&window, &state);
#endif
	mj_activate(keypath);
	// install GLFW mouse and keyboard callbacks
	initMujoco(filepath, &state);

	// allocate rgb and depth buffers
	unsigned char *rgb = (unsigned char *)malloc(3 * H * W);
	if (!rgb)
		mju_error("Could not allocate buffers");

	// create output rgb file
	FILE *fp = fopen("build/rgb.out", "wb");
	if (!fp)
		mju_error("Could not open rgbfile for writing");

	// main loop
	for (int i = 0; i < 100; i++) {
		renderOffscreen(0, rgb, H, W, &state);
		fwrite(rgb, 3, H * W, fp);
#ifndef MJ_EGL
    renderOnscreen(-1, window, &state); 
#endif
		state.d->ctrl[0] = 0.5;
		mj_step(state.m, state.d);
	}
	printf
	    ("ffmpeg -f rawvideo -pixel_format rgb24 -video_size %dx%d -framerate 60 -i build/rgb.out -vf 'vflip' build/video.mp4\n",
	     H, W);

	fclose(fp);
	free(rgb);
	closeMujoco(&state);

	return 0;
}
