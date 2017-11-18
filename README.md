# MuJoCo

This is a simple python wrapper around the [MuJoCo](http://www.mujoco.org/) physics simulation.

## Installation

pip install mujoco

## API
This package exports the following names:

- `Sim`: a class that corresponds to a single MuJoCo simulation. Discussed below
- `GeomType`: enum of the different types of `geom`s supported by MuJoCo (corresponds to `mjtGeom`).
- `ObjType`: enum of different MuJoCo object types (corresponds to `mjtObj`). Some of 
