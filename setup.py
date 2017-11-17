#! /usr/bin/env python

RENDER = False #os.environ.get('RENDER') is not None

# from distutils.core import setup, Extension
from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
from os.path import join, expanduser

mjpro_path = join(expanduser('~'), '.mujoco', 'mjpro150')
build_dir = "build"
name = 'mujoco.sim'


extensions = Extension(
    name,
    sources=[
        "mujoco/sim.pyx",
        "src/lib.c",
    ],
    include_dirs=[
        join(mjpro_path, 'include'),
        'headers',
        'pxd',
    ],
    library_dirs=[join(mjpro_path, 'bin')],
    extra_compile_args=[
        '-fopenmp',  # needed for OpenMP
        '-w',  # suppress numpy compilation warnings
    ],
    extra_link_args=['-fopenmp',
                     join(mjpro_path, 'bin', 'libglfw.so.3')],
    language='c')

if RENDER:
    extensions.sources += ["src/renderGlfw.c"]
    extensions.libraries=['mujoco150', 'GL', 'glew']
else:
    extensions.library_dirs += ["/usr/lib/nvidia-384"]
    extensions.sources += ["src/renderEgl.c"]
    extensions.libraries=["mujoco150", "OpenGL", "EGL", "glewegl"]

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
