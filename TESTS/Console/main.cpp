/*  Dust Ultimate Game Library (DUGL) - (C) 2025 Fakhri Feki */
/*  Console - graphic console like profiling of DSTRDic against std::map*/
/*  History : */
/*  27 march 2022 : first release */
/*  6 February 2023 : Few upgrades, first Debian version */
/*  2 March 2023: Detect/handle window close request */

#include <map>
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <DUGL.h>


// screen resolution
//int ScrResH=640,ScrResV=480;
int ScrResH=800,ScrResV=600;
//int ScrResH=1024,ScrResV=768;
//int ScrResH=1280,ScrResV=1024;

//******************
// FONT
FONT F1;
// functions
bool exitApp=false;
bool takeScreenShot=false;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
// render DWorker
unsigned int renderWorkerID = 0;
void RenderWorkerFunc(void *, int );


int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
	}

    // create rendering DWorker
    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);

    // load font
    if (!LoadFONT(&F1,"../Asset/FONT/HELLOC.chr")) {
		printf("Error loading HELLOC.chr\n"); exit(-1);
	}

    SetFONT(&F1);

    // init video mode
    if (!DgInitMainWindowX("Console", ScrResH, ScrResV, 16, -1, -1, false, false, false))
    {
        DgQuit();
        exit(-1);
    }

    // install timer and keyborad handler
    DgInstallTimer(500);

    if (DgTimerFreq == 0)
    {
       DgQuit();
       printf("Timer error\n");
       exit(-1);
    }
    if (!InstallKeyboard()) {
		DgQuit();
		printf("Keyboard error\n");
		exit(-1);
    }

	// set screen rendering Surf origin on the middle of the screen
	SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);

	// both rendering and front RenderSurf should be cleared to avoid any garbage at start-up
    DgSetCurSurf(RendSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    // init synchro
    InitSynch(EventsLoopSynchBuff, NULL, 250); // speed of events scan per second, this will be too the max fps detectable
    // render one frame in separate DWorker (Thread)
	RunDWorker(renderWorkerID, false);

	// main loop
	for (int j=0;;j++) {
		// synchronise event loop
		// WaitSynch should be used as Synch will cause scan events by milions or bilions time per sec !
		WaitSynch(EventsLoopSynchBuff, NULL);

		// get key
		unsigned char keyCode;
		unsigned int keyFLAG;

		DgCheckEvents();

		GetKey(&keyCode, &keyFLAG);
		switch (keyCode) {
			case KB_KEY_ESC: // F5 vertical synch e/d
				exitApp = true;
				break;
			case KB_KEY_F6: // F6 Todo
				break;
			case KB_KEY_F7 : // F7 Todo
				break;
			case KB_KEY_TAB: // ctrl + shift + TAB = screenshot
				takeScreenShot = ((keyFLAG&(KB_SHIFT_PR|KB_CTRL_PR)) > 0);
				break;
		}

        // detect close Request
        if (DgWindowRequestClose == 1) {
            // Set ExitApp to true to allow render DWorker to exit and finish
            exitApp = true;
        }

		// esc exit
        if (exitApp) {
        	// it's safer to wait the render DWorker to finish before exiting
        	if (IsBusyDWorker(renderWorkerID))
                WaitDWorker(renderWorkerID);
			break;
        }
		// need screen shot
		if (takeScreenShot) {
			SaveBMP16(RendSurf,(char*)"Console.bmp");
			takeScreenShot = false;
		}

	}

	DestroyDWorker(renderWorkerID);
	renderWorkerID = 0;
	UninstallKeyboard();
	DgUninstallTimer();
    DgQuit();
    return 0;
}

void RenderWorkerFunc(void *, int ) {

	static bool finished = false;
	#define SIZE_TEXT 127
	char text[SIZE_TEXT+1];

	// profiling finished ? exit
	if (finished)
		return;

	DgSetCurSurf(RendSurf);

	// clear all the Surf
	DgClear16(0);

	// put text cursor on the top
	ClearText();
	SetTextCol(0xffff);

	// std::map

    std::map<std::string,void*> mapData;
	char intstr[12];
    unsigned int countKeyVal = 1500000;
    unsigned int lastDgTime = 0;
    OutText16Format(text, SIZE_TEXT, "%i - Timing std::map\n", DgTime);
	DgUpdateWindow(); // required if we want to see the output OutText16 on the screen
    OutText16Format(text, SIZE_TEXT, "%i - Creating std::map Dictionnary\n", DgTime);
	DgUpdateWindow();
    lastDgTime = DgTime;
    for (unsigned int idic=0;idic<countKeyVal;idic++) {
        snprintf(intstr, 11, "%u", (rand()%countKeyVal)+123456);
		mapData.insert(std::make_pair(intstr, (void*)(idic+1+123456))); // inserting an integer instead of void *
    }
    OutText16Format(text, SIZE_TEXT, "%i - Inserting %0.2f milions (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
    lastDgTime = DgTime;
    int valptr = 0;
    for (int idic=0;idic<1000000;idic++) {
        snprintf(intstr, 11, "%u", (rand()%countKeyVal)+123456);
		auto fit = mapData.find(intstr);
		if (fit != mapData.end()) {
			valptr = (int)fit->second;
		}
    }
    OutText16Format(text, SIZE_TEXT, "%i - searching for random 1 milions (key, value) in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
    lastDgTime = DgTime;
	for (auto i = mapData.begin(); i != mapData.end(); i++) {
		valptr = (int)i->second;
	}
    OutText16Format(text, SIZE_TEXT, "%i - traversing all %0.2f milions elements  (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
	mapData.clear();

    // DSTRDic

    OutText16Format(text, SIZE_TEXT, "%i - Timing DSTRDic\n", DgTime);
	DgUpdateWindow();
	DSTRDic *strDIC =CreateDSTRDic(0, 18); // hash Table in 18bits or 256k elements without collision
	OutText16Format(text, SIZE_TEXT, "%i - Creating DSTRDic Dictionnary \n", DgTime);
	DgUpdateWindow();
    lastDgTime = DgTime;
	for (unsigned int idic=0;idic<countKeyVal;idic++) {
        snprintf(intstr, 11, "%u", (rand()%countKeyVal)+123456);
		InsertDSTRDic(strDIC, intstr, (void*)(idic+1+123456), false);
	}
    OutText16Format(text, SIZE_TEXT, "%i - Inserting %0.2f milions (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
    lastDgTime = DgTime;
    valptr = 0;
	for (unsigned int idic=0;idic<1000000;idic++) {
        snprintf(intstr, 11, "%u", (rand()%countKeyVal)+123456);
		valptr = (int)keyValueDSTRDic(strDIC, intstr);
	}
    OutText16Format(text, SIZE_TEXT, "%i - searching for random 1 milions (key, value) in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
    lastDgTime = DgTime;
    char *strv = NULL;
    void *datav = NULL;
    bool hasElem = false;
    for (hasElem = GetFirstValueDSTRDic(strDIC, &strv, &datav); hasElem; hasElem = GetNextValueDSTRDic(strDIC, &strv, &datav)) {
		valptr = (int)datav;
    }
    OutText16Format(text, SIZE_TEXT, "%i - traversing all %0.2f milions elements  (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DgUpdateWindow();
	DestroyDSTRDic(strDIC);

    // DFileBuffer

    DFileBuffer *dbuff = CreateDFileBuffer(0);
    char *readBuff = NULL;
    FILE *tmpFILE = NULL;
    int countBenchChunks = 4096*8-1; // 2gb
    if (dbuff != NULL) {
        readBuff = (char*)malloc(dbuff->m_sizeBuff);
        OutText16Format(text, SIZE_TEXT, "%i - Timing DFileBuffer\n", DgTime);
        OutText16Format(text, SIZE_TEXT, "%i - Creating temp file\n", DgTime);
        DgUpdateWindow();
        lastDgTime = DgTime;
        if ((tmpFILE = fopen("tmpBench.bin", "wb")) != NULL) {
            for (int i=0; i < countBenchChunks; i++) {
                fwrite(dbuff->m_buffRead, dbuff->m_sizeBuff, 1, tmpFILE);
            }
            fclose(tmpFILE);
            OutText16Format(text, SIZE_TEXT, "%i - creating tmpBench.bin in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
            DgUpdateWindow();

            OutText16Format(text, SIZE_TEXT, "%i - Bench DFileBuffer\n", DgTime);
            DgUpdateWindow();
            lastDgTime = DgTime;
            if (OpenFileDFileBuffer(dbuff, "tmpBench.bin", "rb")) {
                for (int i=0; i < countBenchChunks; i++) {
                    if (GetBytesDFileBuffer(dbuff, readBuff, dbuff->m_sizeBuff) != dbuff->m_sizeBuff) {
                        OutText16Format(text, SIZE_TEXT, "%i - Error DFileBuffer::GetBytes\n", DgTime);
                        DgUpdateWindow();
                    }
                }
                CloseFileDFileBuffer(dbuff);
                OutText16Format(text, SIZE_TEXT, "%i - DFileBuffer reading tmpBench.bin in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
                DgUpdateWindow();
            }

            remove("tmpBench.bin");
            OutText16Format(text, SIZE_TEXT, "%i - Bench fread\n", DgTime);
            OutText16Format(text, SIZE_TEXT, "%i - Creating temp file\n", DgTime);
            DgUpdateWindow();
            lastDgTime = DgTime;
            if ((tmpFILE = fopen("tmpBench.bin", "wb")) != NULL) {
                for (int i=0; i < countBenchChunks; i++) {
                    fwrite(dbuff->m_buffRead, dbuff->m_sizeBuff, 1, tmpFILE);
                }
                fclose(tmpFILE);
            }
            OutText16Format(text, SIZE_TEXT, "%i - creating tmpBench.bin in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
            DgUpdateWindow();

            lastDgTime = DgTime;
            if ((tmpFILE = fopen("tmpBench.bin", "rb")) != NULL) {
                for (int i=0; i < countBenchChunks; i++) {
                    if (fread(readBuff, 1, dbuff->m_sizeBuff, tmpFILE) != dbuff->m_sizeBuff) {
                        OutText16Format(text, SIZE_TEXT, "%i - Error fread\n", DgTime);
                        DgUpdateWindow();
                    }
                }
                fclose(tmpFILE);
                OutText16Format(text, SIZE_TEXT, "%i - fread reading tmpBench.bin in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
                DgUpdateWindow();
            }

            remove("tmpBench.bin");
        } else {
            OutText16Format(text, SIZE_TEXT, "%i - Failed create tmpBench.bin\n", DgTime);
            DgUpdateWindow();
        }
        DgUpdateWindow();
        free(readBuff);
    }

    OutText16("\nconsole sample finished,\nEsc to exit\n");
    DgUpdateWindow();
    finished = true;
    for(;!exitApp;) DelayMs(10);
}
