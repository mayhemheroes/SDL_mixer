# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git clang cmake make libsdl2-dev libogg-dev

## Add source code to the build stage.
WORKDIR /
RUN git clone https://github.com/capuanob/SDL_mixer.git
WORKDIR SDL_mixer
RUN git checkout mayhem

## Download external dependencies
WORKDIR external
RUN ./download.sh

## Build
WORKDIR /SDL_mixer
RUN mkdir build
WORKDIR build
RUN CC=clang cmake .. -DINSTRUMENT=1 -DSUPPORT_FLAC=1 -DSUPPORT_OGG=1 -DSUPPORT_OPUS=1 -DSUPPORT_MP3_MPG123=1 -DSUPPORT_MOD_MODPLUG=1
RUN make -j$(nproc)

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libsdl2-dev
COPY --from=builder /SDL_sound/build/fuzz/SDL_sound-fuzzer /SDL_sound-fuzzer
COPY --from=builder /SDL_sound/fuzz/corpus /corpus

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL_sound-fuzzer /corpus -close_fd_mask=2
