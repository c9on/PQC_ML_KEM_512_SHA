#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT/tools/iverilog_build"
PREFIX="$ROOT/tools/iverilog_local"
mkdir -p "$BUILD_DIR" "$PREFIX"
cd "$BUILD_DIR"

if [ ! -f "$PREFIX/bin/iverilog" ]; then
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR" "$PREFIX"
  curl -L --fail -o "$BUILD_DIR/iverilog.tar.gz" https://github.com/steveicarus/iverilog/archive/refs/tags/v13_0.tar.gz
  tar -xzf "$BUILD_DIR/iverilog.tar.gz" --strip-components=1 -C "$BUILD_DIR"
  cd "$BUILD_DIR"
  ./configure --prefix="$PREFIX"
  make -j"$(nproc)"
  make install
fi

echo "iverilog ready at $PREFIX/bin/iverilog"
