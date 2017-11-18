BUILD=build/
MK_BUILD=mkdir -p $(BUILD)
MJ_DIR=$(HOME)/.mujoco/mjpro150/
COMMON=-O2 -I$(MJ_DIR)/include -Iheaders -L$(MJ_DIR)/bin -std=c++11 -mavx

default:
	python setup.py build_ext --inplace
	#python main.py
	make random-agent
	#cd ~/zero_shot; ls; python remote_control_pick_and_place.py 8000

random-agent:
	cd ~/zero_shot; ls; python random_agent.py


glfw:
	$(MK_BUILD)
	g++ $(COMMON) src/renderGlfw.c -DMJ_GLFW src/lib.c -lmujoco150 -lGL -lglew $(MJ_DIR)/bin/libglfw.so.3 -o  $(BUILD)render
	$(BUILD)render
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

egl:
	$(MK_BUILD)
	g++ $(COMMON) -L/usr/lib/nvidia-384 -DMJ_EGL src/renderEgl.c src/lib.c -lmujoco150 -lOpenGL -lEGL -lglewegl -o  $(BUILD)renderegl
	$(BUILD)renderegl
	ffmpeg -f rawvideo -pixel_format rgb24 -video_size 800x800 -framerate 60 -i $(BUILD)rgb.out -vf 'vflip' $(BUILD)video.mp4
	vlc $(BUILD)video.mp4

#egl:	
	#$(MK_BUILD)
	#g++ $(COMMON) -L/usr/lib/nvidia-384 -DMJ_EGL lib.c -lmujoco150 -lOpenGL -lEGL -lglewegl -o $(BUILD)renderegl

clean:
	rm -f mujoco/*.so
	rm -rf mujoco/__pycache__/ 
	rm -f MUJOCO_LOG.txt
	rm -rf build/ *.egg-info
