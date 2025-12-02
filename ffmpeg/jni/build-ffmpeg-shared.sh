#!/bin/bash
ROOT=$(cd "$(dirname "$0")"; pwd)
source ${ROOT}/util.sh

build_type=release
debug_flag=""
for p in $*
do
  case "$p" in
    --debug )
      debug_flag="--debug"
      build_type=debug
      ;;
  esac
  done

if test -t 1 && which tput >/dev/null 2>&1; then 
    ncolors=$(tput colors)
    if test -n "$ncolors" && test $ncolors -ge 8; then 
        bold_color=$(tput bold)
        warn_color=$(tput setaf 3)
        error_color=$(tput setaf 1)
        reset_color=$(tput sgr0)
    fi   
    # 72 used instead of 80 since that's the default of pr
    ncols=$(tput cols)
fi
: ${ncols:=72}

# Only load ENV if NDK is not already set (for local builds)
if [ -z "${NDK}" ]; then
    . ENV # Environment
fi

cd ffmpeg

make clean
rm compat/strtod.d
rm compat/strtod.o

echo "=====================CONFIGURE FFMPEG (SHARED) FOR $1====================="
make distclean

# Use a modified configuration for shared libraries
# We pass a special flag to config-ffmpeg.sh or set an env var to enable shared
export ENABLE_SHARED_LIBS=true
../config-ffmpeg.sh $1 $debug_flag

if test "$?" != 0; then 
    die "ERROR: failed to configure ffmpeg for $1"
fi

make clean
make -j$(nproc)

# Copy shared libraries to libs directory
cd ..
DST_DIR=$(get_dst_dir $1)
mkdir -p ${DST_DIR}

echo "Copying shared libraries to ${DST_DIR}..."
cp ffmpeg/libavcodec/libavcodec.so ${DST_DIR}/ || echo "libavcodec.so not found"
cp ffmpeg/libavformat/libavformat.so ${DST_DIR}/ || echo "libavformat.so not found"
cp ffmpeg/libavutil/libavutil.so ${DST_DIR}/ || echo "libavutil.so not found"
cp ffmpeg/libavfilter/libavfilter.so ${DST_DIR}/ || echo "libavfilter.so not found"
cp ffmpeg/libswscale/libswscale.so ${DST_DIR}/ || echo "libswscale.so not found"
cp ffmpeg/libswresample/libswresample.so ${DST_DIR}/ || echo "libswresample.so not found"

echo "Shared library build complete."
