#include "render.h"
#include "lib.h"
#include "glfw3.h"
#include "stdio.h"

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
	if (!state->button_left && !state->button_middle
	    && !state->button_right)
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
	mjv_moveCamera(state->m, action, dx / height, dy / height,
		       &(state->scn), &(state->cam));
}

// scroll callback
void scroll(GLFWwindow * window, double xoffset, double yoffset)
{
	State *state = (State *) glfwGetWindowUserPointer(window);

	// emulate vertical mouse motion = 5% of window height
	mjv_moveCamera(state->m, mjMOUSE_ZOOM, 0, -0.05 * yoffset,
		       &(state->scn), &(state->cam));
}

int initGlfw(State * state)
{
	if (!glfwInit())
		mju_error("Could not initialize GLFW");

	// create visible window, double-buffered glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);
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

	state->window = window;
}

int renderOnscreen(int camid, State * state)
{

	setCamera(camid, state);

	mjvScene scn = state->scn;
	mjrContext con = state->con;
	mjvCamera cam = state->cam;
	mjvOption opt = state->opt;
	mjrRect rect = { 0, 0, 0, 0 };
	glfwGetFramebufferSize(state->window, &rect.width, &rect.height);

	mjr_setBuffer(mjFB_WINDOW, &con);
	if (con.currentBuffer != mjFB_WINDOW)
		printf("Warning: window rendering not supported\n");
	mjr_render(rect, &scn, &con);
	glfwSwapBuffers(state->window);
	glfwPollEvents();
}
