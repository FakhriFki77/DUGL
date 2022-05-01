/*  Dust Ultimate Game Library (DUGL) - (C) 2022 Fakhri Feki */
/*  Forest Sample*/
/*  Description: */
/*  Infinite progressing forest with fog effect, smoothing - ported/improved from the fog16 sample of the DOS version */
/*  History : */
/*  19 april 2022 : first release */

#include <stdio.h>
#include <stdlib.h>
#include "DUGL.h"

// screen resolution
//int ScrResH=640,ScrResV=480;
//int ScrResH=800,ScrResV=600;
int ScrResH=1024,ScrResV=768;
//int ScrResH=1280,ScrResV=1024;

// Poly16 point structure
typedef struct {
  int x,y,z;  // screen pos
  int xt,yt;  // texture position
  //int lightRGB; // lightening, RGBA color ... no need in this demo
} PolyPt;

// tree point
PolyPt TreePts[4] =
   { { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 },
     { 0, 0, 0, 0, 0 }, { 0, 0, 0, 0, 0 }
   };
int ListPtTree[] =
   { 4, (int)&TreePts[0], (int)&TreePts[1],
        (int)&TreePts[2], (int)&TreePts[3] };

// Forest Scene parameters ///////////////
// trees parameters
#define ROAD_WIDTH  180 // width of the road on the middle
#define FOREST_SPACE 300
#define NUMBER_TREES 10000 //

int TreeYPos=-130; // height of the camera from the ground
// tree sorting data
float TreesSpeed=1500.0f;//150.0f;//800.0; // speed of the progress of the trees
// fog parameter
#define FOG_COLOR RGB16(128,128,128) // grey
float fogDistance=5000.0;

// stored DATA and structs

// ground
typedef struct {
  int x, y;
  float z;
  int width, height;
  int tex; // 0 ground 1, 1 ground 2
} Ground;

Ground TGround[256];

// Road
typedef struct {
  float z;
  int ashpaltIdx;
} Road;

Road TRoad[16];

// trees
typedef struct {
  int x, y;
  float z;
  int width, height;
  int rev;
  int imgIdx;
} Tree;

Tree TTrees[NUMBER_TREES];
int idxLAstTree=0; // defaul at startup
// render Surf
unsigned int smoothWorkerID = 0;

int smoothSurfPlusX = 40, smoothSurfPlusY = 40;
DgSurf *blurSurf16;
DgSurf *srcBlurSurf16;

// smooth half of srcBlurSurf16
void SmoothFirstHalf() {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV/2);
}
// smooth second half of srcBlurSurf16 in another DWorker
void SmoothWorker(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/2+1, srcBlurSurf16->ResV-1);
}

// texture Surf
DgSurf *TreeSurf16=NULL,*Tree2Surf16=NULL,*Ground1Surf16=NULL,*BackSky16=NULL;
DgSurf *AsphaltSurf16[3]= { NULL, NULL, NULL };

//******************
// FONT
FONT F1;
// mouse View
DgView MsV;
// display parameters
bool SynchScreen=false,SmoothDisplay=false,EnableFog=true;
bool ExitApp = false;
bool PauseMove = false;
bool takeScreenShot=false;
bool requestRenderMutex=false;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
char RenderSynchBuff[SIZE_SYNCH_BUFF];
unsigned int LastDgTime;
// render DWorker
unsigned int renderWorkerID = 0;
void *renderMutex = NULL;
void *dataMutex = NULL;
void RenderWorkerFunc(void *, int );

float accTime = 0.0f;

//******* utils functions ****************************
void ForestInit();
void ForestProgress();
int GetFog(float Z); // compute the fog color
// generate the quad polygone of a tree,
void PtsRectGenerate(PolyPt *Pts4,DgSurf *S16,
        int xRect, int yRect,int wRect,int hRect, int rev);
void GroundRectRender(Ground *grnd);
// event resize
DgView orgView,treeView;
bool oldPauseMove = false;
void ForestWinPreResize(int , int ) {
    oldPauseMove = PauseMove;
    PauseMove = true;
}
void ForestWinResize(int , int ) {
	SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);
    GetSurfView(RendSurf, &orgView);
    GetSurfView(RendSurf, &treeView);
	ScrResH=RendSurf->ResH;
	ScrResV=RendSurf->ResV;
	// restore old PauseMove
    PauseMove = oldPauseMove;
    LastDgTime = DgTime;
    accTime = 0.0f;
}

int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
	}

    // load GFX
    if (LoadPNG16(&Ground1Surf16,"../Asset/PICS/groundhd.png")==0) {
		printf("error loading groundhd.gif\n"); exit(-1);
    }
    if (LoadPNG16(&AsphaltSurf16[0],"../Asset/PICS/asphalt1.png")==0) {
		printf("error loading asphalt1.png\n"); exit(-1);
    }
    if (LoadPNG16(&AsphaltSurf16[1],"../Asset/PICS/asphalt2.png")==0) {
		printf("error loading asphalt2.png\n"); exit(-1);
    }
    if (LoadPNG16(&AsphaltSurf16[2],"../Asset/PICS/asphalt3.png")==0) {
		printf("error loading asphalt2.png\n"); exit(-1);
    }
    if (LoadGIF16(&Tree2Surf16,"../Asset/PICS/tree2.gif")==0) {
		printf("error loading tree.gif\n"); exit(-1);
    }

    if (LoadPNG16(&BackSky16, "../Asset/PICS/Background.png" /*"backsky.png"*/) == 0) {
		printf("error loading Background.png\n"); exit(-1);
    }
    if (LoadGIF16(&TreeSurf16,"../Asset/PICS/tree.gif")==0) {
		printf("error loading tree.gif\n"); exit(-1);
    }

    // load font
    if (!LoadFONT(&F1,"../Asset/FONT/helloc.chr")) {
		printf("Error loading hello.chr\n"); exit(-1);
	}
    SetFONT(&F1);

    // create RAM render Surf
    if (CreateSurf(&blurSurf16, ScrResH+smoothSurfPlusX, ScrResV+smoothSurfPlusY, 16)==0) {
		printf("no mem\n"); exit(-1);
    }

    if (CreateSurf(&srcBlurSurf16, ScrResH+smoothSurfPlusX, ScrResV+smoothSurfPlusY, 16)==0) {
		printf("no mem\n"); exit(-1);
    }

    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);
    smoothWorkerID = CreateDWorker(SmoothWorker, nullptr);

    renderMutex = CreateDMutex();
    dataMutex = CreateDMutex();
    if (renderWorkerID == 0 || smoothWorkerID == 0 || renderMutex == NULL || dataMutex == NULL) {
		printf("DWorker threading error\n"); exit(-1);
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
		exit(-1);
    }

    // init video mode
    if (!DgInitMainWindowX("Forest", ScrResH, ScrResV, 16, -1, -1, false, false, true))
    {
        DgQuit();
        exit(-1);
    }
    DgSetWindowIcone(Tree2Surf16);
    DgSetMainWindowMinSize(128, 64);
	DgSetMainWindowResizeCallBack(ForestWinPreResize, ForestWinResize, renderMutex, &requestRenderMutex);

	// set Surf origin on the middle of the screen

    SetOrgSurf(BackSky16,BackSky16->ResH/2,BackSky16->ResV/2);
	SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);
    GetSurfView(RendSurf, &orgView);
    GetSurfView(RendSurf, &treeView);

    DgSetCurSurf(RendSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    ForestInit();

    // init synchro
    InitSynch(EventsLoopSynchBuff, NULL, 250);
    InitSynch(RenderSynchBuff, NULL, 60);
    // lunch rendering loop
	RunDWorker(renderWorkerID, false);
	LastDgTime = DgTime;
	float revTimerFreq = 1.0f/(float)(DgTimerFreq);

	//DgQuit();
	// main loop
	for (int j=0;;j++) {
		// synchronise event loop
		WaitSynch(EventsLoopSynchBuff, NULL);

		if (DgTime != LastDgTime) {
            accTime += (float)(DgTime-LastDgTime)*revTimerFreq; //SynchAverageTime(EventsLoopSynchBuff);
            LastDgTime = DgTime;
            ForestProgress();
		}

		// get key
		unsigned char keyCode;
		unsigned int keyFLAG;

		GetKey(&keyCode, &keyFLAG);
		switch (keyCode) {
			case KB_KEY_F5: // F5 vertical synch e/d
				SynchScreen=!SynchScreen;
				break;
			case KB_KEY_F6: // F6 blur
				SmoothDisplay=!SmoothDisplay;
				break;
			case KB_KEY_F7 : // F7 fog
				EnableFog=!EnableFog;
				break;
			case KB_KEY_SPACE : // F7 fog
				PauseMove=!PauseMove;
				break;
            case KB_KEY_ESC:
                ExitApp = true;
                break;
			case KB_KEY_TAB: // ctrl + shift + TAB = screenshot
				takeScreenShot = ((keyFLAG&(KB_SHIFT_PR|KB_CTRL_PR)) > 0);
				break;
		}

		// esc exit
		if (ExitApp) break;
		if (takeScreenShot) {
            // first try to lock renderMutex,
            // if fail, wait until rendering DWorker set requestRenderMutex to false, and execute a DelayMs(10) to free the renderMutex
            if(!TryLockDMutex(renderMutex)) {
                for (requestRenderMutex = true;requestRenderMutex;) DelayMs(1);
                LockDMutex(renderMutex);
            }
			SaveBMP16(RendSurf,(char*)"forest.bmp");
			takeScreenShot = false;
			UnlockDMutex(renderMutex);
		}

		DgCheckEvents();
	}

	WaitDWorker(renderWorkerID); // wait render DWorker finish
	DestroyDWorker(renderWorkerID);
	renderWorkerID = 0;
	DestroyDWorker(smoothWorkerID);
	smoothWorkerID = 0;
    DestroyDMutex(renderMutex);
    renderMutex = NULL;
    DestroyDMutex(dataMutex);
    dataMutex = NULL;

    UninstallKeyboard();
    DgUninstallTimer();

    DestroySurf(TreeSurf16);
    DestroySurf(Tree2Surf16);
    DestroySurf(Ground1Surf16);
    DestroySurf(BackSky16);
    DestroySurf(AsphaltSurf16[0]);
    DestroySurf(AsphaltSurf16[1]);
    DestroySurf(AsphaltSurf16[2]);

    TreeSurf16=NULL;
    Tree2Surf16=NULL;
    Ground1Surf16=NULL;
    BackSky16=NULL;

    DgQuit();

    return 0;
}

void ForestInit() {
    // Init Table of ground
    for (int i=0;i<256;i++) {
		TGround[i].x=-4096+(i&0xf)*512; TGround[i].y=TreeYPos;
		TGround[i].z=512.0*(float)(i/16)+100.0;
		TGround[i].width=512; TGround[i].height=512;
    }

    // init road
    for (int i=0;i<16;i++) {
		TRoad[i].z=512.0*(float)(i);
		TRoad[i].ashpaltIdx = rand()%3;
    }

    // Init Table of Trees

    float zTree=8191.0;
    for (int i=0;i<NUMBER_TREES;i++) {
		if ((rand()%2)==1)
            TTrees[i].x=(rand()%(2048-200)+FOREST_SPACE/2);
        else
            TTrees[i].x=-(rand()%(2048-200)+FOREST_SPACE/2);

		TTrees[i].y=TreeYPos;
		TTrees[i].z=zTree;
		TTrees[i].width=rand()%50+30;
		TTrees[i].height=rand()%100+50;
		TTrees[i].rev=rand()&1;
		TTrees[i].imgIdx=rand()&1;
		zTree-=8100.0/(float)(NUMBER_TREES);
    }
}

void ForestProgress() {
    LockDMutex(dataMutex);

    if (PauseMove || accTime <= 0.0f) {
        accTime = 0.0f;
        UnlockDMutex(dataMutex);
        return;
    }
    float moveTime = accTime;
    accTime = 0.0f;
    float zstep = TreesSpeed*moveTime;

    // ground
    for (int i=0;i<256;i++) {
        TGround[i].z-=zstep;
        if (TGround[i].z<-256.0) {
            TGround[i].z+=8192.0;
        }
	}

    // road
    for (int i=0;i<16;i++) {
        TRoad[i].z-=zstep;
        if (TRoad[i].z<-256.0) {
            TRoad[i].z+=8192.0;
            TRoad[i].ashpaltIdx = rand()%3;
        }
    }

    // trees

    int nextidxLAstTree=idxLAstTree;
    bool treeToBack=false;

    for (int i=0;i<NUMBER_TREES;i++) {

        // curid is the starting point of the ring buffer list of the tree
        int curid=(idxLAstTree+i)%NUMBER_TREES; // defaul at startup

        TTrees[curid].z-=zstep;

        // if the tree is back the camera then push it to the end of the list
        if (TTrees[curid].z<=20.0) {
            if ((rand()%2)==1)
                TTrees[curid].x=(rand()%(2048-200)+FOREST_SPACE/2);
            else
                TTrees[curid].x=-(rand()%(2048-200)+FOREST_SPACE/2);
            TTrees[curid].y=TreeYPos;
            TTrees[curid].z=8191.0;
            TTrees[curid].width=rand()%50+30;
            TTrees[curid].height=rand()%100+50;
            TTrees[curid].rev=rand()&1;
            if (!treeToBack) { nextidxLAstTree=curid; treeToBack=true; }
            continue;
        }
    }

    idxLAstTree=nextidxLAstTree;

    UnlockDMutex(dataMutex);
}


int GetFog(float Z) {
	// blending for POLY16_MASK_TEXT_BLND and POLY16_TEXT_BLND
	// blend between 0 .. 31 passed on the byte 4 of the color parameter
	// Poly16 color param (5bits : blue, 6bits green, 5bits blue, 8bits reserved for 24bpp, 5bits blend value, 3 bits reserved)
	int ColorBlnd=FOG_COLOR;
	if (Z>=fogDistance)
		ColorBlnd|=31<<24;
	else
		ColorBlnd|=((int)(Z/(fogDistance/32.0)-1.0))<<24;
	return ColorBlnd;
}

void GroundRectRender(Ground *grnd) {
    int ColorBlnd=GetFog(grnd->z+(float)(grnd->height/2));
    // render far ground
    if (grnd->z>20.0+(grnd->height*3)) {
        TreePts[0].z=(int)grnd->z;
        TreePts[0].x=(grnd->x*ScrResH)/TreePts[0].z;
        TreePts[0].y=(grnd->y*ScrResV)/TreePts[0].z;

        TreePts[1].z=(int)grnd->z;
        TreePts[1].x=((grnd->x+grnd->width)*ScrResH)/TreePts[1].z;
        TreePts[1].y=(grnd->y*ScrResV)/TreePts[1].z;

        TreePts[2].z=(int)grnd->z+grnd->height;
        TreePts[2].x=((grnd->x+grnd->width)*ScrResH)/TreePts[2].z;
        TreePts[2].y=(grnd->y*ScrResV)/TreePts[2].z;

        TreePts[3].z=(int)grnd->z+grnd->height;
        TreePts[3].x=(grnd->x*ScrResH)/TreePts[3].z;
        TreePts[3].y=(grnd->y*ScrResV)/TreePts[3].z;

        TreePts[0].xt=Ground1Surf16->MaxX; TreePts[0].yt=Ground1Surf16->MinY;
        TreePts[1].xt=Ground1Surf16->MinX; TreePts[1].yt=Ground1Surf16->MinY;
        TreePts[2].xt=Ground1Surf16->MinX; TreePts[2].yt=Ground1Surf16->MaxY;
        TreePts[3].xt=Ground1Surf16->MaxX; TreePts[3].yt=Ground1Surf16->MaxY;

        if (EnableFog)
            Poly16(ListPtTree, NULL, POLY16_TEXT_BLND, ColorBlnd);
        else
            Poly16(ListPtTree, NULL, POLY16_TEXT, 0);
    } else {
        // render near grounds by splitting to 4 to avoid ugly not perspective corrected texturing
        float heightStep = (float)(grnd->height)/4.0;
        float tyStep = (float)(Ground1Surf16->MaxY-Ground1Surf16->MinY)/4.0f;
        for (int i=0;i<4;i++) {
            TreePts[0].z=(int)grnd->z+(int)((float)(i)*heightStep);
            if (TreePts[0].z > 1.0f) {
                TreePts[0].x=(grnd->x*ScrResH)/TreePts[0].z;
                TreePts[0].y=(grnd->y*ScrResV)/TreePts[0].z;

                TreePts[1].z= TreePts[0].z;
                TreePts[1].x=((grnd->x+grnd->width)*ScrResH)/TreePts[1].z;
                TreePts[1].y=(grnd->y*ScrResV)/TreePts[1].z;

                TreePts[2].z=(int)grnd->z+(int)((float)(i+1)*heightStep);
                TreePts[2].x=((grnd->x+grnd->width)*ScrResH)/TreePts[2].z;
                TreePts[2].y=(grnd->y*ScrResV)/TreePts[2].z;

                TreePts[3].z=TreePts[2].z;
                TreePts[3].x=(grnd->x*ScrResH)/TreePts[3].z;
                TreePts[3].y=(grnd->y*ScrResV)/TreePts[3].z;

                TreePts[0].xt=Ground1Surf16->MaxX; TreePts[0].yt=Ground1Surf16->MinY+(int)((float)(i)*tyStep);
                TreePts[1].xt=Ground1Surf16->MinX; TreePts[1].yt=TreePts[0].yt;
                TreePts[2].xt=Ground1Surf16->MinX; TreePts[2].yt=Ground1Surf16->MinY+(int)((float)(i+1)*tyStep);
                TreePts[3].xt=Ground1Surf16->MaxX; TreePts[3].yt=TreePts[2].yt;

                if (EnableFog)
                    Poly16(ListPtTree, NULL, POLY16_TEXT_BLND, ColorBlnd);
                else
                    Poly16(ListPtTree, NULL, POLY16_TEXT, 0);
            }
        }
    }

}

void RoadRectRender(Road *rd) {
    int ColorBlnd=(rd->z > 20.0) ? GetFog(rd->z) : 0;
    DgSurf *myAspahlt = AsphaltSurf16[rd->ashpaltIdx];
    DgSetSrcSurf(myAspahlt);
    // render far ground
    if (rd->z>20.0f+(512.0f*3.0f)) {
        TreePts[0].z=(int)rd->z;
        TreePts[0].x=-((ROAD_WIDTH/2)*ScrResH)/TreePts[0].z;
        TreePts[0].y=(TreeYPos*ScrResV)/TreePts[0].z;

        TreePts[1].z=(int)rd->z;
        TreePts[1].x=((ROAD_WIDTH/2)*ScrResH)/TreePts[1].z;
        TreePts[1].y=(TreeYPos*ScrResV)/TreePts[1].z;

        TreePts[2].z=(int)rd->z+512;
        TreePts[2].x=((ROAD_WIDTH/2)*ScrResH)/TreePts[2].z;
        TreePts[2].y=(TreeYPos*ScrResV)/TreePts[2].z;

        TreePts[3].z=(int)rd->z+512;
        TreePts[3].x=-((ROAD_WIDTH/2)*ScrResH)/TreePts[3].z;
        TreePts[3].y=(TreeYPos*ScrResV)/TreePts[3].z;

        TreePts[0].xt=myAspahlt->MaxX; TreePts[0].yt=myAspahlt->MinY;
        TreePts[1].xt=myAspahlt->MinX; TreePts[1].yt=myAspahlt->MinY;
        TreePts[2].xt=myAspahlt->MinX; TreePts[2].yt=myAspahlt->MaxY;
        TreePts[3].xt=myAspahlt->MaxX; TreePts[3].yt=myAspahlt->MaxY;

        if (EnableFog)
            Poly16(ListPtTree, NULL, POLY16_MASK_TEXT_BLND, ColorBlnd);
        else
            Poly16(ListPtTree, NULL, POLY16_MASK_TEXT, 0);
    } else {
        // render near road rect by splitting to 4 to avoid ugly not perspective corrected texturing
        float heightStep = 512.0f/4.0f;
        float tyStep = (float)(myAspahlt->MaxY-myAspahlt->MinY)/4.0f;
        for (int i=0;i<4;i++) {
            TreePts[0].z=(int)rd->z+(int)((float)(i)*heightStep);
            if (TreePts[0].z > 1.0f) {
                TreePts[0].x=-((ROAD_WIDTH/2)*ScrResH)/TreePts[0].z;
                TreePts[0].y=(TreeYPos*ScrResV)/TreePts[0].z;

                TreePts[1].z= TreePts[0].z;
                TreePts[1].x=((ROAD_WIDTH/2)*ScrResH)/TreePts[1].z;
                TreePts[1].y=(TreeYPos*ScrResV)/TreePts[1].z;

                TreePts[2].z=(int)rd->z+(int)((float)(i+1)*heightStep);
                TreePts[2].x=((ROAD_WIDTH/2)*ScrResH)/TreePts[2].z;
                TreePts[2].y=(TreeYPos*ScrResV)/TreePts[2].z;

                TreePts[3].z=TreePts[2].z;
                TreePts[3].x=-((ROAD_WIDTH/2)*ScrResH)/TreePts[3].z;
                TreePts[3].y=(TreeYPos*ScrResV)/TreePts[3].z;

                TreePts[0].xt=myAspahlt->MaxX; TreePts[0].yt=myAspahlt->MinY+(int)((float)(i)*tyStep);
                TreePts[1].xt=myAspahlt->MinX; TreePts[1].yt=TreePts[0].yt;
                TreePts[2].xt=myAspahlt->MinX; TreePts[2].yt=myAspahlt->MinY+(int)((float)(i+1)*tyStep);
                TreePts[3].xt=myAspahlt->MaxX; TreePts[3].yt=TreePts[2].yt;

                if (EnableFog)
                    Poly16(ListPtTree, NULL, POLY16_MASK_TEXT_BLND, ColorBlnd);
                else
                    Poly16(ListPtTree, NULL, POLY16_MASK_TEXT, 0);
            }
        }
    }

}

// poly Gen
void PtsRectGenerate(DgSurf *S16, int xRect,
      int yRect,int x2Rect,int y2Rect, int rev) {

	TreePts[0].x=xRect; TreePts[0].y=yRect;
	TreePts[1].x=x2Rect; TreePts[1].y=yRect;
	TreePts[2].x=x2Rect; TreePts[2].y=y2Rect;//*2/3);
	TreePts[3].x=xRect; TreePts[3].y=y2Rect;
	if (rev) {
		TreePts[0].xt=S16->MaxX; TreePts[0].yt=S16->MinY;
		TreePts[1].xt=S16->MinX; TreePts[1].yt=S16->MinY;
		TreePts[2].xt=S16->MinX; TreePts[2].yt=S16->MaxY;
		TreePts[3].xt=S16->MaxX; TreePts[3].yt=S16->MaxY;
	}
	else {
		TreePts[0].xt=S16->MinX; TreePts[0].yt=S16->MinY;
		TreePts[1].xt=S16->MaxX; TreePts[1].yt=S16->MinY;
		TreePts[2].xt=S16->MaxX; TreePts[2].yt=S16->MaxY;
		TreePts[3].xt=S16->MinX; TreePts[3].yt=S16->MaxY;
	}
}



void RenderWorkerFunc(void *, int ) {
    float avgFps;
    bool FullView = false;
    int frames = 0;

    for(;!ExitApp;) {
        // synchronise
        if (SynchScreen)
            WaitSynch(RenderSynchBuff, NULL);
        else
            Synch(RenderSynchBuff,NULL);

        // synch screen display
        avgFps=SynchAverageTime(RenderSynchBuff);

		LockDMutex(renderMutex); // render lock

        DgSetCurSurf(RendSurf);

        // set view to half
        int oldDMinY = CurSurf.MinY;
        int oldSMinY = BackSky16->MinY;
        CurSurf.MinY = -CurSurf.ResV / 8;
        BackSky16->MinY = -BackSky16->ResV / 8;
        //DgClear16(0);

        // render ///////////////////
        if (EnableFog)
            BlndResizeViewSurf16(BackSky16, 0, 0, FOG_COLOR | (25<<24));
        else
            ResizeViewSurf16(BackSky16, 0, 0);
        CurSurf.MinY = oldDMinY;
        BackSky16->MinY = oldSMinY;

        DgSetSrcSurf(Ground1Surf16);
        if (!FullView) {
            SetSurfViewBounds(&CurSurf, &orgView);
            FullView = true;
        }

        LockDMutex(dataMutex);

        // ground rendering
        DgSetSrcSurf(Ground1Surf16);
        for (int i=0;i<256;i++) {
            GroundRectRender(&TGround[i]);
        }
        // road rendering
        for (int i=0;i<16;i++) {
            RoadRectRender(&TRoad[i]);
        }

        // trees rendering

        for (int i=0;i<NUMBER_TREES;i++) {

            // curid is the starting point of the ring buffer list of the tree
            int curid=(idxLAstTree+i)%NUMBER_TREES; // defaul at startup

            // compute tree rectangle parameters
            int treeX=(TTrees[curid].x*ScrResH)/(int)(TTrees[curid].z),
                treeY=(TTrees[curid].y*ScrResV)/(int)(TTrees[curid].z),
                treeWidth=(TTrees[curid].width*ScrResH)/(int)(TTrees[curid].z),
                treeHeight=(TTrees[curid].height*ScrResV)/(int)(TTrees[curid].z),
                treeX2 = treeX + treeWidth,
                treeY2 = treeY + treeHeight;

                treeX -= treeWidth / 2;
                treeX2 -= treeWidth / 2;

            if (!FullView) {
                SetSurfViewBounds(&CurSurf, &orgView);
                FullView = true;
            }


            // completely out of the view ?
            if (!(treeX > orgView.MaxX || treeY > orgView.MaxY || treeX2 < orgView.MinX || treeY2 < orgView.MinY)) {
                // fog
                int ColorBlnd=GetFog(TTrees[curid].z);
                // decrease tree position
                DgSurf *imgTree = (TTrees[curid].imgIdx == 0) ? TreeSurf16 : Tree2Surf16;
                // clipped ? use Poly16
                if (treeX < orgView.MinX || treeY < orgView.MinY || treeX2 > orgView.MaxX || treeY2 > orgView.MaxY) {

                    if (!FullView) {
                        SetSurfViewBounds(&CurSurf, &orgView);
                        FullView = true;
                    }

                    // generate the quad of the tree
                    PtsRectGenerate(imgTree,
                      treeX, treeY, treeX2, treeY2,  TTrees[curid].rev);

                    if (EnableFog)
                        Poly16(ListPtTree, imgTree, POLY16_MASK_TEXT_BLND, ColorBlnd);
                    else
                        Poly16(ListPtTree, imgTree, POLY16_MASK_TEXT, ColorBlnd);

                } else {
                    treeView.MinX = treeX;
                    treeView.MinY = treeY;
                    treeView.MaxX = treeX2;
                    treeView.MaxY = treeY2;
                    SetSurfViewBounds(&CurSurf, &treeView);
                    FullView = false;
                    if (EnableFog)
                        MaskBlndResizeViewSurf16(imgTree, TTrees[curid].rev, 0, ColorBlnd);
                    else
                        MaskResizeViewSurf16(imgTree, TTrees[curid].rev, 0);
                }
            }
        }

        UnlockDMutex(dataMutex);

        if (!FullView) {
            SetSurfViewBounds(&CurSurf, &orgView);
            FullView = true;
        }

        if (SmoothDisplay) {

            DgSetCurSurf(srcBlurSurf16);
            ResizeViewSurf16(RendSurf, 0, 0);
            //BlurSurf16(blurSurf16,srcBlurSurf16); // single core
			// dual core smoothing
			RunDWorker(smoothWorkerID, false); // lunch DWorker to smooth second half
			SmoothFirstHalf(); // in parallel to first DWorker - smooth first half
			WaitDWorker(smoothWorkerID); // wait the thread to finish

            DgSetCurSurf(RendSurf);
            ResizeViewSurf16(blurSurf16, 0, 0);
        }

        char text[100];

        ClearText();
        SetTextCol(0xffff);
        if (avgFps!=0.0)
            OutText16ModeFormat(AJ_RIGHT,text,100,"FPS %i\n",(int)(1.0/avgFps));
        else
            OutText16Mode("FPS ???\n",AJ_RIGHT);
        OutText16ModeFormat(AJ_RIGHT,text,100,"Trees Count %i",NUMBER_TREES);
        ClearText();
        OutText16ModeFormat(AJ_LEFT,text,100,"Esc   Exit\nF5    Vertical Synch: %s\nF6    Smooth: %s\nF7    Fog: %s\nSpace Pause: %s\n", (SynchScreen)?"ON":"OFF", (SmoothDisplay)?"ON":"OFF", (EnableFog)? "ON":"OFF", (PauseMove)? "ON":"OFF");

        DgUpdateWindow();

		UnlockDMutex(renderMutex); // render unlock
		if (requestRenderMutex) {
            requestRenderMutex = false;
            DelayMs(10); // wait for 10 ms to allow the renderMutex to be token by another thread or DWorker
		}
    }

}
