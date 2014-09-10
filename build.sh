#!/bin/bash

# use extended globbing features
shopt -s extglob

#-- error function
function die {
  code=-1
  err="Unknown error!"
  test "$1" && err=$1
  cd ${top_root}
  echo "$err"
  echo "Check the build log: ${build_log}"
  exit -1
}

#-- set up environment variables, folder structure, and log files
function initialize {
  echo "Setting up build environment ..."

  # environment variables
  top_root=$PWD
  depot_tools_root=${top_root}/depot_tools
  src_root=${top_root}/src
  build_root=${top_root}/build
  dist_root=${top_root}/build/dist
  dist_bin_root=${dist_root}/bin
  dist_include_root=${dist_root}/include
  dist_lib_root=${dist_root}/lib
  build_log=${top_root}/build/build.log
  config_file=${top_root}/.build-config.sh

  # create our folder structure
  cd ${top_root}
  test -d ${src_root} || mkdir -p ${src_root}
  test -d ${build_root} || mkdir -p ${build_root}
  test -d ${dist_root} || mkdir -p ${dist_root}
  test -d ${dist_bin_root} || mkdir -p ${dist_bin_root}
  test -d ${dist_include_root} || mkdir -p ${dist_include_root}
  test -d ${dist_lib_root} || mkdir -p ${dist_lib_root}
  touch ${build_log}

  rm -f ${build_log}
  touch ${build_log}

  # create our configuration file if it doesn't yet exist
  if [ ! -f "${config_file}" ]; then
    # save our configuration
    echo "Saving configuration into ${config_file} ..."
    echo 'export PATH="$PATH:${depot_tools_root}"' > ${config_file}
  fi

  # show the user our configuration, then import it
  source ${config_file}
}

#-- get the Chromium depot_tools
function clone_depot_tools {
  echo "Getting the Chromium depot_tools ..."
  git clone "https://chromium.googlesource.com/chromium/tools/depot_tools.git" ${depot_tools_root} >> ${build_log} 2>&!
}

function ensure_depot_tools {
  test -d "${depot_tools_root}" || clone_depot_tools
  test -x "${depot_tools_root}/gclient" || clone_depot_tools
  test -x "${depot_tools_root}/ninja" || clone_depot_tools
}

#-- get the WebRTC source
function fetch_webrtc_source {
  echo "Getting the WebRTC source (this may take a while) ..."
  cd ${src_root}
  gclient config http://webrtc.googlecode.com/svn/trunk -v -v -v >> ${build_log} 2>&1
  echo "target_os = ['ios', 'mac']" >> .gclient
  gclient sync --force -v -v -v -j1 >> ${build_log} 2>&1
}

##-- build WebRTC for the passed-in platform
function build {
  test "$1" || die "No platform supplied when building"
  platform="$1"

  cd ${src_root}

  case $platform in
  ios)
    os="ios"
    target_arch="armv7"
    crosscompile="1"
    debug_dir_suffix="-iphoneos"
    ;;
  mac)
    os="mac"
    target_arch="x64"
    crosscompile=""
    debug_dir_suffix=""
    ;;
  sim)
    os="ios"
    target_arch="ia32"
    crosscompile="1"
    debug_dir_suffix=""
    ;;
  *)
    die 'Platform must be one of: "ios", "mac", or "sim"'
  esac

  # set up gyp build environment
  output_dir="${build_root}/out_$platform"
  export GYP_GENERATORS="ninja"
  export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_objc=1 OS=$os target_arch=$target_arch"
  export GYP_GENERATOR_FLAGS="$GYP_GENERATOR_FLAGS output_dir=$output_dir"
  test "$crosscompile" && export GYP_CROSSCOMPILE="1"

  # build
  echo "Building for $platform ..."
  gclient runhooks -v -v -v -j1 >> ${build_log} 2>&1
  ninja -C ${output_dir}/Debug${debug_dir_suffix} AppRTCDemo >> ${build_log} 2>&1
}


#-- main
set -e  # fail hard on any error

initialize
ensure_depot_tools || die "Couldn't get Chromium depot_tools"
fetch_webrtc_source || die "Couldn't get WebRTC source code"
for platform in $(echo "mac sim ios"); do
  build $platform || die "Couldn't build for $platform"
done

echo "Look in ${dist_root} for libraries and executables."
