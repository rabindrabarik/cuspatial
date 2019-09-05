#!/bin/bash
# Copyright (c) 2018, NVIDIA CORPORATION.
#########################################
# cuSpatial GPU build and test script for CI #
#########################################
set -e
NUMARGS=$#
ARGS=$*

# Logger function for build status output
function logger() {
  echo -e "\n>>>> $@\n"
}

# Arg parsing function
function hasArg {
    (( ${NUMARGS} != 0 )) && (echo " ${ARGS} " | grep -q " $1 ")
}

# Set path and build parallel level
export PATH=/conda/bin:/usr/local/cuda/bin:$PATH
export PARALLEL_LEVEL=4
export CUDA_REL=${CUDA_VERSION%.*}
export CUDF_HOME="${WORKSPACE}/cudf"
export PYTHONPATH=${WORKSPACE}/python/cuspatial

# Set home to the job's workspace
export HOME=$WORKSPACE

# Parse git describe
cd $WORKSPACE
export GIT_DESCRIBE_TAG=`git describe --tags`
export MINOR_VERSION=`echo $GIT_DESCRIBE_TAG | grep -o -E '([0-9]+\.[0-9]+)'`

################################################################################
# SETUP - Check environment
################################################################################

logger "Check environment..."
env

logger "Check GPU usage..."
nvidia-smi

logger "Activate conda env..."
source activate gdf

# These installs are dependencies of cudf and most should be removed once we use a conda package
# for cudf
conda install "rmm=$MINOR_VERSION.*" "cudatoolkit=$CUDA_REL" \
              "dask>=2.1.0" "distributed>=2.1.0" "numpy>=1.16" "double-conversion" \
              "rapidjson" "flatbuffers" "boost-cpp" "fsspec>=0.3.3" "dlpack" \
              "feather-format" "cupy>=6.0.0" "arrow-cpp=0.14.1" "pyarrow=0.14.1" \
              "fastavro>=0.22.0" "pandas>=0.24.2,<0.25" "hypothesis"

# Install the master version of dask and distributed
logger "pip install git+https://github.com/dask/distributed.git --upgrade --no-deps" 
pip install "git+https://github.com/dask/distributed.git" --upgrade --no-deps
logger "pip install git+https://github.com/dask/dask.git --upgrade --no-deps"
pip install "git+https://github.com/dask/dask.git" --upgrade --no-deps

logger "Check versions..."
python --version
$CC --version
$CXX --version
conda list

################################################################################
# BUILD - Build libnvstrings, nvstrings, libcudf, and cuDF from source
#
# cuSpatial currently requires a source build of cudf and not a conda package
################################################################################

logger "Clone cudf"
git clone git@github.com:rapidsai/cudf.git -b branch-$MINOR_VERSION ${CUDF_HOME}

logger "Build cudf..."
cd $CUDF_HOME
./build.sh clean libnvstrings nvstrings libcudf cudf

################################################################################
# BUILD - Build libcuspatial and cuSpatial from source
################################################################################

logger "Build cuSpatial"
cd $WORKSPACE
./build.sh clean libcuspatial cuspatial

###############################################################################
# TEST - Run libcuspatial and cuSpatial Unit Tests
###############################################################################

if hasArg --skip-tests; then
    logger "Skipping tests..."
else
    logger "Download/Generate Test Data"
    #TODO

    logger "Test cuSpatial"
    #TODO
fi

