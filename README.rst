`Documentation <http://mujoco.readthedocs.io/>`_

.. inclusion-marker-do-not-remove

MuJoCo for Python!
==================

This is a simple python wrapper around the MuJoCo physics simulation. I wrote it when I couldn't get `mujoco-py  <https://github.com/openai/mujoco-py>`_ to work. Please note: this library is a partial replacement to (not a supplement of) 
``mujoco-py``. It is currently not very fully featured. If there are additional capabilities you want added, please feel free to 
`post an issue <https://github.com/lobachevzky/mujoco/issues/new>`_.

Installation
------------

Working on getting a `pypi` script working. In the mean time, install from source:

.. code-block:: bash

  pip install -e /path/to/cloned/directory

Usage
-----
Examples are locates in the ``examples/`` directory.


If you want your code to use EGL, you must define the environment variable ``EGL=1``. Otherwise, the code defaults to GLFW. Note that when using EGL, you cannot render to the screen (you can still render offscreen).

GLFW vs. EGL
------------
One of the main design decisions behind this implementation was to build with separate libraries for the version that uses EGL (which is faster on linux GPUs). In general, the idea is to use the exact same libraries that Emo's original MuJoCo code uses in the provided Makefile. That way if my version doesn't work, you can bet that Emo's code doesn't work either. I think the reason why ``mujoco-py`` stopped working is that it tried to get fancy with the libraries and dynamically switch between EGL- and GLFW-friendly graphics libraries.
