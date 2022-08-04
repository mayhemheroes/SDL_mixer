#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

#include "SDL.h"
#include "SDL_mixer.h"

#define READ_BUFF_SIZE 4096
bool lib_init = false;

void init_lib() {
    if (SDL_Init(SDL_INIT_AUDIO) < 0)
        exit(0);
    lib_init = true;
}

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
    Mix_Music *music = NULL;
    if (!lib_init)
        init_lib();

    // Create a new buffer of non-const fuzzer data
    uint8_t fuzz_data[size];
    memcpy(fuzz_data, data, size);

    SDL_RWops *src = SDL_RWFromMem(fuzz_data, size);
    if (!src)
        return 0;

    music = Mix_LoadMUS_RW(src, SDL_TRUE);

    if (music) {
        // Try and get music type
        Mix_MusicType type = Mix_GetMusicType(music);
        Mix_FreeMusic(music);
        if (src)
            SDL_RWclose(src);
    }

    return 0;
}
