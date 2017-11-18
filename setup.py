#! /usr/bin/env python

# from distutils.core import setup, Extension
from setuptools import setup, Extension
from Cython.Build import cythonize
from os.path import join, expanduser
import numpy as np
import sys
import os

mjpro_path = join(expanduser('~'), '.mujoco', 'mjpro150')
build_dir = "build"
name = 'mujoco.sim'


def make_extension(name, render_file, libraries, extra_link_args,
                   define_macros):
    return Extension(
        name,
        sources=[
            name.replace('.', os.sep) + '.pyx',
            render_file,
            "src/lib.c",
        ],
        include_dirs=[
            join(mjpro_path, 'include'),
            np.get_include(),
            'headers',
            'pxd',
        ],
        libraries=libraries,
        library_dirs=[join(mjpro_path, 'bin'), "/usr/lib/nvidia-384"],
        extra_compile_args=[
            '-fopenmp',  # needed for OpenMP
            '-w',  # suppress numpy compilation warnings
        ],
        extra_link_args=extra_link_args,
        define_macros=define_macros,
        language='c')


if sys.platform == "darwin":
    os.environ["CC"] = "/usr/local/bin/gcc-7"
    os.environ["CXX"] = "/usr/local/bin/g++-7"

    libraries = ['mujoco150', 'glfw.3']
    names = ["mujoco.sim", "mujoco.simGlfw"]
    render_file = "src/renderGlfw.c"
    extra_link_args = []
    define_macros = []
elif os.environ.get('RENDER') is not None:
    libraries = ['mujoco150', 'GL', 'glew']
    names = ["mujoco.sim", "mujoco.simGlfw"]
    render_file = "src/renderGlfw.c"
    extra_link_args = ['-fopenmp', join(mjpro_path, 'bin', 'libglfw.so.3')]
    define_macros = []
else:
    libraries = ["mujoco150", "OpenGL", "EGL", "glewegl"]
    names = ["mujoco.sim", "mujoco.simEgl"]
    render_file = "src/renderEgl.c"
    extra_link_args = ['-fopenmp', join(mjpro_path, 'bin', 'libglfw.so.3')]
    define_macros = [('MJ_EGL', 1)]

extensions = [
    make_extension(name, render_file, libraries, extra_link_args,
                   define_macros) for name in names
]

if __name__ == '__main__':
    setup(
        name=name,
        packages=['mujoco'],
        ext_modules=cythonize(
            extensions,
            build_dir=build_dir,
        ),
        install_requires=[
            'Cython',
            'Numpy',
        ])
