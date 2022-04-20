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

#ifndef DAUDIO_H_INCLUDED
#define DAUDIO_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef struct DSound {
	unsigned char       *data;
	unsigned int        length;
} DSound;

bool InstallDAudio(int frequency, bool stereo);
void UninstallDAudio();
void PlayDAudio();
void PauseDAudio();
void LockDAudio();
void UnlockDAudio();
DSound *DgLoadWAV(char *filename);
void DestroyDSound(DSound *sound);

unsigned int PlayDSound(DSound *sound, unsigned char volume, bool loop, bool paused);
void StopDSound(unsigned int soundID);
void SetVolumeDSound(unsigned int soundID, unsigned char volume);
void SetPausedDSound(unsigned int soundID, bool paused);
void SetLoopingDSound(unsigned int soundID, bool loop);
void QueueDSound(unsigned int soundID, DSound *sound, unsigned char volume, bool loop, bool paused);
bool IsQueuedDSound(unsigned int soundID);
unsigned int GetPlayingDSoundCount();

#ifdef __cplusplus
		}  // extern "C" {
#endif


#endif // DAUDIO_H_INCLUDED
