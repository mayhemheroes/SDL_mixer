# Build Stage
FROM --platform=linux/amd64 ubuntu:22.04 as builder

## Install build dependencies.
RUN for i in 1 2 3 4 5; do \
      apt-get update --fix-missing && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing clang git cmake make libsdl2-dev libogg-dev libmpg123-dev libopusfile-dev libflac-dev libxmp-dev && break || \
      { echo "Attempt $i failed, retrying..."; sleep 15; }; \
    done

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
RUN CC=clang CFLAGS="-fPIE" cmake .. -DINSTRUMENT=1 -DSUPPORT_FLAC=1 -DSUPPORT_OPUS=1 -DSUPPORT_MP3_MPG123=1 -DSUPPORT_MID_TIMIDITY=0 -DSDL2MIXER_MIDI_FLUIDSYNTH=0
RUN make -j$(nproc)

## Package Stage
FROM --platform=linux/amd64 ubuntu:22.04
RUN for i in 1 2 3 4 5; do \
      apt-get update --fix-missing && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing libsdl2-2.0-0 && break || \
      { echo "Attempt $i failed, retrying..."; sleep 15; }; \
    done

# Does not accept these libraries from apt, must be copied over
COPY --from=builder /SDL_mixer/build/fuzz/SDL2_mixer-fuzzer /SDL2_mixer-fuzzer
COPY --from=builder /SDL_mixer/build/libSDL2_mixer-2.0.so.0 /usr/lib
COPY --from=builder /SDL_mixer/fuzz/corpus /corpus

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL2_mixer-fuzzer /corpus
