#include <EGL/egl.h>
#include "mujoco.h"
#include "utilEgl.h"
#include "util.h"

// create OpenGL context / window
int 
initOpenGL()
{
	//desired config
	const EGLint	configAttribs[] = {
		EGL_RED_SIZE, 8,
		EGL_GREEN_SIZE, 8,
		EGL_BLUE_SIZE, 8,
		EGL_ALPHA_SIZE, 8,
		EGL_DEPTH_SIZE, 24,
		EGL_STENCIL_SIZE, 8,
		EGL_COLOR_BUFFER_TYPE, EGL_RGB_BUFFER,
		EGL_SURFACE_TYPE, EGL_PBUFFER_BIT,
		EGL_RENDERABLE_TYPE, EGL_OPENGL_BIT,
		EGL_NONE
	};

	//get default display
		EGLDisplay eglDpy = eglGetDisplay(EGL_DEFAULT_DISPLAY);
	if (eglDpy == EGL_NO_DISPLAY)
		mju_error_i("Could not get EGL display, error 0x%x\n",
			    eglGetError());

	//initialize
		EGLint major, minor;
	if (eglInitialize(eglDpy, &major, &minor) != EGL_TRUE)
		mju_error_i("Could not initialize EGL, error 0x%x\n",
			    eglGetError());

	//choose config
		EGLint numConfigs;
	EGLConfig	eglCfg;
	if (eglChooseConfig(eglDpy, configAttribs, &eglCfg, 1, &numConfigs) !=
	    EGL_TRUE)
		mju_error_i("Could not choose EGL config, error 0x%x\n",
			    eglGetError());

	//bind OpenGL API
		if (eglBindAPI(EGL_OPENGL_API) != EGL_TRUE)
		mju_error_i("Could not bind EGL OpenGL API, error 0x%x\n",
			    eglGetError());

	//create context
		EGLContext eglCtx =
		eglCreateContext(eglDpy, eglCfg, EGL_NO_CONTEXT, NULL);
	if (eglCtx == EGL_NO_CONTEXT)
		mju_error_i("Could not create EGL context, error 0x%x\n",
			    eglGetError());

	//make context current, no surface(let OpenGL handle FBO)
		if (eglMakeCurrent(eglDpy, EGL_NO_SURFACE, EGL_NO_SURFACE, eglCtx) !=
		    EGL_TRUE)
		mju_error_i("Could not make EGL context current, error 0x%x\n",
			    eglGetError());
	return 0;
}

//close OpenGL context / window
int 
closeOpenGL(void)
{
	//get current display
	EGLDisplay eglDpy = eglGetCurrentDisplay();
	if (eglDpy == EGL_NO_DISPLAY)
		return 1;

	//get current context
		EGLContext eglCtx = eglGetCurrentContext();

	//release context
		eglMakeCurrent(eglDpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

	//destroy context if valid
		if (eglCtx != EGL_NO_CONTEXT)
			eglDestroyContext(eglDpy, eglCtx);

	//terminate display
		eglTerminate(eglDpy);
	return 0;
}

int 
renderOnscreen(int camid, GraphicsState window, State * state)
{
	return 0;
}
