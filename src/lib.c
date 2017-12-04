#include "lib.h"
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
	return 0;
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
	return 0;
}

int
renderOffscreen(int camid, unsigned char *rgb,
		int height, int width, State * state)
{
	setCamera(camid, state);

	mjvScene scn = state->scn;
	mjrContext con = state->con;
	mjrRect viewport = { 0, 0, height, width };

	// write offscreen-rendered pixels to file
	mjr_setBuffer(mjFB_OFFSCREEN, &con);
	if (con.currentBuffer != mjFB_OFFSCREEN)
		printf
		    ("Warning: offscreen rendering not supported, using default/window framebuffer\n");
	mjr_render(viewport, &scn, &con);
	mjr_readPixels(rgb, NULL, viewport, &con);
	return 0;
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
	return 0;
}
