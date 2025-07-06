#!/usr/bin/env zsh

set -e
set -x

echo "AMBER INSTALLER 1.0"

# Set environment variables for libclang
export LIBCLANG_PATH=/usr/local/llvm16/lib
export LD_LIBRARY_PATH=$LIBCLANG_PATH:$LD_LIBRARY_PATH

echo "LIBCLANG_PATH: $LIBCLANG_PATH"

# Clean previous build artifacts
echo "Cleaning previous build artifacts..."
rm -rf /home/dev/.local/bun /home/dev/.local/bun_minimal /home/dev/.local/bun_temp /home/dev/.bun/bin

# Clone the Bun repository if it doesn't exist
if [ ! -d /home/dev/bun-main ]; then
    echo "Cloning Bun repository..."
    git clone https://github.com/oven-sh/bun /home/dev/bun-main
fi

cd /home/dev/bun-main

# Set necessary environment variables
export CXXFLAGS="-I/usr/local/include"
export LDFLAGS="-L/usr/local/lib"

# Verify Zig installation
echo "Verifying Zig installation..."
if [ ! -d /home/dev/bun-main/src/deps/zig ]; then
    echo "Zig installation not found. Downloading Zig libraries..."
    mkdir -p /home/dev/bun-main/src/deps/zig
    curl -L https://ziglang.org/download/0.8.1/zig-0.8.1.tar.xz | tar -xJ --strip-components=1 -C /home/dev/bun-main/src/deps/zig
fi

# Patch CMakeLists.txt to remove the requirement for BUN_EXECUTABLE
echo "Patching CMakeLists.txt..."
sed -i.bak '/find_program(BUN_EXECUTABLE bun)/d' CMakeLists.txt
sed -i /BUN_EXECUTABLE/d CMakeLists.txt

# Build Bun with Clang
build_bun() {
    echo "Configuring Bun build..."
    cmake -S . -B /home/dev/.local/bun -DZIG_COMPILER=/usr/local/bin/zig -DCMAKE_CXX_FLAGS="-fno-pie" -DCMAKE_EXE_LINKER_FLAGS="-nopie" -DCMAKE_BUILD_TYPE=Release

    echo "Building Bun..."
    make -C /home/dev/.local/bun > build.log 2>&1
    tail -n 100 build.log
}

if ! build_bun; then
    echo "Failed to build with Clang."
    exit 1
fi

# Verify if the 'bun' executable is present
if [ -f /home/dev/.local/bun/bin/bun ]; then
    echo "Bun has been successfully built."
else
    echo "Bun build failed. Check the logs for details."
    exit 1
fi

# Run a basic command to verify 'bun' functionality
/home/dev/.local/bun/bin/bun --help

