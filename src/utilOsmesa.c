#include <GL/osmesa.h>
#include "mujoco.h"
#include "utilOsmesa.h"
#include "util.h"

// create OpenGL context/window
int initOpenGL(OSMesaContext* ctx)
{
	*ctx = OSMesaCreateContextExt(GL_RGBA, 24, 8, 8, 0);
	if (!(*ctx)) {
		mju_error("OSMesa context creation failed");
  }

	// make current
  unsigned char buffer[10000000];
	if (!OSMesaMakeCurrent(*ctx, buffer, GL_UNSIGNED_BYTE, 800, 800)) {
		mju_error("OSMesa make current failed");
  }
	return 0;
}

// close OpenGL context/window
int closeOpenGL(OSMesaContext* ctx)
{
	OSMesaDestroyContext(*ctx);
	return 0;
}

int renderOnscreen(int camid, GraphicsState window, State * state)
{
	return 0;
}
