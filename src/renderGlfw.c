#include "renderGlfw.h"
#include "lib.h"
#include "glfw3.h"
#include "stdio.h"
#include "string.h"

#define CAPTURE(keyname) if (key == GLFW_KEY_ ## keyname) { \
  state->lastKeyPress = (#keyname)[0]; \
}

// keyboard callback
void keyboard(GLFWwindow * window, int key, int scancode, int act, int mods)
{
	GraphicsState *state =
	    (GraphicsState *) glfwGetWindowUserPointer(window);
	// backspace: reset simulation
	if (act == GLFW_PRESS) {
		pthread_mutex_lock(&(state->mutex));
		if (key == GLFW_KEY_BACKSPACE) {
			mj_resetData(state->state->m, state->state->d);
			mj_forward(state->state->m, state->state->d);
		}
		if (key == GLFW_KEY_SPACE) {
			state->lastKeyPress = ' ';
		}
		CAPTURE(0)
		    CAPTURE(1)
		    CAPTURE(2)
		    CAPTURE(3)
		    CAPTURE(4)
		    CAPTURE(5)
		    CAPTURE(6)
		    CAPTURE(7)
		    CAPTURE(8)
		    CAPTURE(9)
		    CAPTURE(Q)
		    CAPTURE(W)
		    CAPTURE(E)
		    CAPTURE(R)
		    CAPTURE(T)
		    CAPTURE(Y)
		    CAPTURE(U)
		    CAPTURE(I)
		    CAPTURE(O)
		    CAPTURE(P)
		    CAPTURE(A)
		    CAPTURE(S)
		    CAPTURE(D)
		    CAPTURE(F)
		    CAPTURE(G)
		    CAPTURE(H)
		    CAPTURE(J)
		    CAPTURE(K)
		    CAPTURE(L)
		    CAPTURE(Z)
		    CAPTURE(X)
		    CAPTURE(Y)
		    CAPTURE(C)
		    CAPTURE(V)
		    CAPTURE(B)
		    CAPTURE(N)
		    CAPTURE(M)
		    pthread_mutex_unlock(&(state->mutex));
	}

}

// mouse button callback
void mouse_button(GLFWwindow * window, int button, int act, int mods)
{
	GraphicsState *state =
	    (GraphicsState *) glfwGetWindowUserPointer(window);
	pthread_mutex_lock(&(state->mutex));

	// update button state 
	state->buttonLeft =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT) == GLFW_PRESS);
	state->buttonMiddle =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE) ==
	     GLFW_PRESS);
	state->buttonRight =
	    (glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT) == GLFW_PRESS);

	// update mouse position 
	glfwGetCursorPos(window, &(state->mouseLastX), &(state->mouseLastY));
	pthread_mutex_unlock(&(state->mutex));
}

// mouse move callback
void mouse_move(GLFWwindow * window, double xpos, double ypos)
{
	GraphicsState *state =
	    (GraphicsState *) glfwGetWindowUserPointer(window);

	// compute mouse displacement, save 
	pthread_mutex_lock(&(state->mutex));
	double dx = xpos - state->mouseLastX;
	double dy = ypos - state->mouseLastY;
	state->mouseDx = dx;
	state->mouseDy = dy;
	state->mouseLastX = xpos;
	state->mouseLastY = ypos;

	// no buttons down: nothing to do 
	if (!state->buttonLeft && !state->buttonMiddle && !state->buttonRight) {
		pthread_mutex_unlock(&(state->mutex));
		return;
	}

	// get current window size 
	int width, height;
	glfwGetWindowSize(window, &width, &height);

	// get shift key state 
	int mod_shift = (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS
			 || glfwGetKey(window,
				       GLFW_KEY_RIGHT_SHIFT) == GLFW_PRESS);

	// determine action based on mouse button 
	mjtMouse action;
	if (state->buttonRight) {
		action = mod_shift ? mjMOUSE_MOVE_H : mjMOUSE_MOVE_V;
	} else if (state->buttonLeft) {
		action = mod_shift ? mjMOUSE_ROTATE_H : mjMOUSE_ROTATE_V;
	} else {
		action = mjMOUSE_ZOOM;
	}

	// move camera 
	mjv_moveCamera(state->state->m, action, dx / height, dy / height,
		       &(state->state->scn), &(state->state->cam));
	pthread_mutex_unlock(&(state->mutex));
}

// scroll callback
void scroll(GLFWwindow * window, double xoffset, double yoffset)
{
	GraphicsState *state =
	    (GraphicsState *) glfwGetWindowUserPointer(window);

	// emulate vertical mouse motion = 5% of window height
	mjv_moveCamera(state->state->m, mjMOUSE_ZOOM, 0, -0.05 * yoffset,
		       &(state->state->scn), &(state->state->cam));
}

int clearLastKey(GraphicsState * state)
{
	pthread_mutex_lock(&(state->mutex));
	state->lastKeyPress = '\0';
	pthread_mutex_unlock(&(state->mutex));
	return 0;
}

int clearMouseDx(GraphicsState * state)
{
	pthread_mutex_lock(&(state->mutex));
	state->mouseDx = 0;
	pthread_mutex_unlock(&(state->mutex));
	return 0;
}

int clearMouseDy(GraphicsState * state)
{
	pthread_mutex_lock(&(state->mutex));
	state->mouseDy = 0;
	pthread_mutex_unlock(&(state->mutex));
	return 0;
}

int initOpenGL(GraphicsState * graphicsState, State * state)
{
	if (!glfwInit()) {
		mju_error("Could not initialize GLFW");
	}

	graphicsState->state = state;

	// create visible window, double-buffered glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);
	glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);
	GLFWwindow *window =
	    glfwCreateWindow(800, 800, "Visible window", NULL, NULL);
	if (!window)
		mju_error("Could not create GLFW window");
	glfwMakeContextCurrent(window);

	// install GLFW mouse and keyboard callbacks
	glfwSetWindowUserPointer(window, graphicsState);
	glfwSetKeyCallback(window, keyboard);
	glfwSetCursorPosCallback(window, mouse_move);
	glfwSetMouseButtonCallback(window, mouse_button);
	glfwSetScrollCallback(window, scroll);

	graphicsState->window = window;
	pthread_mutex_init(&(graphicsState->mutex), NULL);
	graphicsState->buttonLeft = 0;
	graphicsState->buttonMiddle = 0;
	graphicsState->buttonRight = 0;
	graphicsState->mouseLastX = 0;
	graphicsState->mouseLastY = 0;
	graphicsState->mouseDx = 0;
	graphicsState->mouseDy = 0;
	graphicsState->lastKeyPress = '\0';
	return 0;
}

int closeOpenGL()
{
	glfwTerminate();
	return 0;
}

int addLabel(const char* label, const float* pos, State* s)
{
	mjvScene* scn = &(s->scn);
  
  mjv_updateScene(s->m, s->d, &s->opt, NULL, &s->cam, mjCAT_ALL, scn);
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


int renderOnscreen(GraphicsState * state)
{
	mjvScene scn = state->state->scn;
	mjrContext con = state->state->con;


	mjrRect rect = { 0, 0, 0, 0 };
	glfwGetFramebufferSize(state->window, &rect.width, &rect.height);

	mjr_setBuffer(mjFB_WINDOW, &con);
	if (con.currentBuffer != mjFB_WINDOW) {
		printf("Warning: window rendering not supported\n");
	}


	mjr_render(rect, &scn, &con);
	glfwSwapBuffers(state->window);
	glfwPollEvents();
	return 0;
}
