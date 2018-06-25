#include <GL/osmesa.h>
#include "mujoco.h"
#include "utilOsmesa.h"
#include "util.h"
#include "stdio.h"

// create OpenGL context / window
int 
initOpenGL(OSMesaContext * ctx, void **buffer, int h, int w)
{
	*buffer = malloc(10000000 * sizeof(unsigned char));
	//create context
		* ctx = OSMesaCreateContextExt(GL_RGBA, 24, 8, 8, 0);
	if (!*ctx)
		mju_error("OSMesa context creation failed");

	//make current
		if (!OSMesaMakeCurrent(*ctx, *buffer, GL_UNSIGNED_BYTE, h, w))
		mju_error("OSMesa make current failed");
	return 0;
}

//close OpenGL context / window
int 
closeOpenGL(OSMesaContext ctx, void *buffer)
{
	free(buffer);
	OSMesaDestroyContext(ctx);
	return 0;
}

int 
renderOnscreen(int camid, GraphicsState window, State * state)
{
	return 0;
}
