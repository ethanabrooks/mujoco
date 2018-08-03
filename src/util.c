#include "util.h"
#ifdef MJ_EGL
#include "utilEgl.h"
#elif defined(MJ_OSMESA)
#include "utilOsmesa.h"
#elif defined(MJ_GLFW)
#include "utilGlfw.h"
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

int addLabel(const char* label, const float* pos, State* s)
{
	mjvScene* scn = &(s->scn);
  
  if (scn->ngeom >= scn->maxgeom)
  {
    printf("Warning: reached max geoms %d\n", scn->maxgeom);
    return 1;
  }
  double mat [] = {1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0};
  mjvGeom *g = scn->geoms + scn->ngeom++;
  g->type = 104;  // label geom
  g->dataid = -1; // None
  g->objtype = 0; // unknown
  g->objid = -1;  // decor
  g->category = 4;  // decorative geom
  g->texid = -1; // no texture
  g->texuniform = 0;
  g->texrepeat[0] = 1;
  g->texrepeat[1] = 1;
  g->emission = 0;
  g->specular = 0.5;
  g->shininess = 0.5;
  g->reflectance = 0;
  memcpy(g->pos, pos, 3 * sizeof(float));
  memset(g->size, 0.1, 3 * sizeof(float));
  memset(g->rgba, 1, 4 * sizeof(float));
  memcpy(g->mat, mat, 9 * sizeof(float)); // cartesian orientation
  strncpy(g->label, label, 100);
  return 0;
}

int renderOffscreen(unsigned char *rgb, int height, int width, State * state)
{
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

//-------------------------------- main function ----------------------------------------

int main(int argc, const char **argv)
{
  if (argc != 3) {
    printf("Usage: /path/to/binary height width");
    exit(0);
  }
	int H = atoi(argv[1]);
	int W = atoi(argv[2]);
  /*char const *filepath = "../zero_shot/environment/models/pick-and-place/world.xml"; */
  char const *filepath = "xml/humanoid.xml";
	char const *keypath = "../.mujoco/mjkey.txt";
	State state;
#ifdef MJ_EGL
	initOpenGL();
#elif defined(MJ_OSMESA)
	OSMesaContext ctx;
	void *buffer;
	initOpenGL(&ctx, &buffer, H, W);
#elif defined(MJ_GLFW)
	GraphicsState graphicsState;
	initOpenGL(&graphicsState, &state, H, W);
#endif
	mj_activate(keypath);	// install GLFW mouse and keyboard callbacks
	printf("Initializing MuJoCo...\n");
	initMujoco(filepath, &state);
	mj_resetDataKeyframe(state.m, state.d, 0);

	printf("Allocating rgb and depth buffers...\n");
	unsigned char *rgb = (unsigned char *)malloc(3 * H * W);
	if (!rgb)
		mju_error("Could not allocate buffers\n");

	printf("Creating output rgb file...\n");
	FILE *fp = fopen("build/rgb.out", "wb");
	if (!fp)
		mju_error("Could not open rgbfile for writing");

	printf("Running simulation...\n");
	for (int i = 0; i < 100; i++) {
		setCamera(-1, &state);
		renderOffscreen(rgb, H, W, &state);
		fwrite(rgb, 3, H * W, fp);
#ifdef MJ_GLFW
		float pos1[] = { 0, 0, 0 };
		float pos2[] = { 0.2, 0, 0 };

		setCamera(0, &state);
		addLabel("1\n", pos1, &state);
		addLabel("2\n", pos2, &state);
		renderOnscreen(&graphicsState);
#endif
		state.d->ctrl[0] = 0.5;
		mj_step(state.m, state.d);
	}
	printf
	    ("ffmpeg -f rawvideo -pixel_format rgb24 -video_size %dx%d -framerate 60 -i build/rgb.out -vf 'vflip' build/video.mp4\n",
	     H, W);

	fclose(fp);
	free(rgb);
	printf("Closing MuJoCo...\n");
	closeMujoco(&state);
	printf("Closing OpenGL...\n");
#ifdef MJ_OSMESA
	closeOpenGL(ctx, buffer);
#else
	closeOpenGL();
#endif

	return 0;
}
