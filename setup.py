#! /usr/bin/env python

import configparser
import sys
from pathlib import Path

import numpy as np
from Cython.Build import cythonize
# from distutils.core import setup, Extension
from setuptools import Extension, setup

if sys.version_info.major == 2:
    FileNotFoundError = IOError

build_dir = "build"
config_path = 'config.yml'
if __name__ == '__main__':
    keys = ['mjkey_path',
            'mjpro_dir',
            'opengl_dir',
            'headless']
    config = configparser.ConfigParser(allow_no_value=True)
    config_filename = 'config.ini'
    descriptions = ['path to mjkey.txt',
        'mjpro150 directory',
        'directory containing libOpenGL.so ' \
            '(should be None if you don\'t have a GPU)',
        'whether performing headless rendering']
    if Path(config_filename).exists():
        config.read(config_filename)
    else:
        config['MAIN'] = dict(
            mjkey_path=Path('~/.mujoco/mjkey.txt').expanduser(),
            mjpro_dir=Path('~/.mujoco/mjpro150').expanduser(),
            opengl_dir=None,
            headless=False,
        )
        with open(config_filename, 'w') as f:
            config.write(f)

    config = config['MAIN']
    print('---------------------------')
    print('Using the following config:')
    for key, description in zip(config.keys(), descriptions):

        value = config
        print('{}: {} ({})'.format(
            key, config.get(key), description))
    print('To change, edit', config_path)
    print('---------------------------')
    mjpro_dir = config['mjpro_dir']
    mjkey_path = '"' + config['mjkey_path'] + '"'
    opengl_dir = config['opengl_dir']
    opengl_dir = [opengl_dir] if opengl_dir else []

    def make_extension(name, main_source, util_file, libraries,
                       extra_link_args, define_macros):
        return Extension(
            name,
            sources=([util_file] if util_file else []) + [
                main_source,
                "src/util.c",
            ],
            include_dirs=[
                str(Path(mjpro_dir, 'include')),
                np.get_include(),
                'headers',
                'pxd',
            ],
            libraries=libraries,
            library_dirs=[str(Path(mjpro_dir, 'bin'))] + opengl_dir,
            define_macros=define_macros + [('MJKEY_PATH', mjkey_path)],
            extra_link_args=extra_link_args,
            extra_compile_args=['-Wno-unused-function', '-std=c99'],
            language='c')

    if sys.platform == "darwin":
        extensions = [make_extension(
                    name="mujoco.glfw",
                    main_source='mujoco/glfw.pyx',
                    util_file='src/utilGlfw.c',
                    libraries=['mujoco150', 'glfw.3'],
                    extra_link_args=[],
                    define_macros=[]
                    )]
    elif sys.platform in ["linux", "linux2"]:
        extensions = []
        if not opengl_dir and config['headless']:
            print('Building OSMesa version...')
            extensions += [make_extension(
                    name="mujoco.osmesa",
                    main_source='mujoco/osmesa.pyx',
                    util_file='src/utilOsmesa.c',
                    libraries=["mujoco150", "OSMesa", "glewosmesa"],
                    extra_link_args=[],
                    define_macros=[('MJ_OSMESA', 1)]
                    )]
        if opengl_dir:
            print('Building EGL version...')
            extensions += [make_extension(
                    name="mujoco.egl",
                    main_source='mujoco/egl.pyx',
                    util_file='src/utilEgl.c',
                    libraries=["mujoco150", "OpenGL", "EGL", "glewegl"],
                    extra_link_args=[],
                    define_macros=[('MJ_EGL', 1)]
                    )]
        if not config['headless']:
            print('Building GLFW version...')
            extra_link_args = ['-fopenmp', str(Path(mjpro_dir, 'bin', 'libglfw.so.3'))]
            extensions += [make_extension(
                        name="mujoco.glfw",
                        main_source='mujoco/glfw.pyx',
                        util_file='src/utilGlfw.c',
                        libraries=['mujoco150', 'GL', 'glew'],
                        extra_link_args=extra_link_args,
                        define_macros=[('MJ_GLFW', 1)]
                        )]
    else:
        raise SystemError("We don't support Windows!")

    with open('README.rst') as f:
        long_description = f.read()

    setup(
        name='mujoco',
        version='2.1.2',
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
            'Cython>=0.27.3',
            'numpy>=1.14',
        ])
