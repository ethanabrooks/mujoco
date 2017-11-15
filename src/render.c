#include "render.h"
#include "mujoco.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "glfw3.h"

//-------------------------------- global data ------------------------------------------

// mouse button callback
/*void mouse_button(GLFWwindow * window, int button, int act, int mods)*/
/*{*/
  /*// update button state*/
  /*button_left =*/
      /*(glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS);*/
  /*button_middle =*/
      /*(glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE) ==*/
       /*GLFW_PRESS);*/
  /*button_right =*/
      /*(glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS);*/

  /*// update mouse position*/
  /*glfwGetCursorPos(window, &lastx, &lasty);*/
/*}*/

// mouse move callback
/*void mouse_move(GLFWwindow * window, double xpos, double ypos)*/
/*{*/
	/*// no buttons down: nothing to do*/
	/*if (!button_left && !button_middle && !button_right)*/
		/*return;*/

	/*// compute mouse displacement, save*/
	/*double dx = xpos - lastx;*/
	/*double dy = ypos - lasty;*/
	/*lastx = xpos;*/
	/*lasty = ypos;*/

	/*// get current window size*/
	/*int width, height;*/
	/*glfwGetWindowSize(window, &width, &height);*/

	/*// get shift key state*/
	/*bool mod_shift = (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS*/
				/*|| glfwGetKey(window,*/
					/*GLFW_KEY_RIGHT_SHIFT) == GLFW_PRESS);*/

	/*// determine action based on mouse button*/
	/*mjtMouse action;*/
	/*if (button_right)*/
		/*action = mod_shift ? mjMOUSE_MOVE_H : mjMOUSE_MOVE_V;*/
	/*else if (button_left)*/
		/*action = mod_shift ? mjMOUSE_ROTATE_H : mjMOUSE_ROTATE_V;*/
	/*else*/
		/*action = mjMOUSE_ZOOM;*/

	/*// move camera*/
	/*mjv_moveCamera(m, action, dx / height, dy / height, &scn, &cam);*/
/*}*/

// scroll callback
/*void scroll(GLFWwindow * window, double xoffset, double yoffset)*/
/*{*/
  /*RenderContext* context = (RenderContext*)glfwGetWindowUserPointer(window);*/
  /*mjvScene scn = context->scn;*/
  /*mjvCamera cam = context->cam;*/

  /*// emulate vertical mouse motion = 5% of window height*/
  /*mjv_moveCamera(m, mjMOUSE_ZOOM, 0, -0.05 * yoffset, &scn, &cam);*/
/*}*/

GLFWwindow *initGlfw()
{
	if (!glfwInit())
		mju_error("Could not initialize GLFW");

	// create visible window, double-buffered
	glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);
	glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);
	GLFWwindow *window =
	    glfwCreateWindow(800, 800, "Visible window", NULL, NULL);
	if (!window)
		mju_error("Could not create GLFW window");

	glfwMakeContextCurrent(window);

	// install GLFW mouse and keyboard callbacks
	/*glfwSetCursorPosCallback(window, mouse_move);*/
	/*glfwSetMouseButtonCallback(window, mouse_button);*/
  /*glfwSetScrollCallback(window, scroll);*/

	return window;
}


int initMujoco(const char* filepath, RenderContext * context)
{
	char error[1000] = "Could not load xml model";
  mjModel *m = &(context->m);
  mjData *d = &(context->d);

	m = mj_loadXML(filepath, 0, error, 1000);
	if (!m)
		mju_error_s("Load model error: %s", error);

  d = mj_makeData(m);
	mj_forward(m, d);
	mjv_makeScene(&context->scn, 1000);
	mjv_defaultCamera(&context->cam);
	mjv_defaultOption(&context->opt);
	mjr_defaultContext(&context->con);
	mjr_makeContext(m, &context->con, 200);
}

int setCamera(int camid, mjModel * m, mjData * d, RenderContext * context)
{
	mjvScene *scn = &(context->scn);
	mjvCamera *cam = &(context->cam);
	mjvOption *opt = &(context->opt);

	cam->fixedcamid = camid;
	if (camid == -1) {
		cam->type = mjCAMERA_FREE;
	} else {
		cam->type = mjCAMERA_FIXED;
	}

	mjv_updateScene(m, d, opt, NULL, cam, mjCAT_ALL, scn);
}

int renderOnscreen(int camid, GLFWwindow * window, mjModel * m, mjData * d,
		   RenderContext * context)
{

	setCamera(camid, m, d, context);

	mjvScene scn = context->scn;
	mjrContext con = context->con;
	mjvCamera cam = context->cam;
	mjvOption opt = context->opt;
	mjrRect rect = { 0, 0, 0, 0 };
	glfwGetFramebufferSize(window, &rect.width, &rect.height);

	mjr_setBuffer(mjFB_WINDOW, &con);
	if (con.currentBuffer != mjFB_WINDOW)
		printf("Warning: window rendering not supported\n");
	mjr_render(rect, &scn, &con);
	glfwSwapBuffers(window);
}

int renderOffscreen(int camid, unsigned char *rgb, int height, int width,
		    mjModel * m, mjData * d, RenderContext * context)
{
	setCamera(camid, m, d, context);

	mjvScene scn = context->scn;
	mjrContext con = context->con;
	mjvCamera cam = context->cam;
	mjvOption opt = context->opt;
	mjrRect viewport = { 0, 0, height, width };

	// write offscreen-rendered pixels to file
	mjr_setBuffer(mjFB_OFFSCREEN, &con);
	if (con.currentBuffer != mjFB_OFFSCREEN)
		printf
		    ("Warning: offscreen rendering not supported, using default/window framebuffer\n");
	mjr_render(viewport, &scn, &con);
	mjr_readPixels(rgb, NULL, viewport, &con);
}

int closeMujoco(RenderContext * context)
{
  mjModel *m = &(context->m);
  mjData *d = &(context->d);
	mjvScene scn = context->scn;
	mjrContext con = context->con;

	mj_deleteData(d);
	mj_deleteModel(m);
	mjr_freeContext(&con);
	mjv_freeScene(&scn);
	mj_deactivate();
}

//-------------------------------- main function ----------------------------------------

int main(int argc, const char **argv)
{
	int H = 800;
	int W = 800;
	char const *filepath = "xml/humanoid.xml";
	char const *keypath = "../.mujoco/mjkey.txt";
	RenderContext context;

	GLFWwindow *window = initGlfw();
	mj_activate(keypath);
	initMujoco(filepath, &context);

  // install GLFW mouse and keyboard callbacks
  glfwSetWindowUserPointer(window, &context);
  /*glfwSetKeyCallback(window, keyboard);*/
  /*glfwSetCursorPosCallback(window, mouse_move);*/
  /*glfwSetMouseButtonCallback(window, mouse_button);*/
  /*glfwSetScrollCallback(window, scroll);*/


	// allocate rgb and depth buffers
	unsigned char *rgb = (unsigned char *)malloc(3 * H * W);
	if (!rgb)
		mju_error("Could not allocate buffers");

	// create output rgb file
	FILE *fp = fopen("build/rgb.out", "wb");
	if (!fp)
		mju_error("Could not open rgbfile for writing");

	// main loop
	for (int i = 0; i < 10; i++) {
		renderOffscreen(0, rgb, H, W, &(context.m), &(context.d), &context);
		fwrite(rgb, 3, H * W, fp);
		renderOnscreen(-1, window, &(context.m), &(context.d), &context);
		mj_step(&(context.m), &(context.d));
	}
	printf
	    ("ffmpeg -f rawvideo -pixel_format rgb24 -video_size %dx%d -framerate 60 -i build/rgb.out -vf 'vflip' build/video.mp4\n",
	     H, W);

	fclose(fp);
	free(rgb);
	closeMujoco(&context);

	return 0;
}
