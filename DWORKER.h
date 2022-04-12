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

#ifndef DWORKER_H_INCLUDED
#define DWORKER_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// DWorker support =====================================================================

typedef void (*dworkerFunctionPointer)(void*, int);
#define DWORKERS_DEFAULT_MAX_COUNT	128

bool InitDWorkers(unsigned int MAX_DWorker);
void DestroyDWorkers();
unsigned int CreateDWorker(dworkerFunctionPointer workerFunction, void *workerData);
void RunDWorker(unsigned int dworkerID, bool WaitIfBusy);
void SetDWorkerDataPtr(unsigned int dworkerID, void *dataPtr);
void SetDWorkerFunction(unsigned int dworkerID, dworkerFunctionPointer workerFunction);
void SetDWorkerPriority(int priority); // 0 highest - 3 lowest
bool IsBusyDWorker(unsigned int dworkerID);
void WaitDWorker(unsigned int dworkerID);
bool WaitTimeOutDWorker(unsigned int dworkerID, unsigned int timeOut);
void DestroyDWorker(unsigned int dworkerID);
// Mutex
void *CreateDMutex();
void  DestroyDMutex(void *DMutexPtr);
void  LockDMutex(void *DMutexPtr);
void  UnlockDMutex(void *DMutexPtr);
bool  TryLockDMutex(void *DMutexPtr);

#ifdef __cplusplus
		}  // extern "C" {
#endif

#endif // DWORKER_H_INCLUDED

