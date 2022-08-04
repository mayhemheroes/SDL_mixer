# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y clang git cmake make libsdl2-dev libogg-dev libmpg123-dev

## Add source code to the build stage.
WORKDIR /
ADD . /SDL_mixer
WORKDIR SDL_mixer

## Download external dependencies
WORKDIR external
RUN ./download.sh || true

## Build
WORKDIR /SDL_mixer
RUN mkdir -p build
WORKDIR build
RUN CC=clang CFLAGS="-fPIE" cmake .. -DINSTRUMENT=1 -DSUPPORT_FLAC=1 -DSUPPORT_OPUS=1 -DSUPPORT_MP3_MPG123=1 -DSUPPORT_MID_TIMIDITY=0
RUN make -j$(nproc)

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libsdl2-2.0-0

# Does not accept these libraries from apt, must be copied over
COPY --from=builder /SDL_mixer/build/fuzz/SDL2_mixer-fuzzer /SDL2_mixer-fuzzer
COPY --from=builder /SDL_mixer/build/libSDL2_mixer-2.0.so.0 /usr/lib
COPY --from=builder /SDL_mixer/build/external/opus/libopus.so.0 /usr/lib
COPY --from=builder /SDL_mixer/build/external/opusfile/libopusfile.so.0 /usr/lib
COPY --from=builder /SDL_mixer/fuzz/corpus /corpus
COPY --from=builder /SDL_mixer/build/external/mpg123/ports/cmake/src/libmpg123/libmpg123.so /usr/lib

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL2_mixer-fuzzer /corpus
