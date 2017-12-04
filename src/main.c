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

int main(int argc, const char **argv)
{
	int H = 800;
	int W = 800;
  char const *filepath = "../zero_shot/environment/models/pick-and-place/world.xml"; 
	/*char const *filepath = "xml/humanoid.xml";*/
	char const *keypath = "../.mujoco/mjkey.txt";
	State state;
#ifdef MJ_EGL
	initOpenGL();
#else
	GraphicsState graphicsState;
	initOpenGL(&graphicsState, &state);
#endif
	mj_activate(keypath);
	// install GLFW mouse and keyboard callbacks
	initMujoco(filepath, &state);
	mj_resetDataKeyframe(state.m, state.d, 0);

	// allocate rgb and depth buffers
	unsigned char *rgb = (unsigned char *)malloc(3 * H * W);
	if (!rgb)
		mju_error("Could not allocate buffers");

	// create output rgb file
	FILE *fp = fopen("build/rgb.out", "wb");
	if (!fp)
		mju_error("Could not open rgbfile for writing");

	// main loop
	for (int i = 0; i < 10000; i++) {
		renderOffscreen(0, rgb, H, W, &state);
		fwrite(rgb, 3, H * W, fp);
#ifndef MJ_EGL
		renderOnscreen(-1, &graphicsState);
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
