BUILD=build/
MK_BUILD=mkdir -p $(BUILD)
MJ_DIR=$(HOME)/.mujoco/mjpro150/
COMMON=-O2 -I$(MJ_DIR)/include -Iheaders -L$(MJ_DIR)/bin -mavx

default:
	python setup.py build_ext --inplace
	#DYLD_LIBRARY_PATH=$(MJ_DIR)bin cd ~/zero_shot; python random_agent.py

# glfw and egl build a simple test example to ensure that the underlying c code works

osx:
	#clang $(COMMON) $(MJ_DIR)/sample/basic.cpp -lmujoco150 -lglfw.3 -o $(BUILD)basic
	#DYLD_LIBRARY_PATH=$(MJ_DIR)bin $(BUILD)/basic $(MJ_DIR)/model/humanoid.xml
	clang $(COMMON) src/renderGlfw.c -DMJ_GLFW src/lib.c -lmujoco150 -lglfw.3 -o $(BUILD)renderosx
	DYLD_LIBRARY_PATH=$(MJ_DIR)bin $(BUILD)renderosx

glfw:
	$(MK_BUILD)
	g++ $(COMMON) -std=c++11 src/renderGlfw.c -DMJ_GLFW src/lib.c -lmujoco150 -lGL -lglew $(GLFW) -o  $(BUILD)renderglfw
	$(BUILD)renderglfw
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

egl:
	$(MK_BUILD)
	g++ $(COMMON) -std=c++11 -L/usr/lib/nvidia-384 -DMJ_EGL src/renderEgl.c src/lib.c -lmujoco150 -lOpenGL -lEGL -lglewegl -o  $(BUILD)renderegl
	$(BUILD)renderegl
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

clean:
	rm -f mujoco/*.so MUJOCO_LOG.txt
	rm -rf mujoco/__pycache__/ build/ *.egg-info dist/
