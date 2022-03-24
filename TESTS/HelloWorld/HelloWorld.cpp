/*  Dust Ultimate Game Library (DUGL) - (C) 2022 Fakhri Feki */
/*  Hello World Sample*/
/*  History : */
/*  23 march 2022 : first release */

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include "DUGL.h"


// screen resolution
//int ScrResH=640,ScrResV=480;
int ScrResH=800,ScrResV=600;
//int ScrResH=1024,ScrResV=768;
//int ScrResH=1280,ScrResV=1024;

//******************
// FONT
FONT F1;
// display parameters
bool SynchScreen=false;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
char RenderSynchBuff[SIZE_SYNCH_BUFF];
// render DWorker
unsigned int renderWorkerID = 0;
void RenderWorkerFunc(void *, int );
// fps counter
float avgFps, lastFps;
float accTime = 0.0f;
// Hello World DATA
const char *sHelloWorld = "Hello World!";
float TimeFullView = 3.0f;
DgSurf HelloWorldSurf16;
DgView RendSurfOrgView, HelloWorldView, RendSurfCurView;
bool directionGrowth = true;


int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
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

    // create rendering DWorker
    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);

    // load font
    if (!LoadFONT(&F1,"../Asset/FONT/hello.chr")) {
		printf("Error loading hello.chr\n"); exit(-1);
	}

    SetFONT(&F1);

    // create Hello World render Surf
    if (CreateSurf(&HelloWorldSurf16, WidthText(sHelloWorld)+20, FntHaut+2, 16)==0) {
		printf("no mem\n"); exit(-1);
    }
	SetOrgSurf(&HelloWorldSurf16, HelloWorldSurf16.ResH/2, HelloWorldSurf16.ResV/2);
	// render Hello World Surf
	DgSetCurSurf(&HelloWorldSurf16);
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

	// set screen rendering Surf origin on the middle of the screen
	SetOrgSurf(&RendSurf, RendSurf.ResH/2, RendSurf.ResV/2);
	SetOrgSurf(&RendFrontSurf, RendFrontSurf.ResH/2, RendFrontSurf.ResV/2);

	GetSurfRView(&RendSurf, &RendSurfOrgView); // save current View
	GetSurfRView(&HelloWorldSurf16, &HelloWorldView);
	HelloWorldView.OrgX = RendSurfOrgView.OrgX;
	HelloWorldView.OrgY = RendSurfOrgView.OrgY;

	// both rendering and front RenderSurf should be cleared to avoid any garbage at start-up
    DgSetCurSurf(&RendSurf);
    DgClear16(0); // clear by black
    DgSetCurSurf(&RendFrontSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    // init resize view of Hello world
	RendSurfCurView = HelloWorldView;
    // init synchro
    InitSynch(EventsLoopSynchBuff, NULL, 500); // speed of events scan per second, this will be too the max fps detectable
    InitSynch(RenderSynchBuff, NULL, 60); // screen frequency
	// main loop
	for (int j=0;;j++) {
		// synchronise event loop
		// WaitSynch should be used as Synch will cause scan events by milions or bilions time per sec !
		WaitSynch(EventsLoopSynchBuff, NULL);

		// time synching ignored for simplicity
		//accTime += SynchAverageTime(EventsLoopSynchBuff);

		// render one frame in separate DWorker (Thread)
		RunDWorker(renderWorkerID, false);

		// get key
		unsigned char keyCode;
		unsigned int keyFLAG;

		GetKey(&keyCode, &keyFLAG);
		switch (keyCode) {
			case KB_KEY_F5: // F5 vertical synch e/d
				SynchScreen=(SynchScreen)?false:true;
				break;
			case KB_KEY_F6: // F6 Todo
				break;
			case KB_KEY_F7 : // F7 Todo
				break;
		}

		// esc exit
		if (IsKeyDown(KB_KEY_ESC)) break;
		// ctrl + shift + tab  = jpeg screen shot
		if (IsKeyDown(KB_KEY_TAB) && (KbFLAG&KB_SHIFT_PR) && (KbFLAG&KB_CTRL_PR))
			SaveBMP16(&RendFrontSurf,(char*)"HelloWorld.bmp");

		DgCheckEvents();
	}

	DestroySurf(&HelloWorldSurf16);
	WaitDWorker(renderWorkerID);
	DestroyDWorker(renderWorkerID);
	renderWorkerID = 0;
    DgQuit();
    printf("See you!\n");
    return 0;
}

void RenderWorkerFunc(void *, int ) {

	static float minFps = 0.0f;
	static float maxFps = 0.0f;
	// synchronise
	if (SynchScreen)
		WaitSynch(RenderSynchBuff, NULL);
	else
		Synch(RenderSynchBuff,NULL);

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

	DgSetCurSurf(&RendSurf);

	SetSurfRView(&CurSurf, &RendSurfCurView);

	// clear all the Surf
	DgClear16(0x1e|0x380);

	// Blit Resized "Hello World !"
	ResizeViewSurf16(&HelloWorldSurf16, 0, 0);

	// restore original Screen View
	SetSurfRView(&CurSurf, &RendSurfOrgView);
	ClearText();
	char text[100];
	SetTextCol(0xffff);
	if (avgFps!=0.0 && minFps!=0.0 && maxFps!=0.0)
		sprintf(text,"MINFPS %i, MAXFPS %i, FPS %i\n",(int)(1.0/minFps),(int)(1.0/maxFps),(int)(1.0/avgFps));
	else
		sprintf(text,"FPS ???\n");
	OutText16Mode(text,AJ_RIGHT);

	ClearText();
	sprintf(text,"Esc Exit\nF5  Vertical Synch: %s\n", (SynchScreen)?"ON":"OFF");
	OutText16Mode(text,AJ_LEFT);

	// update Hello world Resize View
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
		if (RendSurfCurView.MaxX == HelloWorldSurf16.MaxX ||
			RendSurfCurView.MinX == HelloWorldSurf16.MinX ||
			RendSurfCurView.MaxY == HelloWorldSurf16.MaxY ||
			RendSurfCurView.MinY == HelloWorldSurf16.MinY) {

			directionGrowth = true;
		} else {
			RendSurfCurView.MaxX--;
			RendSurfCurView.MinX++;
			RendSurfCurView.MaxY--;
			RendSurfCurView.MinY++;
		}
	}

	DgUpdateWindow();
}
