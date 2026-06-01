cmake_minimum_required(VERSION 3.18)
project("ambot-image-core")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

# Build options for Android - static libs to minimize .so loading
set(SD_VULKAN OFF CACHE BOOL "Enable Vulkan backend (experimental, high memory usage)" FORCE)
set(SD_BUILD_EXAMPLES OFF CACHE BOOL "Disable examples" FORCE)
set(SD_BUILD_SHARED_LIBS OFF CACHE BOOL "Build static library for single .so" FORCE)
set(SD_WEBP OFF CACHE BOOL "Disable WebP" FORCE)
set(SD_WEBM OFF CACHE BOOL "Disable WebM" FORCE)

# Vulkan cross-compilation: use NDK sysroot for headers/lib, host glslc for shaders
# MUST be before add_subdirectory so ggml picks up the NDK Vulkan paths
if(SD_VULKAN AND ANDROID)
    # CMAKE_SYSROOT is set by NDK toolchain before this CMakeLists.txt runs
    set(Vulkan_INCLUDE_DIR "${CMAKE_SYSROOT}/usr/include" CACHE PATH "Vulkan include dir (NDK)")
    # Map ANDROID_ABI to NDK target triple
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(_VK_TRIPLE "aarch64-linux-android")
    elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
        set(_VK_TRIPLE "arm-linux-androideabi")
    elseif(ANDROID_ABI STREQUAL "x86_64")
        set(_VK_TRIPLE "x86_64-linux-android")
    elseif(ANDROID_ABI STREQUAL "x86")
        set(_VK_TRIPLE "i686-linux-android")
    else()
        set(_VK_TRIPLE "aarch64-linux-android")
    endif()
    # Find highest API libvulkan.so under NDK sysroot for the target ABI
    file(GLOB_RECURSE _VULKAN_LIBS "${CMAKE_SYSROOT}/usr/lib/${_VK_TRIPLE}/libvulkan.so")
    if(_VULKAN_LIBS)
        list(SORT _VULKAN_LIBS)
        list(GET _VULKAN_LIBS -1 Vulkan_LIBRARY)
        set(Vulkan_LIBRARY "${Vulkan_LIBRARY}" CACHE FILEPATH "Vulkan library (NDK)")
    endif()
    unset(_VULKAN_LIBS)
    unset(_VK_TRIPLE)
endif()

# stable-diffusion.cpp as static library, linked into sd-server.so
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp ${CMAKE_CURRENT_BINARY_DIR}/sd-build)

# ---- sd-server as a shared library loaded via JNI ----
# Uses the same HTTP server code as the executable, but built as libsd-server.so
# so it can be loaded via System.loadLibrary() without SELinux restrictions.

set(SD_SERVER_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/main.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/runtime.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/async_jobs.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/routes_index.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/routes_openai.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/routes_sdapi.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server/routes_sdcpp.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/common/common.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/common/log.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/common/media_io.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/sd_server_jni.cpp
)

add_library(sd-server SHARED ${SD_SERVER_SOURCES})

target_include_directories(sd-server PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/include
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/src
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/examples/server
    ${CMAKE_CURRENT_SOURCE_DIR}/stable-diffusion.cpp/thirdparty
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(sd-server
    stable-diffusion
    android
    log
)

# Compiler flags for ARM64 optimization
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(sd-server PRIVATE -O3 -march=armv8-a)
endif()

# Define SD_AS_LIBRARY so main.cpp knows to skip the standalone main()
target_compile_definitions(sd-server PRIVATE SD_AS_LIBRARY)
