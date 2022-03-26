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

#ifndef DTIMER_H_INCLUDED
#define DTIMER_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// Time Support ==============================================
void DgInstallTimer(int Freq);
void DgUninstallTimer();

// Timer Synch<ronisation>

#define SIZE_SYNCH_BUFF 168

extern unsigned int DgTime;
extern int DgTimerFreq;

int  InitSynch(void *SynchBuff,int *Pos,float Freq); // init Synch buffer and start synching
void StartSynch(void *SynchBuff,int *Pos); // Restart Synching
int  Synch(void *SynchBuff,int *Pos); // synch
float SynchAccTime(void *SynchBuff); // time "in sec" since InitSynch or StartSynch
float SynchAverageTime(void *SynchBuff); // average time "in sec" between Synch calls
float SynchLastTime(void *SynchBuff); // last non zero time "in sec" between Synch calls
int  WaitSynch(void *SynchBuff,int *Pos);
void DelayMs(unsigned int delayInMs); // wait DelayInMs


#ifdef __cplusplus
		}  // extern "C" {
#endif


#endif // DTIMER_H_INCLUDED

