#include "mujoco.h"
#include "stdio.h"
#include "stdlib.h"
#include "string.h"
#include "glfw3.h"


//-------------------------------- global data ------------------------------------------

// MuJoCo model and data
mjModel* m = 0;
mjData* d = 0;

// MuJoCo visualization
mjvScene scn;
mjvCamera cam;
mjvOption opt;
mjrContext con;


//-------------------------------- main function ----------------------------------------

int main(int argc, const char** argv)
{
    if( !glfwInit() )
        mju_error("Could not initialize GLFW");

    // create visible window, double-buffered
    glfwWindowHint(GLFW_VISIBLE, GLFW_TRUE);
    glfwWindowHint(GLFW_DOUBLEBUFFER, GLFW_TRUE);
    GLFWwindow* window = glfwCreateWindow(800, 800, "Visible window", NULL, NULL);
    if( !window )
        mju_error("Could not create GLFW window");

    glfwMakeContextCurrent(window);
    mj_activate("../.mujoco/mjkey.txt");

    char error[1000] = "Could not load xml model";
    m = mj_loadXML("xml/humanoid.xml", 0, error, 1000);
    if( !m )
        mju_error_s("Load model error: %s", error);
    d = mj_makeData(m);
    mj_forward(m, d);

    // initialize MuJoCo visualization
    mjv_makeScene(&scn, 1000);
    mjv_defaultCamera(&cam);
    mjv_defaultOption(&opt);
    mjr_defaultContext(&con);
    mjr_makeContext(m, &con, 200);

    // get size of window
    mjrRect window_rect = {0, 0, 0, 0};
    glfwGetFramebufferSize(window, &window_rect.width, &window_rect.height);
    int W = window_rect.width;
    int H = window_rect.height;

    // allocate rgb and depth buffers
    unsigned char* rgb = (unsigned char*)malloc(3*W*H);
    if( !rgb )
        mju_error("Could not allocate buffers");

    // create output rgb file
    FILE* fp = fopen("rgb.out", "wb");
    if( !fp )
        mju_error("Could not open rgbfile for writing");

    // main loop
    for( int i = 0; i < 50; i++) {
      cam.fixedcamid = 0;
      cam.type = mjCAMERA_FIXED;
      mjv_updateScene(m, d, &opt, NULL, &cam, mjCAT_ALL, &scn);

      // write offscreen-rendered pixels to file
      mjr_render(window_rect, &scn, &con);
      mjr_readPixels(rgb, NULL, window_rect, &con);
      fwrite(rgb, 3, W*H, fp);

      cam.fixedcamid = -1;
      cam.type = mjCAMERA_FREE;
      mjv_updateScene(m, d, &opt, NULL, &cam, mjCAT_ALL, &scn);
      mjr_render(window_rect, &scn, &con);

      glfwSwapBuffers(window);
      mj_step(m, d);
    }

    FILE *fout = fopen("rgb.pbm", "wb");
    if (!fout)
      mju_error("Could not open image file for writing");

    fprintf(fout, "P6\n%d %d\n255\n", W, H);
    fwrite(rgb, 1, W * H * 3, fout);

    fclose(fout);

    fclose(fp);
    free(rgb);
    mj_deleteData(d);
    mj_deleteModel(m);
    mjr_freeContext(&con);
    mjv_freeScene(&scn);
    mj_deactivate();
    return 0;
}
