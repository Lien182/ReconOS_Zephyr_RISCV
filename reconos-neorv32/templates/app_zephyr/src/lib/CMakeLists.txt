# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(lib)

FILE(GLOB reconos runtime/comp/*.c runtime/arch/*.c runtime/reconos_app.c runtime/reconos.c )
include_directories(include)
target_sources(app PRIVATE ${reconos})
