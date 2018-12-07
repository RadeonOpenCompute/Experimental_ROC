#!/bin/bash
###############################################################################
# Copyright (c) 2018 Advanced Micro Devices, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
###############################################################################
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
set -e
trap 'lastcmd=$curcmd; curcmd=$BASH_COMMAND' DEBUG
trap 'errno=$?; print_cmd=$lastcmd; if [ $errno -ne 0 ]; then echo "\"${print_cmd}\" command failed with exit code $errno."; fi' EXIT
source "$BASE_DIR/common/common_options.sh"
parse_args "$@"

# Install pre-reqs. We might need build-essential, cmake, and git if nobody
# ran the higher-level build scripts.
if [ ${ROCM_LOCAL_INSTALL} = false ] || [ ${ROCM_INSTALL_PREREQS} = true ]; then
    echo "Installing software required to build HCC."
    echo "You will need to have root privileges to do this."
    sudo apt -y install build-essential cmake pkg-config git
    if [ ${ROCM_INSTALL_PREREQS} = true ] && [ ${ROCM_FORCE_GET_CODE} = false ]; then
        exit 0
    fi
fi

# Set up source-code directory
if [ $ROCM_SAVE_SOURCE = true ]; then
    SOURCE_DIR=${ROCM_SOURCE_DIR}
    if [ ${ROCM_FORCE_GET_CODE} = true ] && [ -d ${SOURCE_DIR}/hcc ]; then
        rm -rf ${SOURCE_DIR}/hcc
    fi
    mkdir -p ${SOURCE_DIR}
else
    SOURCE_DIR=`mktemp -d`
fi
cd ${SOURCE_DIR}

# Download hcc
if [ ${ROCM_FORCE_GET_CODE} = true ] || [ ! -d ${SOURCE_DIR}/hcc ]; then
    git clone --recursive -b ${ROCM_VERSION_BRANCH} https://github.com/RadeonOpenCompute/hcc.git
    cd ${SOURCE_DIR}/hcc
    git checkout tags/${ROCM_VERSION_TAG}
    git submodule update
else
    echo "Skipping download of hcc, since ${SOURCE_DIR}/hcc already exists."
fi

if [ ${ROCM_FORCE_GET_CODE} = true ]; then
    echo "Finished downloading hcc. Exiting."
    exit 0
fi

cd ${SOURCE_DIR}/hcc
mkdir -p build
cd build

# HCC in ROCm 1.9.2 does not work properly when doing a debug build. It hits
# a number of assertions. So to allow you to build this even with trying to
# pass in Debug builds, we downgrade to RelWithDebInfo.

if [ ${ROCM_CMAKE_BUILD_TYPE} = "Debug" ]; then
    ROCM_CMAKE_BUILD_TYPE=RelWithDebInfo
fi

cd ${SOURCE_DIR}/hcc/build/

cmake .. -DCMAKE_BUILD_TYPE=${ROCM_CMAKE_BUILD_TYPE} -DCMAKE_INSTALL_PREFIX=${ROCM_OUTPUT_DIR}/hcc/ -DLLVM_USE_LINKER=gold -DCMAKE_LIBRARY_PATH=${ROCM_INPUT_DIR}/lib -DCMAKE_INCLUDE_PATH=${ROCM_INPUT_DIR}/include  -DLLVM_ENABLE_ASSERTIONS=OFF
# Building HCC can take a large amount of memory, and it will fail if you do
# not have enough memory available per thread. As such, this # logic limits
# the number of build threads in response to the amount of available memory
# on the system.
MEM_AVAIL=`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`
AVAIL_THREADS=`nproc`

# Give about 4 GB to each building thread
MAX_THREADS=`echo $(( ${MEM_AVAIL} / $(( 1024 * 1024 * 4 )) ))`
if [ ${ROCM_CMAKE_BUILD_TYPE} = "RelWithDebInfo" ]; then
    MAX_THREADS=`echo $(( ${MEM_AVAIL} / $(( 1024 * 1024 * 6 )) ))`
fi
if [ ${MAX_THREADS} -lt ${AVAIL_THREADS} ]; then
    NUM_BUILD_THREADS=${MAX_THREADS}
else
    NUM_BUILD_THREADS=${AVAIL_THREADS}
fi
if [ ${NUM_BUILD_THREADS} -lt 1 ]; then
    NUM_BUILD_THREADS=1
fi

make -j ${NUM_BUILD_THREADS}

if [ ${ROCM_FORCE_BUILD_ONLY} = true ]; then
    echo "Finished building hcc. Exiting."
    exit 0
fi

${ROCM_SUDO_COMMAND} make install
${ROCM_SUDO_COMMAND} mkdir -p ${ROCM_OUTPUT_DIR}/bin/
${ROCM_SUDO_COMMAND} bash -c 'for i in lld clamp-config extractkernel hcc hcc-config; do ln -sf '"${ROCM_OUTPUT_DIR}"'/hcc/bin/${i} '"${ROCM_OUTPUT_DIR}"'/bin/${i}; done'
${ROCM_SUDO_COMMAND} mkdir -p ${ROCM_OUTPUT_DIR}/include/
${ROCM_SUDO_COMMAND} ln -sf ${ROCM_OUTPUT_DIR}/hcc/include ${ROCM_OUTPUT_DIR}/include/hcc
${ROCM_SUDO_COMMAND} mkdir -p ${ROCM_OUTPUT_DIR}/lib/
${ROCM_SUDO_COMMAND} bash -c 'for i in libclang_rt.builtins-x86_64.a libhc_am.so libmcwamp.a libmcwamp_atomic.a libmcwamp_cpu.so libmcwamp_hsa.so; do ln -sf '"${ROCM_OUTPUT_DIR}"'/hcc/lib/${i} '"${ROCM_OUTPUT_DIR}"'/lib/${i}; done'

if [ $ROCM_SAVE_SOURCE = false ]; then
    rm -rf ${SOURCE_DIR}
fi
