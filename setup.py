#! /usr/bin/env python

from distutils.core import setup, Extension
from Cython.Build import cythonize
from os.path import join, expanduser

mjpro_path = join(expanduser('~'), '.mujoco', 'mjpro150')
build_dir = "build"

extensions = Extension(
    'mujoco',
    sources=[
        "pyx/mujoco.pyx",
        "src/render.c",
    ],
    include_dirs=[
        join(mjpro_path, 'include'),
        'headers',
        'pxd',
    ],
    libraries=['mujoco150', 'GL', 'glew'],
    library_dirs=[join(mjpro_path, 'bin')],
    extra_compile_args=[
        '-fopenmp',  # needed for OpenMP
        '-w',  # suppress numpy compilation warnings
    ],
    extra_link_args=['-fopenmp',
                     join(mjpro_path, 'bin', 'libglfw.so.3')],
    language='c')

if __name__ == '__main__':
    setup(
        ext_modules=cythonize(
            extensions,
            build_dir=build_dir,
        ),
        build_requires=[
            'Cython',
            'Numpy',
        ])
