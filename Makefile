BUILD=build/
MK_BUILD=mkdir -p $(BUILD)
MJ_DIR=$(HOME)/.mujoco/mjpro150/
COMMON=-O2 -I$(MJ_DIR)/include -L$(MJ_DIR)/bin -std=c++11 -mavx

default:
	python setup.py build_ext --inplace

render:
	$(MK_BUILD)
	g++ $(COMMON) src/render.c -lmujoco150 -lGL -lglew $(MJ_DIR)/bin/libglfw.so.3 -o  $(BUILD)render

egl:	
	$(MK_BUILD)
	g++ $(COMMON) -L/usr/lib/nvidia-384 -DMJ_EGL render.c -lmujoco150 -lOpenGL -lEGL -lglewegl -o $(BUILD)renderegl

clean:
	rm -rf build/
