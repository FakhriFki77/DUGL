/*  Dust Ultimate Game Library (DUGL) - (C) 2025 Fakhri Feki */
/*  Hello World Sample*/
/*  History : */
/*  23 march 2022 : first release */
/*  6 February 2023 : Few upgrades, first Debian version */
/*  2 March 2023: Detect/handle window close request */
/*  6 Aout 2023: Rework event handling and rendering loop and DWorker */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <DUGL.h>

// screen resolution
int ScrResH=640,ScrResV=480;
//int ScrResH=800,ScrResV=600;
//int ScrResH=1024,ScrResV=768;
//int ScrResH=1280,ScrResV=1024;

//******************
// FONT
FONT F1;
// functions
bool SynchScreen=false;
bool pauseHello=false;
bool exitApp=false;
bool takeScreenShot=false;
bool requestRenderMutex=false;
bool refreshWindow=false;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
char RenderSynchBuff[SIZE_SYNCH_BUFF];
// render DWorker
unsigned int renderWorkerID = 0;
void *renderMutex = NULL;
void RenderWorkerFunc(void *, int );
// fps counter
float avgFps, lastFps;
float accTime = 0.0f;
// Hello World DATA
const char *sHelloWorld = "Hello World!";
DgSurf *HelloWorldSurf16;
DgView RendSurfOrgView, HelloWorldView, RendSurfCurView;
bool directionGrowth = true;

int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
	}

    // create rendering DWorker
    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);
    renderMutex = CreateDMutex();

    // load font
    //if (!LoadFONT(&F1,"/home/darna/Downloads/DUGL-main/Asset/FONT/HELLOC.chr")) {
    if (!LoadFONT(&F1,"../Asset/FONT/HELLOC.chr")) {
		printf("Error loading HELLOC.chr\n"); exit(-1);
	}

    SetFONT(&F1);

    // create Hello World render Surf
    if (CreateSurf(&HelloWorldSurf16, WidthText(sHelloWorld)+20, FntHaut+2, 16)==0) {
		printf("no mem\n"); exit(-1);
    }
	SetOrgSurf(HelloWorldSurf16, HelloWorldSurf16->ResH/2, HelloWorldSurf16->ResV/2);
	// render Hello World Surf
	DgSetCurSurf(HelloWorldSurf16);
	DgClear16(0x1f<<11); // red
	ClearText(); // reset position of the text
	SetTextCol(0x3f<<5);  // green
	OutText16Mode(sHelloWorld, AJ_MID); // output on the middle of the view

    // init video mode
    if (!DgInitMainWindowX("Hello World", ScrResH, ScrResV, 16, -1, -1, false, false, false))
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

	GetSurfView(RendSurf, &RendSurfOrgView); // save current View
	GetSurfView(HelloWorldSurf16, &HelloWorldView);
	HelloWorldView.OrgX = RendSurfOrgView.OrgX;
	HelloWorldView.OrgY = RendSurfOrgView.OrgY;

	// RenderSurf should be cleared to avoid any garbage at start-up
    DgSetCurSurf(RendSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    // init resize view of Hello world
	RendSurfCurView = HelloWorldView;
    // init synchro
    InitSynch(EventsLoopSynchBuff, NULL, 500); // speed of events scan per second
    InitSynch(RenderSynchBuff, NULL, 60); // screen frequency
	// lunch render DWorker
	RunDWorker(renderWorkerID, false);

	// main loop
	for (int j=0;;j++) {
        if (Synch(EventsLoopSynchBuff, NULL) != 0) {

            // time synching ignored for simplicity
            //accTime += SynchAverageTime(EventsLoopSynchBuff);

            // get key
            unsigned char keyCode;
            unsigned int keyFLAG;

            GetKey(&keyCode, &keyFLAG);
            switch (keyCode) {
                case KB_KEY_ESC: // F5 vertical synch e/d
                    exitApp = true;
                    break;
                case KB_KEY_F5: // F5 vertical synch e/d
                    SynchScreen=!SynchScreen;
                    break;
                case KB_KEY_SPACE: // Space to pause
                    pauseHello=!pauseHello;
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
                break;
            }
            // need screen shot
            if (takeScreenShot) {
                // first try to lock renderMutex,
                // if fail, wait until rendering DWorker set requestRenderMutex to false, and execute a DelayMs(10) to free the renderMutex
                if(!TryLockDMutex(renderMutex)) {
                    for (requestRenderMutex = true;requestRenderMutex;) DelayMs(1);
                    LockDMutex(renderMutex);
                }
                SaveBMP16(RendSurf,(char*)"HelloWorld.bmp");
                takeScreenShot = false;
                UnlockDMutex(renderMutex);
            }

            DgCheckEvents();
        } else if (!refreshWindow && SynchScreen) {
            DelayMs(1);
        }

		if (refreshWindow) {
            // synchronise
            if (SynchScreen)
                WaitSynch(RenderSynchBuff, NULL);
            else
                Synch(RenderSynchBuff,NULL);

            DgUpdateWindow();
            refreshWindow = false;
		}
	}

	// wait render DWorker finish before exiting
	while(exitApp) {
        DelayMs(1);
	}
	DestroyDWorker(renderWorkerID);
	renderWorkerID = 0;
    DestroyDMutex(renderMutex);
    renderMutex = NULL;


	DestroySurf(HelloWorldSurf16);
    DgQuit();
    return 0;
}

void RenderWorkerFunc(void *, int ) {

	static float minFps = 0.0f;
	static float maxFps = 0.0f;
	unsigned int frames = 0;

	for(;!exitApp;) {

		// synch screen display
		avgFps=SynchAverageTime(RenderSynchBuff);
		lastFps=SynchLastTime(RenderSynchBuff);

		if (minFps == 0.0f && maxFps == 0.0f) {
			minFps = avgFps;
			maxFps = avgFps;
		} else {
			if (avgFps > minFps) minFps = avgFps;
			if (avgFps < maxFps) maxFps = avgFps;
		}

		// time synchro ignored for simplicity
		//float moveTime = accTime;
		//accTime = 0.0f;
		LockDMutex(renderMutex); // render lock

		DgSetCurSurf(RendSurf);

		// origin is the same, using ..Bounds for faster operation
		SetSurfViewBounds(&CurSurf, &RendSurfCurView);

		// clear all the Surf
		DgClear16(0x1e|0x380);

		// Blit Resized "Hello World !"
		ResizeViewSurf16(HelloWorldSurf16, 0, 0);

		// restore original Screen View
		SetSurfViewBounds(&CurSurf, &RendSurfOrgView);
		ClearText();
		#define SIZE_TEXT 512
		char text[SIZE_TEXT + 1];
		SetTextCol(0xffff);
		if (avgFps!=0.0 && minFps!=0.0 && maxFps!=0.0)
			OutText16ModeFormat(AJ_RIGHT, text, SIZE_TEXT, "DgTime %i, MAXFPS %i, FPS %i\n", DgTime,(int)(1.0/maxFps),(int)(1.0/avgFps));
		else
			OutText16Mode("FPS ???\n", AJ_RIGHT);

		OutText16ModeFormat(AJ_RIGHT, text, SIZE_TEXT, "Frames %u, AVG FPS %0.3f\n", frames,(float)(frames)/SynchAccTime(RenderSynchBuff));

		ClearText();
		OutText16ModeFormat(AJ_LEFT, text, SIZE_TEXT, "Esc    Exit\nF5     Vertical Synch: %s\nSpace  Pause: %s", (SynchScreen)?"ON":"OFF", (pauseHello)?"ON":"OFF");

		// update Hello world Resize View
		if (!pauseHello) {
			if (directionGrowth) {
				// detect overlap and reverse
				if (RendSurfCurView.MaxX == RendSurfOrgView.MaxX ||
					RendSurfCurView.MinX == RendSurfOrgView.MinX ||
					RendSurfCurView.MaxY == RendSurfOrgView.MaxY ||
					RendSurfCurView.MinY == RendSurfOrgView.MinY) {

					directionGrowth = false;
				} else {
					RendSurfCurView.MaxX++;
					RendSurfCurView.MinX--;
					RendSurfCurView.MaxY++;
					RendSurfCurView.MinY--;
				}
			} else {
				// detect overlap and reverse
				if (RendSurfCurView.MaxX == HelloWorldSurf16->MaxX ||
					RendSurfCurView.MinX == HelloWorldSurf16->MinX ||
					RendSurfCurView.MaxY == HelloWorldSurf16->MaxY ||
					RendSurfCurView.MinY == HelloWorldSurf16->MinY) {

					directionGrowth = true;
				} else {
					RendSurfCurView.MaxX--;
					RendSurfCurView.MinX++;
					RendSurfCurView.MaxY--;
					RendSurfCurView.MinY++;
				}
			}
		}
		UnlockDMutex(renderMutex);


		refreshWindow = true;
        // wait until last frame displayed or an exit requested
        while(refreshWindow && !exitApp && !requestRenderMutex) {
            if (SynchScreen) {
                DelayMs(1);
            }
        }

		if (requestRenderMutex) {
            requestRenderMutex = false;
            DelayMs(10); // wait for 10 ms to allow the renderMutex to be token by another thread or DWorker
		}
		frames++;
	}
	exitApp = false;
}
