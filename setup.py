#! /usr/bin/env python

# from distutils.core import setup, Extension
from setuptools import setup, Extension
from Cython.Build import cythonize
from os.path import join, expanduser
import os

RENDER = True  # os.environ.get('RENDER') is not None

mjpro_path = join(expanduser('~'), '.mujoco', 'mjpro150')
build_dir = "build"
name = 'mujoco.sim'


def make_extension(name, libraries, render_file):
    return Extension(
        name,
        sources=[
            name.replace('.', os.sep) + '.pyx',
            render_file,
            "src/lib.c",
        ],
        include_dirs=[
            join(mjpro_path, 'include'),
            'headers',
            'pxd',
        ],
        libraries=libraries,
        library_dirs=[join(mjpro_path, 'bin'), "/usr/lib/nvidia-384"],
        extra_compile_args=[
            '-fopenmp',  # needed for OpenMP
            '-w',  # suppress numpy compilation warnings
        ],
        extra_link_args=['-fopenmp',
                         join(mjpro_path, 'bin', 'libglfw.so.3')],
        language='c')


names = ["mujoco.sim"]
if RENDER:
    libraries = ['mujoco150', 'GL', 'glew']
    names += ["mujoco.simGlfw"]
    render_file = "src/renderGlfw.c"
else:
    libraries = ["mujoco150", "OpenGL", "EGL", "glewegl"]
    names += ["mujoco.simEgl"]
    render_file = "src/renderEgl.c"

extensions = [make_extension(name, libraries, render_file) for name in names]

if __name__ == '__main__':
    setup(
        name=name,
        packages=['mujoco'],
        ext_modules=cythonize(
            extensions,
            build_dir=build_dir, ),
        install_requires=[
            'Cython',
            'Numpy',
        ])
