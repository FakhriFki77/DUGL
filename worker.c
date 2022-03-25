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

#include "SDL.h"

#include "DUGL.h"
#include "intrndugl.h"

unsigned int countDWorker = 0;
unsigned int MaxDWorkersCount = 0;
unsigned int FirstFreeDWorkerID = 0;
bool *conditionsDWorker = NULL;
SDL_mutex **locksDworker = NULL;
SDL_cond **condsDworker = NULL;
SDL_Thread **threadsDWorker = NULL;
dworkerFunctionPointer *funcsDWorker = NULL;
void **paramsDWorker = NULL;
unsigned int *dataThreadsID = NULL;

bool InitDWorkers(unsigned int MAX_DWorkers) {
	if (countDWorker > 0 || (MAX_DWorkers > 0 && MAX_DWorkers < 4))
		return false;
	unsigned int maxDWorkers = (MAX_DWorkers == 0) ? DWORKERS_DEFAULT_MAX_COUNT : MAX_DWorkers;
	conditionsDWorker = (bool *)SDL_malloc(sizeof(bool)*maxDWorkers);
	locksDworker = (SDL_mutex **)SDL_malloc(sizeof(SDL_mutex *)*maxDWorkers);
	condsDworker = (SDL_cond **)SDL_malloc(sizeof(SDL_cond *)*maxDWorkers);
	threadsDWorker = (SDL_Thread **)SDL_malloc(sizeof(SDL_Thread *)*maxDWorkers);
	funcsDWorker = (dworkerFunctionPointer *)SDL_malloc(sizeof(dworkerFunctionPointer)*maxDWorkers);
	paramsDWorker = (void**)SDL_malloc(sizeof(void *)*maxDWorkers);
	dataThreadsID = (unsigned int*)SDL_malloc(sizeof(unsigned int)*maxDWorkers);
	if (conditionsDWorker != NULL && locksDworker != NULL && condsDworker != NULL && threadsDWorker != NULL &&
		paramsDWorker != NULL && dataThreadsID != NULL) {
		MaxDWorkersCount = maxDWorkers;
		SDL_memset4(conditionsDWorker, 0, sizeof(bool)*maxDWorkers/4);
		SDL_memset4(locksDworker, 0, sizeof(SDL_mutex *)*maxDWorkers/4);
		SDL_memset4(condsDworker, 0, sizeof(SDL_cond *)*maxDWorkers/4);
		SDL_memset4(threadsDWorker, 0, sizeof(SDL_Thread *)*maxDWorkers/4);
		SDL_memset4(paramsDWorker, 0, sizeof(void *)*maxDWorkers/4);
		for (unsigned int i=0; i<maxDWorkers; i++) dataThreadsID[i] = i+1;
		FirstFreeDWorkerID = 0;
		return true;
	}
	DestroyDWorkers();
	return false;
}

bool DestroyDWorkers() {
	if (countDWorker > 0)
		return false;
	if (conditionsDWorker != NULL)
		SDL_free(conditionsDWorker);
	if (locksDworker != NULL)
		SDL_free(locksDworker);
	if (condsDworker != NULL)
		SDL_free(condsDworker);
	if (threadsDWorker != NULL)
		SDL_free(threadsDWorker);
	if (paramsDWorker != NULL)
		SDL_free(paramsDWorker);
	if (dataThreadsID != NULL)
		SDL_free(dataThreadsID);

	countDWorker = 0;
	MaxDWorkersCount = 0;
	conditionsDWorker = NULL;
	locksDworker = NULL;
	condsDworker = NULL;
	threadsDWorker = NULL;
	paramsDWorker = NULL;
	dataThreadsID = NULL;
	return true;
}

static int WorkerThreadFunction(void *ptr) {
	unsigned int myIdx = *(unsigned int*)(ptr);
	if (MaxDWorkersCount == 0 || myIdx == 0 || myIdx > MaxDWorkersCount)
		return 0;
	myIdx --;
	for(;;) {
		SDL_LockMutex(locksDworker[myIdx]);
		while (!conditionsDWorker[myIdx]) {
			SDL_CondWait(condsDworker[myIdx], locksDworker[myIdx]);
		}
		if (funcsDWorker[myIdx] != NULL) {
			funcsDWorker[myIdx](paramsDWorker[myIdx], *(int*)ptr);
		}
		SDL_UnlockMutex(locksDworker[myIdx]);
		conditionsDWorker[myIdx] = false;
	}

	return 0;
}

int WorkerPriority[4] = {
	(int)SDL_THREAD_PRIORITY_TIME_CRITICAL,
	(int)SDL_THREAD_PRIORITY_HIGH,
	(int)SDL_THREAD_PRIORITY_NORMAL,
	(int)SDL_THREAD_PRIORITY_LOW
};

void SetDWorkerPriority(int priority) {
	SDL_SetThreadPriority((SDL_ThreadPriority)(WorkerPriority[priority%4]));
}

void SetDWorkerDataPtr(unsigned int dworkerID, void *dataPtr) {
	if (dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] == NULL)
		return;
	paramsDWorker[idx] = dataPtr;
}

void SetDWorkerFunction(unsigned int dworkerID, dworkerFunctionPointer workerFunction) {
	if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] == NULL)
		return;
	funcsDWorker[idx] = workerFunction;
}

unsigned int findFirstFreeDWorkerID() {
	if (countDWorker >= MaxDWorkersCount)
		return 0xFFFFFFFF;
    unsigned int newID = FirstFreeDWorkerID+1;
	if (newID < MaxDWorkersCount && threadsDWorker[newID] == NULL)
		return newID;
	for (unsigned int i=0; i<MaxDWorkersCount; i++) {
		if (threadsDWorker[i] == NULL)
			return i;
	}
	return 0xFFFFFFFF;
}


unsigned int CreateDWorker(dworkerFunctionPointer workerFunction, void *workerData) {
	unsigned int newWorkerIdx = 0;
	char nameWorker[12];
	if (countDWorker >= MaxDWorkersCount)
		return 0;
	newWorkerIdx = FirstFreeDWorkerID;
	sprintf_s(nameWorker, 11, "DWorker%d", newWorkerIdx);
	funcsDWorker[newWorkerIdx] = workerFunction;
	paramsDWorker[newWorkerIdx] = workerData;
	conditionsDWorker[newWorkerIdx] = false;
	locksDworker[newWorkerIdx] = SDL_CreateMutex();
	condsDworker[newWorkerIdx] = SDL_CreateCond();
	threadsDWorker[newWorkerIdx] = SDL_CreateThread(WorkerThreadFunction, nameWorker, &dataThreadsID[newWorkerIdx]);

	countDWorker++;
	FirstFreeDWorkerID = findFirstFreeDWorkerID();

	return newWorkerIdx+1;
}

void RunDWorker(unsigned int dworkerID, bool WaitIfBusy) {
	if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] == NULL)
		return;

	if (conditionsDWorker[idx]) {
		if (WaitIfBusy)
			WaitDWorker(dworkerID);
	}
	SDL_LockMutex(locksDworker[idx]);
	conditionsDWorker[idx] = true;
	SDL_CondSignal(condsDworker[idx]);
	SDL_UnlockMutex(locksDworker[idx]);
}

bool IsBusyDWorker(unsigned int dworkerID) {
	if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return false;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] == NULL)
		return false;
	return conditionsDWorker[idx];
}

void WaitDWorker(unsigned int dworkerID) {
	if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] == NULL)
		return;
	while(conditionsDWorker[idx]) { SDL_Delay(0); };
}

void DestroyDWorker(unsigned int dworkerID) {
	if (MaxDWorkersCount == 0 || dworkerID == 0 || dworkerID > MaxDWorkersCount)
		return;
	unsigned int idx = dworkerID - 1;
	if (threadsDWorker[idx] != NULL) {
		SDL_DetachThread(threadsDWorker[idx]);
		if (condsDworker[idx] != NULL) {
			SDL_DestroyCond(condsDworker[idx]);
			condsDworker[idx] = NULL;
		}
		if (locksDworker[idx] != NULL) {
			SDL_DestroyMutex(locksDworker[idx]);
			locksDworker[idx] = NULL;
		}
		countDWorker --;
		if (idx < FirstFreeDWorkerID)
			FirstFreeDWorkerID = idx;
		threadsDWorker[idx] = NULL;
	}
	funcsDWorker[idx] = NULL;
	paramsDWorker[idx] = NULL;
	conditionsDWorker[idx] = false;
}
