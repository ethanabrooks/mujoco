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
  /*State* state = (RenderContext*)glfwGetWindowUserPointer(window);*/
  /*mjvScene scn = state->scn;*/
  /*mjvCamera cam = state->cam;*/

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

mjModel *loadModel(const char *filepath)
{
	char error[1000] = "Could not load xml model";
	mjModel *m = mj_loadXML(filepath, 0, error, 1000);
	if (!m)
		mju_error_s("Load model error: %s", error);
	return m;
}

int initMujoco(State * state)
{
	/*mjvScene* scn, mjvCamera* cam, mjvOption* opt, mjrContext* con) { */
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

int renderOnscreen(int camid, GLFWwindow * window, State * state)
{

	setCamera(camid, state);

	mjvScene scn = state->scn;
	mjrContext con = state->con;
	mjvCamera cam = state->cam;
	mjvOption opt = state->opt;
	mjrRect rect = { 0, 0, 0, 0 };
	glfwGetFramebufferSize(window, &rect.width, &rect.height);

	mjr_setBuffer(mjFB_WINDOW, &con);
	if (con.currentBuffer != mjFB_WINDOW)
		printf("Warning: window rendering not supported\n");
	mjr_render(rect, &scn, &con);
	glfwSwapBuffers(window);
}

int renderOffscreen(int camid, unsigned char *rgb, 
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
	char const *filepath = "xml/humanoid.xml";
	char const *keypath = "../.mujoco/mjkey.txt";
	mjModel *m;
	mjData *d;
	State state;

	GLFWwindow *window = initGlfw();
	mj_activate(keypath);
	state.m = loadModel(filepath);
	state.d = mj_makeData(state.m);
	initMujoco(&state);

  // install GLFW mouse and keyboard callbacks
  /*glfwSetWindowUserPointer(window, &state);*/
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
		renderOffscreen(0, rgb, H, W, &state);
		fwrite(rgb, 3, H * W, fp);
		renderOnscreen(-1, window, &state);
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
