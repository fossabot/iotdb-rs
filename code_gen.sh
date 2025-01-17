#!/bin/bash

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${CURRENT_DIR}/dev"
PKG_VERSION="0.15.0"
PKG_NAME="thrift-${PKG_VERSION}.tar.gz"
OS_RUNNER="thrift"
DEV_RUNNER="${CURRENT_DIR}/dev/thrift"
RUNNER=${OS_RUNNER}

if [ ! -d "${BUILD_DIR}" ]; then
  mkdir "${BUILD_DIR}"
fi

CHECK_COMMAND=""
IS_EXIST_COMMAND=1
function check_command() {
  if command -v ${RUN_COMMAND} &>/dev/null; then
    IS_EXIST=1
  fi
}

function gen() {
  gen_command="${RUNNER} -out ${CURRENT_DIR}/src --gen rs ${CURRENT_DIR}/thrift/rpc.thrift"
  echo "INFO: Gen command '${gen_command}'"
  command ${gen_command}
  sleep 3

  if [ -f "${CURRENT_DIR}/src/rpc.rs" ]; then
    echo "INFO: Gen code to '${CURRENT_DIR}/src'"
  else
    echo "ERROR: Code gen failed"
  fi
}

function download_source() {
  download_file="${BUILD_DIR}/${PKG_NAME}"
  if [ ! -f ${download_file} ]; then
    echo "INFO: Download thrift source code to ${download_file}"
    curl -o ${download_file} https://downloads.apache.org/thrift/${PKG_VERSION}/${PKG_NAME}
    tar xzf ${download_file} -C ${BUILD_DIR}
    rm -rf ${download_file}
  else
    echo "WARN: File ${download_file} exits "
    tar xzf ${download_file} -C ${BUILD_DIR}
    rm -rf ${download_file}
  fi
}

PKG_DIR=${BUILD_DIR}"/thrift-"${PKG_VERSION}
function build() {
  RUNNER=${DEV_RUNNER}
  build_file="${BUILD_DIR}/thrift"

  cd ${PKG_DIR}
  if [ ! -f ${build_file} ]; then
    echo "INFO: Build thrift from $(pwd)"
    ./configure --bindir=${BUILD_DIR} && make install

    if [ ! -f ${build_file} ]; then
      echo "ERROR: Build error, please retry"
    else
      chmod +x ${build_file}
      echo "INFO: Build successful. $(command ${build_file} -version)"
      gen
    fi
  else
    echo "INFO: Thrift exits. $(command ${build_file} -version)"
    gen
  fi
}

function build_from_source() {
  if [ -d ${PKG_DIR} ]; then
    build
  else
    download_source
    build
  fi
}

function fetch() {
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if [ -f /etc/redhat-release ]; then
      echo "Redhat Linux"
      build_from_source
    elif [ -f /etc/SuSE-release ]; then
      echo "Suse Linux"
      build_from_source
    elif [ -f /etc/arch-release ]; then
      echo "Arch Linux"
      build_from_source
    elif [ -f /etc/mandrake-release ]; then
      echo "Mandrake Linux"
      build_from_source
    elif [ -f /etc/debian_version ]; then
      echo "Ubuntu/Debian Linux" && CHECK_COMMAND="apt-get" && check_command
      if [ ${IS_EXIST_COMMAND} == 1 ]; then
        sudo apt-get install thrift-compiler
        gen
      else
        build_from_source
      fi
    else
      echo "Unknown Linux distribution."
      build_from_source
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac OS (Darwin)" && CHECK_COMMAND="brew" && check_command
    if [ ${IS_EXIST_COMMAND} == 1 ]; then
      brew reinstall thrift && thrift -version && gen
    else
      build_from_source
    fi
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    echo "FreeBSD"
    build_from_source
  else
    echo "Unknown operating system."
    build_from_source
  fi
}

function run() {
  CHECK_COMMAND=${OS_RUNNER} && check_command
  if [ ${IS_EXIST_COMMAND} == 1 ]; then
    echo "INFO: Thrift exits." $(thrift -version) && gen
  else
    fetch
  fi
}

run
