#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#include "SDL3/SDL.h"
#include "SDL3_mixer/SDL_mixer.h"

bool lib_init = false;

void init_lib() {
    if (!SDL_Init(SDL_INIT_AUDIO))
        exit(0);
    lib_init = true;
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    Mix_Music *music = NULL;
    if (!lib_init)
        init_lib();

    SDL_IOStream *src = SDL_IOFromConstMem(data, size);
    if (!src)
        return 0;

    music = Mix_LoadMUS_IO(src, SDL_TRUE);

    if (music) {
        Mix_MusicType type = Mix_GetMusicType(music);
        Mix_FreeMusic(music);
    } else {
        SDL_CloseIO(src);
    }

    return 0;
}
