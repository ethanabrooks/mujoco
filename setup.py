#! /usr/bin/env python

# from distutils.core import setup, Extension
from setuptools import setup, Extension
from Cython.Build import cythonize
from os.path import join, expanduser
import numpy as np
import sys
import os
import subprocess
import yaml

if sys.version_info.major == 2:
    FileNotFoundError = OSError

build_dir = "build"

if __name__ == '__main__':
    config_path = 'config.yml'
    try:
        with open(config_path) as f:
            config = yaml.load(f)
    except FileNotFoundError:
        config = dict()
        for key, description, default in [
                ('mjkey-path', 'path to mjkey.txt', '~/.mujoco/mjkey.txt'), 
                ('mjpro-dir', 'mjpro150 directory', '~/.mujoco/mjpro150'), 
                ('opengl-dir', 'directory containing libOpenGL.so', None)
            ]:
            value = input('Enter {} [default is {}]:'.format(description, default))
            config[key] = value if value else default
        with open(config_path, 'w') as f:
            yaml.dump(config, f, default_flow_style=False)

    mjpro_dir = expanduser(config['mjpro-dir'])
    mjkey_path = '"' + expanduser(config['mjkey-path']) + '"'
    opengl_dir = expanduser(config['opengl-dir'])

    def make_extension(name, main_source, util_file, libraries,
                       extra_link_args, define_macros):
        return Extension(
            name,
            sources=([util_file] if util_file else []) + [
                main_source,
                "src/util.c",
            ],
            include_dirs=[
                join(mjpro_dir, 'include'),
                np.get_include(),
                'headers',
                'pxd',
            ],
            libraries=libraries,
            library_dirs=[join(mjpro_dir, 'bin'), opengl_dir],
            define_macros=define_macros + [('MJKEY_PATH', mjkey_path)],
            extra_link_args=extra_link_args,
            extra_compile_args=['-Wno-unused-function'],
            language='c')
        # e.cython_directives = {"embedsignature": True}

    if sys.platform == "darwin":
        extensions = [make_extension(name="mujoco.glfw",
                                     main_source='mujoco/glfw.pyx',
                                     util_file='src/utilGlfw.c',
                                     libraries=['mujoco150', 'glfw.3'],
                                     extra_link_args=[],
                                     define_macros=[]
                                     )]
    elif sys.platform in ["linux", "linux2"]:
        extra_link_args = ['-fopenmp', join(mjpro_dir, 'bin', 'libglfw.so.3')]
        extensions = [
            make_extension(name="mujoco.egl",
                           main_source='mujoco/egl.pyx',
                           util_file='src/utilEgl.c',
                           libraries=["mujoco150", "OpenGL", "EGL", "glewegl"],
                           extra_link_args=extra_link_args,
                           define_macros=[('MJ_EGL', 1)]
                           ),
            make_extension(name="mujoco.glfw",
                           main_source='mujoco/glfw.pyx',
                           util_file='src/utilGlfw.c',
                           libraries=['mujoco150', 'GL', 'glew'],
                           extra_link_args=extra_link_args,
                           define_macros=[]
                           ),
        ]
    else:
        raise SystemError("We don't support Windows!")

    with open('README.rst') as f:
        long_description = f.read()

    setup(
        name='mujoco',
        version='1.0.11',
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
            'pyyaml==3.12',
        ])
