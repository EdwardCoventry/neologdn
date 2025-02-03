# -*- coding: utf-8 -*-
from codecs import open
import re
import sys
from setuptools import setup, Extension
import platform

# Read version from the source file (using neologdn.cpp as source)
with open('neologdn.cpp', 'r', encoding='utf8') as f:
    version = re.compile(r".*__version__ = '(.*?)'", re.S).match(f.read()).group(1)

# Set the extra compile arguments based on the platform.
if platform.system() == "Windows":
    # Use MSVC flag for C++11 on Windows.
    extra_compile_args = ["/std:c++11"]
else:
    extra_compile_args = ["-std=c++11"]

# Add macOS-specific flags.
if platform.system() == "Darwin":
    extra_compile_args.extend(["-mmacosx-version-min=10.7", "-stdlib=libc++"])

# Define macros based on the Python version.
# For Python 3.12 and 3.13, you can use the macro below inside your C++/Cython code
# to select alternate implementations for removed or deprecated APIs.
define_macros = []
if sys.version_info >= (3, 12):
    define_macros.append(('PYTHON3_12_OR_HIGHER', '1'))

setup(
    name='neologdn',
    version=version,
    author='Yukino Ikegami',
    author_email='yknikgm@gmail.com',
    url='http://github.com/ikegami-yukino/neologdn',
    ext_modules=[
        Extension(
            'neologdn',
            ['neologdn.cpp'],
            language='c++',
            extra_compile_args=extra_compile_args,
            define_macros=define_macros,
        )
    ],
    license='Apache Software License',
    keywords=['japanese', 'MeCab'],
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Natural Language :: Japanese',
        'License :: OSI Approved :: Apache Software License',
        'Programming Language :: Cython',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Programming Language :: Python :: 3.13',
        'Topic :: Text Processing :: Linguistic'
    ],
    description='Japanese text normalizer for mecab-neologd',
    long_description='%s\n\n%s' % (
        open('README.rst', 'r', encoding='utf8').read(),
        open('CHANGES.rst', 'r', encoding='utf8').read()
    ),
)
