# Build Stage
FROM --platform=linux/amd64 ubuntu:22.04 as builder

## Install build dependencies.
RUN for i in 1 2 3 4 5; do \
      apt-get update --fix-missing && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing \
        clang git cmake make ninja-build pkg-config \
        libogg-dev libmpg123-dev libopusfile-dev libflac-dev libxmp-dev && break || \
      { echo "Attempt $i failed, retrying..."; sleep 15; }; \
    done

## Build and install SDL3 from source
WORKDIR /build
RUN git clone --depth=1 https://github.com/libsdl-org/SDL.git /build/SDL3
WORKDIR /build/SDL3
RUN cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DSDL_X11=OFF -DSDL_WAYLAND=OFF -DSDL_OFFSCREEN=ON -DSDL_RENDER=OFF -DSDL_AUDIO=ON && \
    cmake --build build --parallel $(nproc) && \
    cmake --install build

## Add source code to the build stage.
WORKDIR /
ADD . /SDL_mixer
WORKDIR /SDL_mixer

## Download external dependencies
WORKDIR /SDL_mixer/external
RUN ./download.sh || true

## Build
WORKDIR /SDL_mixer
RUN mkdir -p build
WORKDIR /SDL_mixer/build
RUN CC=clang CFLAGS="-fPIE" cmake .. \
    -DINSTRUMENT=1 \
    -DSDL3MIXER_FLAC=ON \
    -DSDL3MIXER_MP3_MPG123=ON \
    -DSDL3MIXER_MIDI_FLUIDSYNTH=OFF \
    -DSDL3MIXER_DEPS_SHARED=OFF \
    -DCMAKE_PREFIX_PATH=/usr/local
RUN make -j$(nproc)

## Package Stage
FROM --platform=linux/amd64 ubuntu:22.04
RUN for i in 1 2 3 4 5; do \
      apt-get update --fix-missing && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing libmpg123-0 libflac8 libopus0 libopusfile0 libxmp4 && break || \
      { echo "Attempt $i failed, retrying..."; sleep 15; }; \
    done

COPY --from=builder /SDL_mixer/build/fuzz/SDL3_mixer-fuzzer /SDL3_mixer-fuzzer
COPY --from=builder /usr/local/lib/libSDL3.so* /usr/lib/
COPY --from=builder /SDL_mixer/build/libSDL3_mixer.so* /usr/lib/
COPY --from=builder /SDL_mixer/fuzz/corpus /corpus

## Set up fuzzing!
ENTRYPOINT []
CMD /SDL3_mixer-fuzzer /corpus
