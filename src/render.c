#include "render.h"
#include "mujoco.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "glfw3.h"


//-------------------------------- global data ------------------------------------------

GLFWwindow* initGlfw() {
    if( !glfwInit() )
        mju_error("Could not initialize GLFW");

    // create visible window, double-buffered
    glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);
    glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);
    GLFWwindow* window = glfwCreateWindow(800, 800, "Visible window", NULL, NULL);
    if( !window )
        mju_error("Could not create GLFW window");

    glfwMakeContextCurrent(window);
    return window;
}

mjModel* loadModel(const char* filepath) {
    char error[1000] = "Could not load xml model";
    mjModel* m = mj_loadXML(filepath, 0, error, 1000);
    if( !m )
        mju_error_s("Load model error: %s", error);
    return m;
}

int initMujoco(mjModel* m, mjData* d, RenderContext* context) {
    /*mjvScene* scn, mjvCamera* cam, mjvOption* opt, mjrContext* con) {*/
      mj_forward(m, d);
      mjv_makeScene(&context->scn, 1000);
      mjv_defaultCamera(&context->cam);
      mjv_defaultOption(&context->opt);
      mjr_defaultContext(&context->con);
      mjr_makeContext(m, &context->con, 200);
}

int setCamera(int camid, mjModel* m, mjData* d, RenderContext* context) {
      mjvScene* scn = &(context->scn);
      mjvCamera* cam = &(context->cam);
      mjvOption* opt = &(context->opt);

      cam->fixedcamid = camid;
      if (camid == -1) {
        cam->type = mjCAMERA_FREE;
      } else {
        cam->type = mjCAMERA_FIXED;
      }

      mjv_updateScene(m, d, opt, NULL, cam, mjCAT_ALL, scn);
}

int renderOnscreen(int camid, GLFWwindow* window, mjModel* m, mjData* d, RenderContext* context) {

      setCamera(camid, m, d, context);

      mjvScene scn = context->scn;
      mjrContext con = context->con;
      mjvCamera cam = context->cam;
      mjvOption opt = context->opt;
      mjrRect rect = {0, 0, 0, 0};
      glfwGetFramebufferSize(window, &rect.width, &rect.height);

      mjr_setBuffer(mjFB_WINDOW, &con);
      if( con.currentBuffer!=mjFB_WINDOW )
          printf("Warning: window rendering not supported\n");
      mjr_render(rect, &scn, &con);
      glfwSwapBuffers(window);
}

int renderOffscreen(int camid, unsigned char* rgb, int height, int width,
    mjModel* m, mjData* d, RenderContext* context) {
      setCamera(camid, m, d, context);

      mjvScene scn = context->scn;
      mjrContext con = context->con;
      mjvCamera cam = context->cam;
      mjvOption opt = context->opt;
      mjrRect viewport = {0, 0, height, width};

      // write offscreen-rendered pixels to file
      mjr_setBuffer(mjFB_OFFSCREEN, &con);
      if( con.currentBuffer!=mjFB_OFFSCREEN )
          printf("Warning: offscreen rendering not supported, using default/window framebuffer\n");
      mjr_render(viewport, &scn, &con);
      mjr_readPixels(rgb, NULL, viewport, &con);
}


int closeMujoco(mjModel* m, mjData* d, RenderContext* context) {
    mjvScene scn = context->scn;
    mjrContext con = context->con;

    mj_deleteData(d);
    mj_deleteModel(m);
    mjr_freeContext(&con);
    mjv_freeScene(&scn);
    mj_deactivate();
}


//-------------------------------- main function ----------------------------------------

int main(int argc, const char** argv)
{
    int H = 800;
    int W = 800;
    char const* filepath = "xml/humanoid.xml";
    char const* keypath = "../.mujoco/mjkey.txt";
    mjModel* m;
    mjData* d;
    RenderContext context;

    GLFWwindow* window = initGlfw();
    mj_activate(keypath);
    m = loadModel(filepath);
    d = mj_makeData(m);
    initMujoco(m, d, &context);

    // allocate rgb and depth buffers
    unsigned char* rgb = (unsigned char*)malloc(3*H*W);
    if( !rgb )
        mju_error("Could not allocate buffers");

    // create output rgb file
    FILE* fp = fopen("build/rgb.out", "wb");
    if( !fp )
        mju_error("Could not open rgbfile for writing");

    // main loop
    for( int i = 0; i < 10; i++) {
      renderOffscreen(0, rgb, H, W, m, d, &context);
      fwrite(rgb, 3, H * W, fp);
      renderOnscreen(-1, window, m, d, &context);
      mj_step(m, d);
    }
    printf("ffmpeg -f rawvideo -pixel_format rgb24 -video_size %dx%d -framerate 60 -i build/rgb.out -vf 'vflip' build/video.mp4\n", H, W);

    fclose(fp);
    free(rgb);
    closeMujoco(m, d, &context);

    return 0;
}

