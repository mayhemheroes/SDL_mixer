cmake_minimum_required(VERSION 3.16 FATAL_ERROR)

# Fuzzer
add_executable(
    "${PROJECT_NAME}-fuzzer"
    "${CMAKE_CURRENT_LIST_DIR}/fuzz_load_music_from_mem.c"
)

# Ensure the fuzzer is being compiled with clang
if (NOT CMAKE_C_COMPILER_ID STREQUAL "Clang")
    message(FATAL_ERROR "Clang is required for libFuzzer!")
endif()

target_compile_options(
    "${PROJECT_NAME}-fuzzer"
    PUBLIC
    -fsanitize=fuzzer
)

target_link_options(
    "${PROJECT_NAME}-fuzzer"
    PUBLIC
    -fsanitize=fuzzer
)

target_link_libraries(
    "${PROJECT_NAME}-fuzzer"
    PRIVATE
    SDL3_mixer
)

if (TARGET SDL3::SDL3main)
    target_link_libraries("${PROJECT_NAME}-fuzzer" PRIVATE SDL3::SDL3main)
endif()
if (BUILD_SHARED_LIBS)
    target_link_libraries("${PROJECT_NAME}-fuzzer" PRIVATE SDL3::SDL3)
else()
    target_link_libraries("${PROJECT_NAME}-fuzzer" PRIVATE SDL3::SDL3-static)
endif()
