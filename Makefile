BUILD=build/
MK_BUILD=mkdir -p $(BUILD)
MJ_DIR=$(HOME)/.mujoco/mjpro150/
COMMON=-O2 -I$(MJ_DIR)/include -Iheaders -L$(MJ_DIR)/bin -mavx

default:
	python setup.py build_ext --inplace

# glfw and egl build a simple test example to ensure that the underlying c code works

osx:
	$(MK_BUILD)
	clang $(COMMON) src/renderGlfw.c -DMJ_GLFW src/lib.c -lmujoco150 -lglfw.3 -o $(BUILD)renderosx
	#DYLD_LIBRARY_PATH=$(MJ_DIR)bin $(BUILD)renderosx
	$(BUILD)renderosx

glfw:
	$(MK_BUILD)
	g++ $(COMMON) -std=c++11 src/renderGlfw.c -DMJ_GLFW src/lib.c -lmujoco150 -lGL -lglew $(MJ_DIR)bin/libglfw.so.3 -o  $(BUILD)renderglfw
	$(BUILD)renderglfw
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

egl:
	$(MK_BUILD)
	g++ $(COMMON) -std=c++11 -L/usr/lib/nvidia-384 -DMJ_EGL src/renderEgl.c src/lib.c -lmujoco150 -lOpenGL -lEGL -lglewegl -o  $(BUILD)renderegl
	$(BUILD)renderegl
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

package:
	python setup.py bdist_wheel

clean:
	rm -f mujoco/*.so MUJOCO_LOG.txt
	rm -rf mujoco/__pycache__/ build/ *.egg-info dist/
