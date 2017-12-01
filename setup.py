#! /usr/bin/env python

# from distutils.core import setup, Extension
from setuptools import setup, Extension
from Cython.Build import cythonize
from os.path import join, expanduser
import numpy as np
import sys
import os
import subprocess

mjpro_path = join(expanduser('~'), '.mujoco', 'mjpro150')
build_dir = "build"


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
        extra_link_args=extra_link_args,
        define_macros=define_macros,
        language='c')


if sys.platform == "darwin":
    libraries = ['mujoco150', 'glfw.3']
    names = ["mujoco.sim", "mujoco.simGlfw"]
    render_file = "src/renderGlfw.c"
    extra_link_args = []
    define_macros = []
    extensions = [make_extension(name, render_file, libraries, extra_link_args,
                                 define_macros) for name in names]
elif sys.platform in ["linux", "linux2"]:
    libraries = ["mujoco150", "OpenGL", "EGL", "glewegl"]
    names = ["mujoco.sim", "mujoco.simEgl"]
    render_file = "src/renderEgl.c"
    extra_link_args = ['-fopenmp', join(mjpro_path, 'bin', 'libglfw.so.3')]
    define_macros = [('MJ_EGL', 1)]
    extensions = [make_extension(name, render_file, libraries, extra_link_args,
                                 define_macros) for name in names]
    if os.environ.get('RENDER'):
        libraries = ['mujoco150', 'GL', 'glew']
        name = "mujoco.simGlfw"
        render_file = "src/renderGlfw.c"
        extra_link_args = ['-fopenmp', join(mjpro_path, 'bin', 'libglfw.so.3')]
        define_macros = []
        extensions += [make_extension(name, render_file, libraries,
                                      extra_link_args, define_macros)]
else:
    raise SystemError("We don't support Windows!")

extensions = [
    make_extension(name, render_file, libraries, extra_link_args,
                   define_macros) for name in names
]

with open('README.rst') as f:
    long_description = f.read()

if __name__ == '__main__':
    setup(
        name='mujoco',
        version='1.0.10',
        description='Python wrapper for MuJoCo physics simulation.',
        long_description=long_description,
        url='https://github.com/lobachevzky/mujoco',
        author='Ethan Brooks',
        author_email='ethanbrooks@gmail.com',
        license='MIT',
        classifiers=[
            'Development Status :: 3 - Alpha',
            'Intended Audience :: Developers',
            'Topic :: Scientific/Engineering :: Visualization',
            'Topic :: Scientific/Engineering :: Physics',
            'License :: OSI Approved :: MIT License',
            'Programming Language :: Python :: 2',
            'Programming Language :: Python :: 3',
        ],
        keywords='physics mujoco wrapper python-wrapper physics-simulation',
        py_modules=['mujoco.sim'],
        packages=['mujoco'],
        ext_modules=cythonize(
            extensions,
            build_dir=build_dir,
        ),
        install_requires=[
            'Cython==0.27.3',
            'numpy==1.13.3',
        ])
