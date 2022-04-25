/*	Dust Ultimate Game Library (DUGL)
    Copyright (C) 2022	Fakhri Feki

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    contact: libdugl@hotmail.com    */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

SDL_AudioSpec wantAudio, haveAudio;
SDL_AudioDeviceID audDevId = 0;
#define MAX_SIMULTANOUS_DSOUNDS 64
DSoundState playingSounds[MAX_SIMULTANOUS_DSOUNDS];
DSoundState queuedSounds[MAX_SIMULTANOUS_DSOUNDS];
DSoundState replaceSounds[MAX_SIMULTANOUS_DSOUNDS];
unsigned int countPlayingSounds = 0;

void DGaudioCallback( void *userData, Uint8 * stream, int len )
{
    int remainLen, mixLen, requiredLen;
    int idx = 0, HandledSounds = 0;

    // silence buffer
    SDL_memset4( stream, 0, len/4 );

    if (countPlayingSounds == 0)
        return;
    // mix sounds
    for (;idx<MAX_SIMULTANOUS_DSOUNDS && HandledSounds < countPlayingSounds; idx++) {
        if (playingSounds[idx].sound != NULL) {
            // replace if required
            if (replaceSounds[idx].sound != NULL) {
                if(replaceSounds[idx].queueInheritEvents) {
                    replaceSounds[idx].OnFinish = playingSounds[idx].OnFinish;
                    replaceSounds[idx].OnLoop = playingSounds[idx].OnLoop;
                    replaceSounds[idx].OnQueue = playingSounds[idx].OnQueue;
                }
                playingSounds[idx] = replaceSounds[idx];
                replaceSounds[idx].sound = NULL;
            }

            // mix
            if (!playingSounds[idx].paused) {
                remainLen = playingSounds[idx].sound->length - playingSounds[idx].position;
                mixLen = (remainLen >= (unsigned int)(len)) ? len : remainLen;
                if (mixLen > 0)
                    SDL_MixAudioFormat(stream,
                                (Uint8 *)&playingSounds[idx].sound->data[playingSounds[idx].position],
                                haveAudio.format,
                                mixLen, (int)playingSounds[idx].volume);

                // sound finished
                if (remainLen <= len) {
                    requiredLen = len - remainLen; // bytes not filled yet in stream
                    if (playingSounds[idx].loop) {
                        if (!playingSounds[idx].stopEvents && playingSounds[idx].OnLoop != NULL)
                            playingSounds[idx].OnLoop(idx);
                        if (requiredLen > 0 && playingSounds[idx].sound != NULL && !playingSounds[idx].paused) {
                            if (requiredLen > playingSounds[idx].sound->length)
                                requiredLen = playingSounds[idx].sound->length;
                            playingSounds[idx].position = requiredLen;
                            SDL_MixAudioFormat(&stream[remainLen],
                                (Uint8 *)&playingSounds[idx].sound->data[0],
                                haveAudio.format,
                                requiredLen, (int)playingSounds[idx].volume);
                        } else {
                            if (playingSounds[idx].sound != NULL)
                                playingSounds[idx].position = 0;
                        }

                    } else {
                        if (queuedSounds[idx].sound != NULL) { // queued ?
                            daudioEventCallBack OnQueue = playingSounds[idx].OnQueue;
                            // inherit current playing sound events ?
                            if(queuedSounds[idx].queueInheritEvents) {
                                queuedSounds[idx].OnFinish = playingSounds[idx].OnFinish;
                                queuedSounds[idx].OnLoop = playingSounds[idx].OnLoop;
                                queuedSounds[idx].OnQueue = playingSounds[idx].OnQueue;
                            }
                            playingSounds[idx] = queuedSounds[idx];
                            if (requiredLen > 0 && !queuedSounds[idx].paused) {
                                SDL_MixAudioFormat(&stream[remainLen],
                                    (Uint8 *)&playingSounds[idx].sound->data[0],
                                    haveAudio.format,
                                    requiredLen, (int)playingSounds[idx].volume);
                                playingSounds[idx].position = requiredLen;
                            } else {
                                playingSounds[idx].position = 0;
                            }
                            queuedSounds[idx].sound = NULL;
                            if (!playingSounds[idx].stopEvents && OnQueue != NULL)
                                OnQueue(idx);
                        } else {
                            playingSounds[idx].sound = NULL;
                            countPlayingSounds--;
                            if (!playingSounds[idx].stopEvents && playingSounds[idx].OnFinish != NULL)
                                playingSounds[idx].OnFinish(idx);
                        }
                    }
                } else {
                    playingSounds[idx].position += len;
                }
            }
            HandledSounds++;
        }
    }
}

bool InstallDAudio(int frequency, bool stereo) {
    SDL_memset(&wantAudio, 0, sizeof(wantAudio));
    wantAudio.freq = (frequency >= 11025 && frequency <= 48000) ? frequency : 44000;
    wantAudio.format = AUDIO_S16SYS;
    wantAudio.channels = (stereo) ? 2 : 1;
    wantAudio.samples = 1024*2;
    wantAudio.callback = DGaudioCallback;

    audDevId = SDL_OpenAudioDevice(NULL, 0, &wantAudio, &haveAudio, SDL_AUDIO_ALLOW_CHANNELS_CHANGE | SDL_AUDIO_ALLOW_FREQUENCY_CHANGE);
    if (audDevId == 0)
        return false;
    SDL_PauseAudioDevice(audDevId, 1); // paused at startup

    SDL_memset(playingSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);
    SDL_memset(queuedSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);
    SDL_memset(replaceSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);

    countPlayingSounds = 0;

    return true;
}

void UninstallDAudio() {

    if (audDevId != 0) {
        SDL_PauseAudioDevice(audDevId, 1);
        SDL_CloseAudioDevice(audDevId);
        audDevId = 0;
        SDL_memset(playingSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);
        SDL_memset(queuedSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);
        SDL_memset(replaceSounds, 0, sizeof(DSoundState)*MAX_SIMULTANOUS_DSOUNDS);

        countPlayingSounds = 0;
    }
}

void PlayDAudio() {
    SDL_PauseAudioDevice(audDevId, 0);
}

void PauseDAudio() {
    SDL_PauseAudioDevice(audDevId, 1);
}

void LockDAudio() {
    SDL_UnlockAudioDevice(audDevId);
}

void UnlockDAudio() {
    SDL_UnlockAudioDevice(audDevId);
}

unsigned int PlayDSound(DSound *sound, unsigned char volume, bool loop, bool paused) {
    LockDAudio();
    int freeIdx = 0;

    if (countPlayingSounds == MAX_SIMULTANOUS_DSOUNDS) {
        UnlockDAudio();
        return NO_SOUND_ID;
    }
    // mix sounds
    for (;freeIdx<MAX_SIMULTANOUS_DSOUNDS && playingSounds[freeIdx].sound != NULL; freeIdx++);
    // shouldn't happen
    if (freeIdx >= MAX_SIMULTANOUS_DSOUNDS) {
        UnlockDAudio();
        return NO_SOUND_ID;
    }

    SDL_memset(&playingSounds[freeIdx], 0, sizeof(DSoundState));
    playingSounds[freeIdx].sound = sound;
    playingSounds[freeIdx].volume = (((unsigned int)volume+1)*SDL_MIX_MAXVOLUME)>>8;
    playingSounds[freeIdx].loop = loop;
    playingSounds[freeIdx].position = 0;
    playingSounds[freeIdx].paused = paused;

    countPlayingSounds++;

    UnlockDAudio();
    return freeIdx;
}

void StopDSound(unsigned int soundID) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[soundID].sound != NULL) {
        LockDAudio();
        playingSounds[soundID].sound = NULL;
        countPlayingSounds--;
        UnlockDAudio();
    }
}

void SetVolumeDSound(unsigned int soundID, unsigned char volume) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[soundID].sound != NULL) {
        playingSounds[soundID].volume = (((unsigned int)volume+1)*SDL_MIX_MAXVOLUME)>>8;
    }
}

void SetPausedDSound(unsigned int soundID, bool paused) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[soundID].sound != NULL) {
        playingSounds[soundID].paused = paused;
    }
}

void SetLoopingDSound(unsigned int soundID, bool loop) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[soundID].sound != NULL) {
        playingSounds[soundID].loop = loop;
    }
}

void SetStopEventsDSound(unsigned int soundID, bool stopEvents) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[soundID].sound != NULL) {
        playingSounds[soundID].stopEvents = stopEvents;
    }
}

DSoundState* GetPlayingStateDSound(unsigned int soundID) {
    if (soundID<MAX_SIMULTANOUS_DSOUNDS) {
        return &playingSounds[soundID];
    }
    return NULL;
}

void SetEventsDSound(unsigned int soundID, daudioEventCallBack OnFinish, daudioEventCallBack OnLoop, daudioEventCallBack OnQueue) {
    if (soundID < MAX_SIMULTANOUS_DSOUNDS) {
        LockDAudio();
        if (playingSounds[soundID].sound != NULL) {
            playingSounds[soundID].OnFinish = OnFinish;
            playingSounds[soundID].OnLoop = OnLoop;
            playingSounds[soundID].OnQueue = OnQueue;
        }
        UnlockDAudio();
    }
}

bool QueueDSound(unsigned int soundID, DSound *sound, unsigned char volume, bool loop, bool paused, bool inheritEvents) {
    bool res = false;
    LockDAudio();
    if (playingSounds[soundID].sound != NULL && queuedSounds[soundID].sound == NULL) {
        SDL_memset(&queuedSounds[soundID], 0, sizeof(DSoundState));
        queuedSounds[soundID].sound = sound;
        queuedSounds[soundID].volume = (((unsigned int)volume+1)*SDL_MIX_MAXVOLUME)>>8;
        queuedSounds[soundID].loop = loop;
        queuedSounds[soundID].position = 0;
        queuedSounds[soundID].paused = paused;
        queuedSounds[soundID].queueInheritEvents = inheritEvents;
        res = true;
    }
    UnlockDAudio();
    return res;
}

bool ReplaceDSound(unsigned int *soundID, DSound *sound, unsigned char volume, bool loop, bool paused, bool inheritEvents) {
    bool res = false;
    LockDAudio();
    if (*soundID < MAX_SIMULTANOUS_DSOUNDS && playingSounds[*soundID].sound != NULL) {
        SDL_memset(&replaceSounds[*soundID], 0, sizeof(DSoundState));
        replaceSounds[*soundID].sound = sound;
        replaceSounds[*soundID].volume = (((unsigned int)volume+1)*SDL_MIX_MAXVOLUME)>>8;
        replaceSounds[*soundID].loop = loop;
        replaceSounds[*soundID].position = 0;
        replaceSounds[*soundID].paused = paused;
        replaceSounds[*soundID].queueInheritEvents = inheritEvents;
        res = true;
    } else { // no sound playing ? add new playing sound
        *soundID = PlayDSound(sound, volume, loop, paused);
    }
    UnlockDAudio();
    return res;
}

bool IsQueuedDSound(unsigned int soundID) {
    bool res = false;
    if (soundID < MAX_SIMULTANOUS_DSOUNDS) {
        LockDAudio();
        res = (queuedSounds[soundID].sound != NULL);
        UnlockDAudio();
    }
    return res;
}

bool IsPlayingDSound(unsigned int soundID) {
    bool res = false;
    if (soundID < MAX_SIMULTANOUS_DSOUNDS) {
        LockDAudio();
        res = (playingSounds[soundID].sound != NULL);
        UnlockDAudio();
    }
    return res;
}

unsigned int GetPlayingDSoundCount() {
    return countPlayingSounds;
}

DSound *DgLoadWAV(char *filename) {
    DSound *sound = NULL;
    SDL_AudioSpec wav_spec;
    Uint32 wavLength = 0;
    Uint8 *wavBuffer = NULL;
    SDL_AudioCVT cvt;

    if (audDevId != 0) {
        if (SDL_LoadWAV(filename, &wav_spec, &wavBuffer, &wavLength) != NULL) {
            // convert to current audio device format
           	SDL_BuildAudioCVT(&cvt, wav_spec.format, wav_spec.channels, wav_spec.freq, haveAudio.format, haveAudio.channels, haveAudio.freq);
           	if (cvt.needed) {
                cvt.buf =(Uint8*)SDL_malloc(wavLength*((Uint32)cvt.len_mult));
                if (cvt.buf != NULL) {
                    cvt.len = wavLength;
                    SDL_memcpy(cvt.buf, wavBuffer, wavLength);
                    if (SDL_ConvertAudio(&cvt) == 0) {
                        sound = (DSound*)SDL_malloc(sizeof(DSound) + cvt.len_cvt);
                        if (sound != NULL) {
                            sound->data = &((Uint8 *)sound)[sizeof(DSound)];
                            sound->length = cvt.len_cvt;
                            SDL_memcpy(sound->data, cvt.buf, cvt.len_cvt);
                        }
                    }
                    SDL_free(cvt.buf);
                }
           	} else { // copy data as-is, no conversion needed
           	    sound = (DSound*)SDL_malloc(sizeof(DSound) + wavLength);
           	    if (sound != NULL) {
                    sound->data = &((Uint8 *)sound)[sizeof(DSound)];
                    sound->length = wavLength;
                    SDL_memcpy(sound->data, wavBuffer, wavLength);
           	    }
           	}
            SDL_FreeWAV(wavBuffer);
        }
    }
    return sound;
}

void DestroyDSound(DSound *sound) {
    sound->length = 0;
    sound->data = NULL;
    SDL_free(sound);
}
