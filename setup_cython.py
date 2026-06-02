"""
Build Cython extensions for the Xiangqi AI engine.

Usage:
    pip install cython
    python setup_cython.py build_ext --inplace

On Windows (MinGW):
    python setup_cython.py build_ext --inplace --compiler=mingw32
"""
from setuptools import setup, Extension

try:
    from Cython.Build import cythonize
except ImportError:
    raise SystemExit("Cython is not installed. Run: pip install cython")

extensions = [
    Extension(
        name="engine.ai.fast_eval",
        sources=["engine/ai/fast_eval.pyx"],
        extra_compile_args=["-O2"],
    ),
    Extension(
        name="engine.ai.cy_movegen",
        sources=["engine/ai/cy_movegen.pyx"],
        extra_compile_args=["-O3"],
    ),
]

setup(
    name="xiangqi_engine",
    ext_modules=cythonize(
        extensions,
        compiler_directives={
            "language_level": "3",
            "boundscheck": False,
            "wraparound": False,
            "cdivision": True,
        },
        annotate=False,
    ),
)
