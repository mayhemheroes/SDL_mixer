cmake_minimum_required(VERSION 3.1.0 FATAL_ERROR)

# Fuzzer
add_executable(
    "${PROJECT_NAME}-fuzzer"
    "${CMAKE_CURRENT_LIST_DIR}/fuzz.c"
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
    -fsanitize=fuzzer -lSDL2main -lSDL2
)

message(STATUS ${SDLSOUND_LIB_TARGET})
message(STATUS ${OTHER_LDFLAGS})

target_link_libraries(
    "${PROJECT_NAME}-fuzzer"
    PRIVATE
    ${SDLSOUND_LIB_TARGET} ${OTHER_LDFLAGS}
)
