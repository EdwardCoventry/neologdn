# -*- coding: utf-8 -*-
from codecs import open
import re
import sys
from setuptools import setup, Extension
import platform

# Extract the version from neologdn.cpp
with open('neologdn.cpp', 'r', encoding='utf8') as f:
    version = re.compile(r".*__version__ = '(.*?)'", re.S).match(f.read()).group(1)

# Set extra compile arguments based on the platform.
if platform.system() == "Windows":
    # Use /std:c++14 instead of /std:c++11, as MSVC does not recognize /std:c++11.
    extra_compile_args = ["/std:c++14"]
else:
    extra_compile_args = ["-std=c++11"]

# On macOS, add additional flags.
if platform.system() == "Darwin":
    extra_compile_args.extend(["-mmacosx-version-min=10.7", "-stdlib=libc++"])

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
            extra_compile_args=extra_compile_args
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
    ],
    description='Japanese text normalizer for mecab-neologd',
    long_description='%s\n\n%s' % (
        open('README.rst', 'r', encoding='utf8').read(),
        open('CHANGES.rst', 'r', encoding='utf8').read()
    ),
)
