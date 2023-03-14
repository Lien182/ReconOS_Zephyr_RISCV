# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

set(BOARD neorv32)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(<<projectname>>)
add_subdirectory(src/lib build)        #Adding the subdirectory cmake
include_directories(src/lib/include)
FILE(GLOB sources src/application/*.c <<softwarethread>>)
target_sources(app PRIVATE ${sources})