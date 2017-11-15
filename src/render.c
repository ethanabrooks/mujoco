#include "render.h"
#include "mujoco.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "glfw3.h"

//-------------------------------- global data ------------------------------------------

// keyboard callback
void keyboard(GLFWwindow * window, int key, int scancode, int act, int mods)
{
	State *state = (State *) glfwGetWindowUserPointer(window);
	// backspace: reset simulation
	if (act == GLFW_PRESS && key == GLFW_KEY_BACKSPACE) {
		mj_resetData(state->m, state->d);
		mj_forward(state->m, state->d);
	}
}

// mouse button callback
void mouse_button(GLFWwindow * window, int button, int act, int mods)
{
	State *state = (State *) glfwGetWindowUserPointer(window);

	// update button state 
	state->button_left =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS);
	state->button_middle =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE) ==
	     GLFW_PRESS);
	state->button_right =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS);

	// update mouse position 
	glfwGetCursorPos(window, &(state->lastx), &(state->lasty));
}

// mouse move callback
void mouse_move(GLFWwindow * window, double xpos, double ypos)
{
	State *state = (State *) glfwGetWindowUserPointer(window);

	// no buttons down: nothing to do 
	if (!state->button_left && !state->button_middle && !state->button_right)
		return;

	// compute mouse displacement, save 
	double dx = xpos - state->lastx;
	double dy = ypos - state->lasty;
	state->lastx = xpos;
	state->lasty = ypos;

	// get current window size 
	int width, height;
	glfwGetWindowSize(window, &width, &height);

	// get shift key state 
	int mod_shift = (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS
			  || glfwGetKey(window,
					GLFW_KEY_RIGHT_SHIFT) == GLFW_PRESS);

	// determine action based on mouse button 
	mjtMouse action;
	if (state->button_right)
		action = mod_shift ? mjMOUSE_MOVE_H : mjMOUSE_MOVE_V;
	else if (state->button_left)
		action = mod_shift ? mjMOUSE_ROTATE_H : mjMOUSE_ROTATE_V;
	else
		action = mjMOUSE_ZOOM;

	// move camera 
	mjv_moveCamera(state->m, action, dx / height, dy / height, &(state->scn), &(state->cam));
}

// scroll callback
void scroll(GLFWwindow * window, double xoffset, double yoffset)
{
	State *state = (State *) glfwGetWindowUserPointer(window);

	// emulate vertical mouse motion = 5% of window height
	mjv_moveCamera(state->m, mjMOUSE_ZOOM, 0, -0.05 * yoffset,
		       &(state->scn), &(state->cam));
}

GLFWwindow *initGlfw(State *state)
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

  state->button_left = 0;
  state->button_middle = 0;
  state->button_right = 0;

	// install GLFW mouse and keyboard callbacks
	glfwSetWindowUserPointer(window, state);
	glfwSetKeyCallback(window, keyboard);
  glfwSetCursorPosCallback(window, mouse_move); 
  glfwSetMouseButtonCallback(window, mouse_button); 
	glfwSetScrollCallback(window, scroll);

	return window;
}

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
	glfwPollEvents();
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
	char const *filepath = "xml/humanoid.xml";
	char const *keypath = "../.mujoco/mjkey.txt";
	mjModel *m;
	mjData *d;
	State state;

	GLFWwindow *window = initGlfw(&state);
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
	for (int i = 0; i < 10000; i++) {
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
