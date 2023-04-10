/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */
/*  Shadow Sample*/
/*  Simple/unoptimized 3d engine, with z-sorting polygones, moving camera, shadow casting on ground, 3d obj loader .. */
/*  History : */
/*  10 April 2023 : first release */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <DUGL.h>
#include "D3DLoader.h"
#include "DCamera3D.h"

// screen resolution
//int ScrResH=640,ScrResV=480;
int ScrResH=800,ScrResV=600;
//int ScrResH=1024,ScrResV=768;
//int ScrResH=1280,ScrResV=1024;

// 3d DATA

DCamera3D camera;
float RotSpeed=80.0f;
float MoveSpeed = 100.0;

DVEC4 *lightDir = nullptr;
DVEC4 *lightPos = nullptr;
DVEC4 *lightVecPos = nullptr;
DVEC4 *plusVEC = nullptr;
DMatrix4 *matAnimLight = NULL;
float speedRotLightX = 0.0f;
float speedRotLightY = 20.0f;
float speedRotLightZ = 0.0f;

DAABBox *pAABBox = NULL;
DAAMinBBox *pAAMinBBox = NULL;

int MAX_VERTICES_COUNT = 500000;
int MAX_INDEXES_SIZE = 4000000;
int MAX_FACE_INDEXES = 12;
int MAX_FACES_COUNT = 1000000;

int countVertices = 0;
int countUV = 0;
int countNormals = 0;
DMatrix4 *matView = nullptr;
DVEC4 *varray = nullptr;
DVEC4 *vnarray = nullptr;
DVEC2 *vuvarray = nullptr;
DVEC4 *varrayWorldRes  = nullptr;
DVEC4 *varrayRes = nullptr;
DVEC2i *varrayi = nullptr;
DVEC2i *varrayUVi = nullptr;
int *vindexes = nullptr;

int **vfaces = nullptr;
int *vlight = nullptr;
int **vnfaces = nullptr;
int **uvfaces = nullptr;
int countFaces = 0;

// multi-core (workers) smooth functions
void SmoothWorker1(void *, int wid);
void SmoothWorker2(void *, int wid);
void SmoothWorker3(void *, int wid);
void SmoothWorker4(void *, int wid);

// ground mapping

void MapGroundVertices();

// face struct

typedef struct {
    int *vface; // face vertices [count] then vertices indexes (in DVEC4 *varray)
    int *nface; // face normals [count] then normal indexes (in DVEC4 *vnarray)
    int *uvface; // face u,v [count] then normal indexes (in DVEC2 *vuvarray)
    int countVertices;
    int rendCol;
    int idx;
    DVEC2i *shadowUVi;
    bool shadowed;
} DFace;

DFace **dfaces = NULL;
int countDFaces = 0;

// rendering
DgView curView;
float smoothSurfRatio = 1.8f;
DgSurf *blurSurf16;
DgSurf *srcBlurSurf16;

// smoothing workers
unsigned int smoothWorker2ID = 0;
unsigned int smoothWorker3ID = 0;
unsigned int smoothWorker4ID = 0;

// ressources
DgSurf *Tree2Surf16=NULL;
DgSurf *Ground1Surf16=NULL;

// Shadow Emitter
DgSurf *Tree2SurfShadE16=NULL;
DVEC4 *varrayShadE = nullptr;
DVEC4 *shadEPlane = NULL;
DVEC2i *vuviarrayShadE = nullptr;
DVEC4 *varrayShadEB = nullptr;
DVEC2i *vuviarrayShadEB = nullptr;
DFace shadowFace;

// Poly16 data

// Poly16 point structure
typedef struct {
  int x,y,z;  // screen pos
  int xt,yt;  // texture position
  //int lightRGB; // lightening, RGBA color ... no need in this demo
} PolyPt;

#define MAX_POLY_PTS 4
// tree point
PolyPt TreePts[4] =
   { { 0, 0, 0, 0, 0 },   { 0, 0, 0, 0, 50 },
	 { 0, 0, 0, 50, 50 },   { 0, 0, 0, 50, 0 } };

int ListPtTree[] =
   { 4, (int)&TreePts[0], (int)&TreePts[1],
		(int)&TreePts[2], (int)&TreePts[3] };


//******************
// FONT
FONT F1;
// functions
bool SynchScreen=false;
bool pauseShadow=false;
bool groundTextured=true;
bool highQRendering=false;
bool exitApp=false;
bool takeScreenShot=false;
bool requestRenderMutex=false;
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

int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
	}

    // create rendering DWorker
    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);
    renderMutex = CreateDMutex();
    // create smoothing DWorkers
    smoothWorker2ID = CreateDWorker(SmoothWorker2, nullptr);
    smoothWorker3ID = CreateDWorker(SmoothWorker3, nullptr);
    smoothWorker4ID = CreateDWorker(SmoothWorker4, nullptr);

    if (LoadGIF16(&Tree2Surf16,"../Asset/PICS/TREE2.gif")==0) {
        printf("error loading TREE2.gif\n");
        exit(-1);
    }
    if (LoadPNG16(&Ground1Surf16,"../Asset/PICS/groundhd.png")==0) {
        printf("error loading groundhd.gif\n");
        exit(-1);
    }
    // create High Quality rendering intermediate render Surf
    if (CreateSurf(&blurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        printf("no mem\n"); exit(-1);
    }
    SetOrgSurf(blurSurf16,blurSurf16->ResH/2,blurSurf16->ResV/2);

    if (CreateSurf(&srcBlurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        printf("no mem\n"); exit(-1);
    }
    SetOrgSurf(srcBlurSurf16,srcBlurSurf16->ResH/2,srcBlurSurf16->ResV/2);


	// allocate 3D memory
    varray = (DVEC4*)CreateDVEC4Array(MAX_VERTICES_COUNT);
    vuvarray = (DVEC2*)CreateDVEC2Array(MAX_VERTICES_COUNT);
    vnarray = (DVEC4*)CreateDVEC4Array(MAX_VERTICES_COUNT);
    varrayWorldRes = (DVEC4*)CreateDVEC4Array(MAX_VERTICES_COUNT);
    varrayRes = (DVEC4*)CreateDVEC4Array(MAX_VERTICES_COUNT);
    varrayi = (DVEC2i*)CreateDVEC2Array(MAX_VERTICES_COUNT);
    varrayUVi = (DVEC2i*)CreateDVEC2Array(MAX_VERTICES_COUNT);
    vindexes = (int*)malloc(MAX_INDEXES_SIZE*sizeof(int));
    vfaces = (int**)malloc(MAX_FACES_COUNT*sizeof(int*));
    vnfaces = (int**)malloc(MAX_FACES_COUNT*sizeof(int*));
    uvfaces = (int**)malloc(MAX_FACES_COUNT*sizeof(int*));
    vlight = (int*)malloc(MAX_FACES_COUNT*sizeof(int));
    pAABBox = (DAABBox*)CreateDVEC4Array(8);
    pAAMinBBox = (DAAMinBBox*)CreateDVEC4Array(2);
    matView = CreateDMatrix4();

    // create init Light Dir

	lightVecPos = (DVEC4*)CreateDVEC4();
	plusVEC = (DVEC4*)CreateDVEC4();
    lightDir = CreateInitDVEC4(0.0f, -1.0f, 1.5f, 0.0f);
    NormalizeDVEC4(lightDir);
    lightPos = (DVEC4*)CreateDVEC4();
    matAnimLight = CreateDMatrix4();

    // load 3d model
    DSTRDic *materialDIC = NULL;
    int idt = 0;
    D3DLoader::LoadOBJ("../Asset/MODELS/flat.obj", varray, countVertices, MAX_VERTICES_COUNT,
                            vindexes, countFaces, vfaces, MAX_INDEXES_SIZE, MAX_FACE_INDEXES, MAX_FACES_COUNT,
                            vnarray, &countNormals, vnfaces, vuvarray, &countUV, uvfaces, &materialDIC);

    // init dfaces list
    if (countVertices > 0 && countFaces > 0) {
        printf("flat.obj loaded successfully: %i vertices, %i faces, %i normals \n", countVertices, countFaces, countNormals);
        countDFaces = countFaces;
        dfaces = (DFace**)malloc(sizeof(DFace*)*countFaces);
        for (idt = 0; idt < countFaces; idt++)
            dfaces[idt] = (DFace*)malloc(sizeof(DFace));

        for (idt = 0; idt < countFaces; idt++) {
            dfaces[idt]->vface = vfaces[idt];
            dfaces[idt]->nface = vnfaces[idt];
            dfaces[idt]->countVertices = (vfaces[idt] != NULL) ? vfaces[idt][0] : 0;
            dfaces[idt]->idx = idt;
            dfaces[idt]->shadowed = false;

            if (dfaces[idt]->countVertices > 0) {
                dfaces[idt]->shadowUVi = (DVEC2i*)CreateDVEC2Array(dfaces[idt]->countVertices);
            } else {
                dfaces[idt]->shadowUVi =  NULL;
            }
        }
        // fetch boundaries of 3d model
        FetchDAABBoxDVEC4Array(varray, countVertices, pAABBox);
        FetchDAAMinBBoxDVEC4Array(varray, countVertices, pAAMinBBox);
        MapGroundVertices();
    }

    float bboxWidth = pAAMinBBox->max.x - pAAMinBBox->min.x;
    float bboxHeight = pAAMinBBox->max.y - pAAMinBBox->min.y;
    float bboxDepth = pAAMinBBox->max.z - pAAMinBBox->min.z;
    DVEC4 *bboxMiddle = (DVEC4*)CreateDVEC4();
    *bboxMiddle = pAAMinBBox->max;
    MulValDVEC4(AddDVEC4(bboxMiddle, &pAAMinBBox->min), 0.5);

    //init shadow emitter //////////////////
    varrayShadE = (DVEC4*)CreateDVEC4Array(4);
    vuviarrayShadE = (DVEC2i*)CreateDVEC2Array(4);
    varrayShadEB = (DVEC4*)CreateDVEC4Array(4);
    vuviarrayShadEB = (DVEC2i*)CreateDVEC2Array(4);
    shadEPlane = (DVEC4*)CreateDVEC4();

    // 3d coordinates of displayed Tree
    varrayShadE[0].x = bboxMiddle->x - bboxWidth / 15.0f;
    varrayShadE[0].y = pAAMinBBox->max.y - bboxHeight /2.0;
    varrayShadE[0].z = bboxMiddle->z;

    varrayShadE[1].x = bboxMiddle->x + bboxWidth / 15.0f;
    varrayShadE[1].y = pAAMinBBox->max.y - bboxHeight /2.0;
    varrayShadE[1].z = bboxMiddle->z;

    varrayShadE[2].x = bboxMiddle->x + bboxWidth / 15.0f;
    varrayShadE[2].y = pAAMinBBox->max.y + bboxHeight * 2.0f;
    varrayShadE[2].z = bboxMiddle->z;

    varrayShadE[3].x = bboxMiddle->x - bboxWidth / 15.0f;
    varrayShadE[3].y = pAAMinBBox->max.y + bboxHeight * 2.0f;
    varrayShadE[3].z = bboxMiddle->z;

    // texture UV displayed tree
    vuviarrayShadE[0].x = Tree2Surf16->MinX;
    vuviarrayShadE[0].y = Tree2Surf16->MinY;

    vuviarrayShadE[1].x = Tree2Surf16->MaxX;
    vuviarrayShadE[1].y = Tree2Surf16->MinY;

    vuviarrayShadE[2].x = Tree2Surf16->MaxX;
    vuviarrayShadE[2].y = Tree2Surf16->MaxY;

    vuviarrayShadE[3].x = Tree2Surf16->MinX;
    vuviarrayShadE[3].y = Tree2Surf16->MaxY;

    // create/init shadow emitter texture/coordinates
    int shadEResH = Tree2Surf16->ResH * 1.6f;
    int shadEResV = Tree2Surf16->ResV * 1.2f;
    int shadPlusResH = Tree2Surf16->ResH * 0.3f;
    int shadPlusResV = Tree2Surf16->ResV * 0.1f;
    CreateSurf(&Tree2SurfShadE16, shadEResH, shadEResV, 16);

    DgSetCurSurf(Tree2SurfShadE16);

    ClearSurf16(0);
    PutMaskSurfBlnd16(Tree2Surf16, shadPlusResH, 0, 0, RGB16(16,16,16) | (31<<24));

    // 3d coordinates of shadow emitter
    float midXPlus = (bboxWidth / 7.5) * 0.3f;
    float midYPlus = (bboxHeight * 2.5f) * 0.1f;
    varrayShadEB[0].x = bboxMiddle->x - (bboxWidth / 15.0f) - midXPlus;
    varrayShadEB[0].y = pAAMinBBox->max.y - (bboxHeight /2.0); // - midYPlus;
    varrayShadEB[0].z = bboxMiddle->z;

    varrayShadEB[1].x = bboxMiddle->x + (bboxWidth / 15.0f) + midXPlus;
    varrayShadEB[1].y = pAAMinBBox->max.y - (bboxHeight /2.0); // - midYPlus;
    varrayShadEB[1].z = bboxMiddle->z;

    varrayShadEB[2].x = bboxMiddle->x + (bboxWidth / 15.0f) + midXPlus;
    varrayShadEB[2].y = pAAMinBBox->max.y + (bboxHeight * 2.0f) + midYPlus * 2.0f;
    varrayShadEB[2].z = bboxMiddle->z;

    varrayShadEB[3].x = bboxMiddle->x - (bboxWidth / 15.0f)  - midXPlus;
    varrayShadEB[3].y = pAAMinBBox->max.y + (bboxHeight * 2.0f) + midYPlus * 2.0f;
    varrayShadEB[3].z = bboxMiddle->z;

    GetPlaneDVEC4(&varrayShadEB[0], &varrayShadEB[1], &varrayShadEB[2], shadEPlane);


    // texture UV emitted shadow
    vuviarrayShadEB[0].x = Tree2SurfShadE16->MinX;
    vuviarrayShadEB[0].y = Tree2SurfShadE16->MinY;

    vuviarrayShadEB[1].x = Tree2SurfShadE16->MaxX;
    vuviarrayShadEB[1].y = Tree2SurfShadE16->MinY;

    vuviarrayShadEB[2].x = Tree2SurfShadE16->MaxX;
    vuviarrayShadEB[2].y = Tree2SurfShadE16->MaxY;

    vuviarrayShadEB[3].x = Tree2SurfShadE16->MinX;
    vuviarrayShadEB[3].y = Tree2SurfShadE16->MaxY;


    // adjust camera parameters according to screen and model boundaries
    camera.SetFrustum(60, (float)(ScrResH)/(float)(ScrResV), 1.0f, 1000.0f);
    camera.SetPosition((pAAMinBBox->min.x+pAAMinBBox->max.x)/2.0, (pAAMinBBox->min.y+pAAMinBBox->max.y)/2.0f+15.0f, pAAMinBBox->max.z + (pAAMinBBox->max.z - pAAMinBBox->min.z) / 2.0f );//(pAAMinBBox->min.z+pAAMinBBox->max.z)/2.0);
    MoveSpeed = ((pAAMinBBox->max.x - pAAMinBBox->min.x)+(pAAMinBBox->max.y - pAAMinBBox->min.y)+(pAAMinBBox->max.z - pAAMinBBox->min.z)) / 30.0f;
    // set light pos / anim
    lightPos->x = (pAAMinBBox->min.x+pAAMinBBox->max.x)/2.0;
    lightPos->y = (pAAMinBBox->max.y-pAAMinBBox->min.y)*4 + pAAMinBBox->min.y;
    lightPos->z = (pAAMinBBox->min.z+pAAMinBBox->max.z)/2.0;


    // load font
    //if (!LoadFONT(&F1,"/home/darna/Downloads/DUGL-main/Asset/FONT/HELLOC.chr")) {
    if (!LoadFONT(&F1,"../Asset/FONT/HELLOC.chr")) {
		printf("Error loading HELLOC.chr\n"); exit(-1);
	}

    SetFONT(&F1);

    // init video mode
    if (!DgInitMainWindowX("Shadow", ScrResH, ScrResV, 16, -1, -1, false, false, false))
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


	// RenderSurf should be cleared to avoid any garbage at start-up
    DgSetCurSurf(RendSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    // init synchro
    InitSynch(EventsLoopSynchBuff, NULL, 250); // speed of events scan per second, this will be too the max fps detectable
    InitSynch(RenderSynchBuff, NULL, 60); // screen frequency
	// lunch render DWorker
	RunDWorker(renderWorkerID, false);

	// main loop
	for (int j=0;;j++) {
		// synchronise event loop
		// WaitSynch should be used as Synch will cause scan events by milions or bilions time per sec !
		WaitSynch(EventsLoopSynchBuff, NULL);

		float avgProgress=SynchLastTime(EventsLoopSynchBuff);

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
			case KB_KEY_F6: // F6 switch between solid/textured ground
			    groundTextured=!groundTextured;
				break;
			case KB_KEY_SPACE: // Space to pause
				pauseShadow=!pauseShadow;
				break;
			case KB_KEY_F7 : // F7 High quality rendering
			    highQRendering=!highQRendering;
				break;
			case KB_KEY_TAB: // ctrl + shift + TAB = screenshot
				takeScreenShot = ((keyFLAG&(KB_SHIFT_PR|KB_CTRL_PR)) > 0);
				break;

		}

        if (IsKeyDown(KB_KEY_UP)) { // up
             /*if (move_zcam) {
                zcam = start_zcam - (TreesSpeed * ((float)(DgTime - start_DgTime) / (float)(DgTimerFreq)));
             }*/
			if((KbFLAG & KB_CTRL_PR))
				camera.MoveUpDown(MoveSpeed * avgProgress);
			else
				camera.MoveForwardBackward(MoveSpeed * avgProgress);

        }
        if (IsKeyDown(KB_KEY_DOWN)) { // down
             /*if (move_zcam) {
                zcam = start_zcam + (TreesSpeed * ((float)(DgTime - start_DgTime) / (float)(DgTimerFreq)));
             }*/
			if((KbFLAG & KB_CTRL_PR))
				camera.MoveUpDown(-MoveSpeed * avgProgress);
			else
				camera.MoveForwardBackward(-MoveSpeed * avgProgress);
        }

        if (IsKeyDown(KB_KEY_LEFT)) { // left
             //camera.RotateCamera
             camera.Rotate(0.0f, -RotSpeed*avgProgress, 0.0f);
             //if (xtargetcam > -150.0f) xtargetcam -= TreesSpeed*avgFps;
        }
        if (IsKeyDown(KB_KEY_RIGHT)) {  // right
            camera.Rotate(0.0f, RotSpeed*avgProgress, 0.0f);
        }

		// anim light
		if (!pauseShadow) {
            GetRotDMatrix4(matAnimLight, speedRotLightX*avgProgress, speedRotLightY*avgProgress, speedRotLightZ*avgProgress);
            DMatrix4MulDVEC4Array(matAnimLight, lightDir, 1);
            NormalizeDVEC4(lightDir);
            *lightVecPos = *lightPos;
            plusVEC->x = lightDir->x*7.0f;
            plusVEC->y = lightDir->y*7.0f;
            plusVEC->z = lightDir->z*7.0f;
            AddDVEC4(lightVecPos, plusVEC);
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
			SaveBMP16(RendSurf,(char*)"Shadow.bmp");
			takeScreenShot = false;
			UnlockDMutex(renderMutex);
		}

		DgCheckEvents();
	}

	//WaitDWorker(renderWorkerID); // wait render DWorker finish before exiting
	DestroyDWorker(renderWorkerID);
	renderWorkerID = 0;
    DestroyDMutex(renderMutex);
    renderMutex = NULL;


    DgQuit();
    return 0;
}

int compareDFace (const void * a, const void * b)
{
    DFace *fa  = *((DFace**)a);
    DFace *fb  = *((DFace**)b);
    if (fa->countVertices == 0 || fb->countVertices == 0)
        return 0;

    return (int)(varrayWorldRes[fa->vface[1]].z - varrayWorldRes[fb->vface[1]].z);
}

void RenderWorkerFunc(void *, int ) {

	static float minFps = 0.0f;
	static float maxFps = 0.0f;
	unsigned int frames = 0;
	DVEC4 *lightCamPos = (DVEC4*)CreateDVEC4Array(4);
	DVEC4 *lightCamProj = &lightCamPos[2];
	DVEC2i *lightToScreen = (DVEC2i*)CreateDVEC2Array(2);

	DVEC4 *FacePlane = (DVEC4*)CreateDVEC4();
	DVEC4 *LastFacePlane = (DVEC4*)CreateDVEC4();
    DVEC4 *lighIntersect = (DVEC4*)CreateDVEC4Array(4);

	bool   newFacePlane = true;
	bool   lastIntersectLight = false;
	DVEC4 *crossUV = (DVEC4*)CreateDVEC4();
	DVEC4 *uShadow = (DVEC4*)CreateDVEC4();
	DVEC4 *vShadow = (DVEC4*)CreateDVEC4();
	float lengthU = 0.0f;
	float lengthV = 0.0f;
	DVEC4 *vertShadowDirU = (DVEC4*)CreateDVEC4();
	float dotU = 0.0f;
	float dotV = 0.0f;
	float dotUV = 0.0f;
	float detUV = 0.0f;
    float uVert = 0.0f;
    float vVert = 0.0f;

	DVEC4 *varrayShadowRes = (DVEC4*)CreateDVEC4Array(4);
	DVEC4 *varrayProj = (DVEC4*)CreateDVEC4Array(4);
	DVEC2i *varrayiShadow = (DVEC2i*)CreateDVEC2Array(4);

	AddDVEC4(lightVecPos, plusVEC);

	for(;!exitApp;) {

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
		LockDMutex(renderMutex); // render lock

		if (highQRendering) {
            DgSetCurSurf(srcBlurSurf16);
		} else {
            DgSetCurSurf(RendSurf);
		}
        GetSurfView(&CurSurf, &curView);
        GetViewDMatrix4(matView, &curView, 0.0f, 1.0f, 0.0f, 1.0f);
        camera.SetFrustum(60, (float)(CurSurf.ResH)/(float)(CurSurf.ResV), 1.0f, 1000.0f);


		// clear all the Surf
		DgClear16(0x1e|0x380);

		// transform
		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayResNT(camera.GetTransform(), varray, countVertices, varrayWorldRes);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspResNT(camera.GetProject(), varrayWorldRes, countVertices, varrayRes);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2iNT(matView, varrayRes, countVertices, varrayi);

        // sort DFaces
        qsort (dfaces, countDFaces, sizeof(DFace*), compareDFace);

        // render lines
        int *ptrFace = nullptr;
        int *ptrNFace = nullptr;
        int idx1 = 0;
        int idx2 = 0;
        int idx3 = 0;
        int idx4 = 0;

        int faceCol = RGB16(0,255,128);
        int shadowCol = RGB16(1,1,1);
        int rendCol = 0;
        float dotLightNormal = 0.0f;
        float dotLightNormal2 = 0.0f;
        float dotLightNormal3 = 0.0f;

        float dotShadEBLight = 0.0f;

        DotDVEC4(lightDir, shadEPlane, &dotShadEBLight);
        for (int idt = 0; idt < countDFaces; idt++) {
            ptrFace = dfaces[idt]->vface;
            if (ptrFace == nullptr || dfaces[idt]->countVertices == 0)
                continue;

            idx1 = ptrFace[1];
            idx2 = ptrFace[2];
            idx3 = ptrFace[3];
            bool uvPositive = false;

            // compute face lightening

            ptrNFace = dfaces[idt]->nface;
            if (ptrNFace == nullptr) {
                rendCol = BlndCol16(faceCol, shadowCol, 22);
            } else {
                // compute lightening according to normal of the first vertex of the poly
                if (*DotDVEC4(&vnarray[ptrNFace[1]], lightDir, &dotLightNormal) < 0.0f &&
                    *DotDVEC4(&vnarray[ptrNFace[2]], lightDir, &dotLightNormal2) < 0.0f &&
                    *DotDVEC4(&vnarray[ptrNFace[3]], lightDir, &dotLightNormal3) < 0.0f) {
                    dotLightNormal = (dotLightNormal + dotLightNormal2 + dotLightNormal3) / 3.0f;
                    if (!groundTextured) {
                        // compute new poly color
                        rendCol = BlndCol16(faceCol, shadowCol, (int)(20.0f + 18.0f * dotLightNormal));
                    } else {
                        rendCol = shadowCol | ((int)(20.0f + 18.0f * dotLightNormal)<<24);
                    }
                }
                else
                    if (!groundTextured) {
                        rendCol = BlndCol16(faceCol, shadowCol, 22);
                    } else {
                        rendCol = shadowCol | ((int)(22.0f)<<24);
                    }
            }

            // compute shadow intersection
            GetPlaneDVEC4(&varray[idx1], &varray[idx2], &varray[idx3], FacePlane);
            if (idt == 0) {
                *LastFacePlane = *FacePlane;
                newFacePlane = true;
            } else {
                if (EqualDVEC4(LastFacePlane, FacePlane)) {
                    newFacePlane = false;
                } else {
                    *LastFacePlane = *FacePlane;
                    newFacePlane = true;
                }
            }

            dfaces[idt]->shadowed = true;
            // avoid too thin shadow
            if (dotShadEBLight > 0.25 || dotShadEBLight < -0.25) {

                if (newFacePlane) {
                    lastIntersectLight = true;
                    for (int iv=0; iv < 4; iv++) {
                        if (!IntersectRayPlaneRes(FacePlane, &varrayShadEB[iv], lightDir, &lighIntersect[iv])) {
                            dfaces[idt]->shadowed = false;
                            lastIntersectLight = false;
                            break;
                        }
                    }
                    // compute poly shadow uv
                    SubDVEC4Res(&lighIntersect[1], &lighIntersect[0], uShadow); // xt
                    SubDVEC4Res(&lighIntersect[3], &lighIntersect[0], vShadow); // yt
                    DotDVEC4(uShadow, uShadow, &lengthU);
                    DotDVEC4(vShadow, vShadow, &lengthV);
                    DotDVEC4(uShadow, vShadow, &dotUV);
                    detUV = lengthU * lengthV - (dotUV * dotUV);
                } else {
                    dfaces[idt]->shadowed = lastIntersectLight;
                }
                // compute u v texture coordinate
                if (dfaces[idt]->shadowed) {

                    for (int iv=0; iv < dfaces[idt]->countVertices; iv++) {
                        DotDVEC4(SubDVEC4Res(&varray[ptrFace[iv+1]], &lighIntersect[0], vertShadowDirU), uShadow, &dotU);
                        DotDVEC4(vertShadowDirU, vShadow, &dotV);
                        uVert = (lengthV * dotU - dotUV * dotV) / detUV;
                        vVert = (lengthU * dotV - dotUV * dotU) / detUV;

                        if (uVert >= 1.0f || uVert <= -0.0f || vVert >= 1.0f || vVert <= -0.0f) {
                            dfaces[idt]->shadowed = false;
                            break;
                        } else {
                            dfaces[idt]->shadowUVi[iv].x = uVert * Tree2SurfShadE16->MaxX;
                            dfaces[idt]->shadowUVi[iv].y = vVert * Tree2SurfShadE16->MaxY;
                        }
                    }
                }

            } else {
                dfaces[idt]->shadowed = false;
            }

            // render face
            switch (ptrFace[0]) {
            case 3:
                if ((varrayRes[idx1].z > 0.1f && varrayRes[idx2].z > 0.1f && varrayRes[idx3].z > 0.1f))// &&
                {
                    ListPtTree[0] = 3;
                    TreePts[0].x = varrayi[idx1].x; TreePts[0].y = varrayi[idx1].y;
                    TreePts[1].x = varrayi[idx2].x; TreePts[1].y = varrayi[idx2].y;
                    TreePts[2].x = varrayi[idx3].x; TreePts[2].y = varrayi[idx3].y;
                    if (!groundTextured) {
                        Poly16(&ListPtTree, NULL, POLY16_SOLID, rendCol);
                    } else {
                        TreePts[0].xt = varrayUVi[idx1].x; TreePts[0].yt = varrayUVi[idx1].y;
                        TreePts[1].xt = varrayUVi[idx2].x; TreePts[1].yt = varrayUVi[idx2].y;
                        TreePts[2].xt = varrayUVi[idx3].x; TreePts[2].yt = varrayUVi[idx3].y;
                        Poly16(&ListPtTree, Ground1Surf16, POLY16_TEXT_BLND, rendCol);
                    }
                    if (dfaces[idt]->shadowed) {
                        TreePts[0].xt = dfaces[idt]->shadowUVi[0].x; TreePts[0].yt = dfaces[idt]->shadowUVi[0].y;
                        TreePts[1].xt = dfaces[idt]->shadowUVi[1].x; TreePts[1].yt = dfaces[idt]->shadowUVi[1].y;
                        TreePts[2].xt = dfaces[idt]->shadowUVi[2].x; TreePts[2].yt = dfaces[idt]->shadowUVi[2].y;
                        RePoly16(&ListPtTree, Tree2SurfShadE16, POLY16_MASK_TEXT_TRANS, 15);
                    }
                }
                break;
            case 4:
                idx4 = ptrFace[4];
                if (varrayRes[idx1].z > 0.1f && varrayRes[idx2].z > 0.1f && varrayRes[idx3].z > 0.1f && varrayRes[idx4].z > 0.1f) // &&
                {
                    ListPtTree[0] = 4;
                    TreePts[0].x = varrayi[idx1].x; TreePts[0].y = varrayi[idx1].y;
                    TreePts[1].x = varrayi[idx2].x; TreePts[1].y = varrayi[idx2].y;
                    TreePts[2].x = varrayi[idx3].x; TreePts[2].y = varrayi[idx3].y;
                    TreePts[3].x = varrayi[idx4].x; TreePts[3].y = varrayi[idx4].y;
                    Poly16(&ListPtTree, NULL, POLY16_SOLID, rendCol);
                }
                break;
            }
        }

        // render shadow emitter

		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayResNT(camera.GetTransform(), varrayShadE, 4, varrayWorldRes);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspResNT(camera.GetProject(), varrayWorldRes, 4, varrayRes);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2iNT(matView, varrayRes, 4, varrayi);
        idx1 = 0;
        idx2 = 1;
        idx3 = 2;
        idx4 = 3;
        if (varrayRes[idx1].z > 0.1f && varrayRes[idx2].z > 0.1f && varrayRes[idx3].z > 0.1f && varrayRes[idx4].z > 0.1f) // &&
        {
            ListPtTree[0] = 4;
            TreePts[0].x = varrayi[idx1].x; TreePts[0].y = varrayi[idx1].y;
            TreePts[0].xt = vuviarrayShadE[idx1].x; TreePts[0].yt = vuviarrayShadE[idx1].y;

            TreePts[1].x = varrayi[idx2].x; TreePts[1].y = varrayi[idx2].y;
            TreePts[1].xt = vuviarrayShadE[idx2].x; TreePts[1].yt = vuviarrayShadE[idx2].y;

            TreePts[2].x = varrayi[idx3].x; TreePts[2].y = varrayi[idx3].y;
            TreePts[2].xt = vuviarrayShadE[idx3].x; TreePts[2].yt = vuviarrayShadE[idx3].y;

            TreePts[3].x = varrayi[idx4].x; TreePts[3].y = varrayi[idx4].y;
            TreePts[3].xt = vuviarrayShadE[idx4].x; TreePts[3].yt = vuviarrayShadE[idx4].y;

            Poly16(&ListPtTree, Tree2Surf16, POLY16_MASK_TEXT | POLY16_FLAG_DBL_SIDED, RGB16(255,0,0));
        }

        // render light vector

		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayRes(camera.GetTransform(), lightPos, 1, lightCamPos);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspRes(camera.GetProject(), lightCamPos, 1, lightCamProj);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2i(matView, lightCamProj, 1, lightToScreen);

		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayRes(camera.GetTransform(), lightVecPos, 1, &lightCamPos[1]);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspRes(camera.GetProject(), &lightCamPos[1], 1, &lightCamProj[1]);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2i(matView, &lightCamProj[1], 1, &lightToScreen[1]);

        int plusLight = (highQRendering) ? (3*smoothSurfRatio) : 3;
        Line16(lightToScreen, &lightToScreen[1], 0xffff);
        line16(lightToScreen[1].x-plusLight, lightToScreen[1].y-plusLight,
               lightToScreen[1].x+plusLight, lightToScreen[1].y+plusLight, 0xffff);
        line16(lightToScreen[1].x+plusLight, lightToScreen[1].y-plusLight,
               lightToScreen[1].x-plusLight, lightToScreen[1].y+plusLight, 0xffff);
        if (highQRendering) {
            line16(lightToScreen[0].x, lightToScreen[0].y+1, lightToScreen[1].x, lightToScreen[1].y+1, 0xffff);
            line16(lightToScreen[0].x+1, lightToScreen[0].y, lightToScreen[1].x+1, lightToScreen[1].y, 0xffff);
            line16(lightToScreen[1].x-plusLight+1, lightToScreen[1].y-plusLight,
                    lightToScreen[1].x+plusLight+1, lightToScreen[1].y+plusLight, 0xffff);
            line16(lightToScreen[1].x+plusLight-1, lightToScreen[1].y-plusLight,
                    lightToScreen[1].x-plusLight-1, lightToScreen[1].y+plusLight, 0xffff);
        }

        // smoothing and resizing to the screen size

        if (highQRendering) {
            RunDWorker(smoothWorker2ID, false);
            RunDWorker(smoothWorker3ID, false);
            RunDWorker(smoothWorker4ID, false);
            SmoothWorker1(NULL, 0);
            //WaitDWorker(smoothWorker1ID);
            WaitDWorker(smoothWorker2ID);
            WaitDWorker(smoothWorker3ID);
            WaitDWorker(smoothWorker4ID);

            //BlurSurf16(blurSurf16,srcBlurSurf16);
            DgSetCurSurf(RendSurf);
            ResizeViewSurf16(blurSurf16, 0, 0);
        }

		// restore original Screen View
		ClearText();
		#define SIZE_TEXT 127
		char text[SIZE_TEXT + 1];
		SetTextCol(0xffff);
		if (avgFps!=0.0 && minFps!=0.0 && maxFps!=0.0)
			OutText16ModeFormat(AJ_RIGHT, text, SIZE_TEXT, "MINFPS %i, MAXFPS %i, FPS %i\n", (int)(1.0/minFps),(int)(1.0/maxFps),(int)(1.0/avgFps));
		else
			OutText16Mode("FPS ???\n", AJ_RIGHT);

		ClearText();
		OutText16ModeFormat(AJ_LEFT, text, SIZE_TEXT,
                      "Ctrl+Up/Down  Move Up/Down\n"
                      "Arrows  Move\n"
                      "F5      Vertical Synch: %s\n"
                      "F6      Rendering: %s\n"
                      "F7      Quality: %s\n"
                      "Space   Pause: %s\n"
                      "Esc     Exit\n",
                      (SynchScreen)?"ON":"OFF", (groundTextured)?"Textured":"SOLID",
                      (highQRendering)?"High":"Low",
                      (pauseShadow)?"ON":"OFF");

		DgUpdateWindow();
		UnlockDMutex(renderMutex);
		if (requestRenderMutex) {
            requestRenderMutex = false;
            DelayMs(10); // wait for 10 ms to allow the renderMutex to be token by another thread or DWorker
		}
		frames++;
	}
}

// ground uv mapping

void MapGroundVertices() {
    float bbox_width = pAAMinBBox->max.x - pAAMinBBox->min.x;
    float bbox_depth = pAAMinBBox->max.z - pAAMinBBox->min.z;

    for (int i =0; i < countVertices; i++){
        varrayUVi[i].x = (float(varray[i].x - pAAMinBBox->min.x) / bbox_width) * Ground1Surf16->MaxX;
        varrayUVi[i].y = (float(varray[i].z - pAAMinBBox->min.z) / bbox_depth) * Ground1Surf16->MaxY;
    }
}

// high quality rendering smooth funcs

void SmoothWorker1(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV/4);
}

void SmoothWorker2(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/4, srcBlurSurf16->ResV/2);
}

void SmoothWorker3(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/2+1, srcBlurSurf16->ResV*3/4);
}

void SmoothWorker4(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*3/4+1, srcBlurSurf16->ResV-1);
}
