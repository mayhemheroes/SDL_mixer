# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y git clang cmake make libsdl2-dev libogg-dev libmpg123-dev

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
RUN CC=clang CFLAGS="-fPIE" cmake .. -DINSTRUMENT=1 -DSUPPORT_FLAC=1 -DSUPPORT_OPUS=1 -DSUPPORT_MP3_MPG123=1 -DSUPPORT_MID_TIMIDITY=0
RUN make -j$(nproc)

## Consolidate all dynamic libraries used by the fuzzer
RUN mkdir /deps
RUN cp `ldd ./fuzz/SDL2_mixer-fuzzer | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq` /deps 2>/dev/null || :

## Package Stage
FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libsdl2-dev libmpg123-dev
COPY --from=builder /SDL_mixer/build/fuzz/SDL2_mixer-fuzzer /SDL2_mixer-fuzzer
COPY --from=builder /deps /usr/lib
COPY --from=builder /SDL_mixer/fuzz/corpus /corpus

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL2_mixer-fuzzer /corpus -close_fd_mask=2
