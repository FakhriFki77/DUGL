/*  Dust Ultimate Game Library (DUGL) - (C) 2025 Fakhri Feki */
/*  Shadow Sample*/
/*  Simple/unoptimized 3d engine, with z-sorting polygones, moving camera, shadow casting on ground, 3d obj loader .. */
/*  History : */
/*  10 April 2023 : first release */
/*  6 Aout 2023: Rework event/rendering loop and synching + implement gouroud shading + implement dual core rendering (left|right) view  */
/*                implement full screen toggling + resize handling + several tweaks and performance increase ... */
/* 12 Aout 2023: Add true VSync, try to fix hang when exiting directly from full screen under linux, enable double-buffering to reduce possible flicker under linux */
/*               + Add fps limiter with DgWaitVSync as it reduce flicker but dot not sync with screen freq */
/* 30 March 2025: Add Multi-core resizing, Improve Multi-Core renderingf up to 4 cores, Add parametric High quality rendering from 1.1 to 3.0 ratio */
/*               With capability to change in real time, add background panoramic sky background, better keyboard shortcuts, Enable double-buff, optimize polygones sorting */
/*               bug fixes, speed improvement .. */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <DUGL.h>
#include "D3DLoader.h"
#include "DCamera3D.h"

// screen resolution
//int ScrResH=320,ScrResV=240;
int ScrResH=640,ScrResV=480;
//int ScrResH=800,ScrResV=600;
//int ScrResH=1024,ScrResV=768;
//int ScrResH=1920,ScrResV=1080;

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

int MAX_VERTICES_COUNT = 5000000;
int MAX_INDEXES_SIZE = 40000000;
int MAX_FACE_INDEXES = 12;
int MAX_FACES_COUNT = 2000000;

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
float *vLightNormals = nullptr;
int *vLightUPos = nullptr;
int countFaces = 0;

int faceCol = RGB16(0,255,128);
int shadowCol = RGB16(1,1,1);
// tree transformation arrays
DVEC4 *varrayTreeRes = NULL;
DVEC4 *varrayTreeProj = NULL;
DVEC2i *varrayiTree = NULL;

DGCORE dgCores[4];

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

PolyPt TreePts_C2[4] =
   { { 0, 0, 0, 0, 0 },   { 0, 0, 0, 0, 50 },
	 { 0, 0, 0, 50, 50 },   { 0, 0, 0, 50, 0 } };

int ListPtTree_C2[] =
   { 4, (int)&TreePts_C2[0], (int)&TreePts_C2[1],
		(int)&TreePts_C2[2], (int)&TreePts_C2[3] };

PolyPt TreePts_C3[4] =
   { { 0, 0, 0, 0, 0 },   { 0, 0, 0, 0, 50 },
	 { 0, 0, 0, 50, 50 },   { 0, 0, 0, 50, 0 } };

int ListPtTree_C3[] =
   { 4, (int)&TreePts_C3[0], (int)&TreePts_C3[1],
		(int)&TreePts_C3[2], (int)&TreePts_C3[3] };

PolyPt TreePts_C4[4] =
   { { 0, 0, 0, 0, 0 },   { 0, 0, 0, 0, 50 },
	 { 0, 0, 0, 50, 50 },   { 0, 0, 0, 50, 0 } };

int ListPtTree_C4[] =
   { 4, (int)&TreePts_C4[0], (int)&TreePts_C4[1],
		(int)&TreePts_C4[2], (int)&TreePts_C4[3] };

PolyPt TreePts_C5[4] =
   { { 0, 0, 0, 0, 0 },   { 0, 0, 0, 0, 50 },
	 { 0, 0, 0, 50, 50 },   { 0, 0, 0, 50, 0 } };

int ListPtTree_C5[] =
   { 4, (int)&TreePts_C5[0], (int)&TreePts_C5[1],
		(int)&TreePts_C5[2], (int)&TreePts_C5[3] };

// backgroun/sky rendering////////////////////////////
/////////////////////////////////////////////////////

// split background/sky img into cylinder of polygones

const double skyCylinderHeight      = 4000000.0;
const double skyCylinderRay         = 3000000.0;
const double skyCylinderYStart      = -2000000.0;
const int skyCylinderYSplits        = 3;
const int skyCylinderCircleSplits   = 16;
const int skyCylinderPolyQuadCount  = skyCylinderYSplits * skyCylinderCircleSplits;
const int skyCylinderLevelVertCount = skyCylinderCircleSplits + 1;
const int skyCylinderVertCount      = (skyCylinderYSplits+1) * skyCylinderLevelVertCount;

DVEC4 varraySkyCylinder[skyCylinderVertCount] __attribute__ ((aligned (16)));

DVEC4 varraySkyCylinderRes[skyCylinderVertCount] __attribute__ ((aligned (16)));
DVEC4 varraySkyCylinderProj[skyCylinderVertCount] __attribute__ ((aligned (16)));
DVEC2i varrayiSkyCylinder[skyCylinderVertCount] __attribute__ ((aligned (16)));

PolyPt ListSkyCylinderPts[skyCylinderVertCount];
// series of (count=4, &ListSkyCylinderPts[n*4], &ListSkyCylinderPts[n*4+1], &ListSkyCylinderPts[n*4+2], &ListSkyCylinderPts[n*4+3]
// where n is the quad count
int ListPtSkyCylinder[skyCylinderPolyQuadCount * 5];
void GenSkyCylinderGeometry();

// multi-core (workers) smooth functions ///////////////////
///////////////////////////////////////////////////////////
void SmoothWorker1C_1(void *, int wid);

void SmoothWorker2C_1(void *, int wid);
void SmoothWorker2C_2(void *, int wid);

void SmoothWorker1(void *, int wid);
void SmoothWorker2(void *, int wid);
void SmoothWorker3(void *, int wid);
void SmoothWorker4(void *, int wid);

void SmoothWorker6C_1(void *, int wid);
void SmoothWorker6C_2(void *, int wid);
void SmoothWorker6C_3(void *, int wid);
void SmoothWorker6C_4(void *, int wid);
void SmoothWorker6C_5(void *, int wid);
void SmoothWorker6C_6(void *, int wid);

// multi-core (workers) render functions ////////////

// common function
void RenderViewCore(DGCORE *curCore, int *curListPtTree, PolyPt *curTreePts);
// full view
void RenderWorker1C_1(void *, int wid);
// left, right
void RenderWorker2C_1(void *, int wid);
void RenderWorker2C_2(void *, int wid);
// top, bottom (left, right)
void RenderWorker4C_1(void *, int wid);
void RenderWorker4C_2(void *, int wid);
void RenderWorker4C_3(void *, int wid);
void RenderWorker4C_4(void *, int wid);

// resize worker smooth to screen (HQ rendering)
void ResizeWorker1C_1(void *, int wid);
// left, right
void ResizeWorker2C_1(void *, int wid);
void ResizeWorker2C_2(void *, int wid);
// top, bottom (left, right)
void ResizeWorker4C_1(void *, int wid);
void ResizeWorker4C_2(void *, int wid);
void ResizeWorker4C_3(void *, int wid);
void ResizeWorker4C_4(void *, int wid);

// ground mapping

void MapGroundVertices();

// face struct

typedef struct {
    int *vface; // face vertices [count] then vertices indexes (in DVEC4 *varray)
    int *nface; // face normals [count] then normal indexes (in DVEC4 *vnarray)
    int *uvface; // face u,v [count] then u,v indexes (in DVEC2 *vuvarray)
    int countVertices;
    int rendCol;
    int idx;
    DVEC2i *shadowUVi;
    bool shadowed;
} DFace;

DFace **dfaces = NULL;
DFace *DFaces = NULL;
int countDFaces = 0;
bool refreshFacesSorting = true;

// rendering
#define MIN_HQR_SURF_RATIO   1.1f
#define MAX_HQR_SURF_RATIO   3.0f
#define HQ_SURF_RATIO_STEP   0.05f

float smoothSurfRatio = 1.6f;
DgSurf *blurSurf16 = NULL;
DgSurf *srcBlurSurf16 = NULL;
DgSurf *gouroudLightSurf = NULL;
float newSmoothSurfRatio = smoothSurfRatio;
bool triggerReallocSmoothSurfs = false;

bool AllocSmoothSurfs();

// smoothing workers count / ID
unsigned int smoothingCores  = 4;

unsigned int smoothWorker2C_2ID = 0;

unsigned int smoothWorker2ID = 0;
unsigned int smoothWorker3ID = 0;
unsigned int smoothWorker4ID = 0;

unsigned int smoothWorker6C_2ID = 0;
unsigned int smoothWorker6C_3ID = 0;
unsigned int smoothWorker6C_4ID = 0;
unsigned int smoothWorker6C_5ID = 0;
unsigned int smoothWorker6C_6ID = 0;

// resize workers (after rendering bigger smooth View)
unsigned int resizeCores  = 1;
unsigned int resizeWorker2C_2ID = 0;

unsigned int resizeWorker4C_2ID = 0;
unsigned int resizeWorker4C_3ID = 0;
unsigned int resizeWorker4C_4ID = 0;


// render workers count / ID
unsigned int renderCores  = 2;

unsigned int renderWorker2C_2ID = 0;

unsigned int renderWorker4C_2ID = 0;
unsigned int renderWorker4C_3ID = 0;
unsigned int renderWorker4C_4ID = 0;

// ressources
DgSurf *Tree2Surf16 = NULL;
DgSurf *Ground1Surf16 = NULL;
DgSurf *BackSky16 = NULL;

// Shadow Emitter
DgSurf *Tree2SurfShadE16=NULL;
DVEC4 *varrayShadE = nullptr;
DVEC4 *shadEPlane = NULL;
DVEC2i *vuviarrayShadE = nullptr;
DVEC4 *varrayShadEB = nullptr;
DVEC2i *vuviarrayShadEB = nullptr;
DFace shadowFace;

//******************
// FONT
FONT F1;
// functions
bool SynchScreen=false;
bool pauseShadow=false;
bool groundTextured=true;
bool highQRendering=false;
bool fullScreen=false;
bool exitApp=false;
bool skyBack=true;
bool takeScreenShot=false;
bool refreshWindow=false;
bool refreshLightening = false;
bool requestRenderMutex=false;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
char RenderSynchBuff[SIZE_SYNCH_BUFF];
// render DWorker
unsigned int renderWorkerID = 0;
void *renderMutex = NULL;
void RenderWorkerFunc(void *, int );
// window event
void ShadowWinPreResize(int w, int h);
void ShadowWinResize(int w, int h);
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
    // get all DgCores
    GetDGCORE(&dgCores[0], 0);
    GetDGCORE(&dgCores[1], 1);
    GetDGCORE(&dgCores[2], 2);
    GetDGCORE(&dgCores[3], 3);
    // create smoothing DWorkers
    smoothWorker2C_2ID = CreateDWorker(SmoothWorker2C_2, nullptr);

    smoothWorker2ID = CreateDWorker(SmoothWorker2, nullptr);
    smoothWorker3ID = CreateDWorker(SmoothWorker3, nullptr);
    smoothWorker4ID = CreateDWorker(SmoothWorker4, nullptr);

    smoothWorker6C_2ID = CreateDWorker(SmoothWorker6C_2, nullptr);
    smoothWorker6C_3ID = CreateDWorker(SmoothWorker6C_3, nullptr);
    smoothWorker6C_4ID = CreateDWorker(SmoothWorker6C_4, nullptr);
    smoothWorker6C_5ID = CreateDWorker(SmoothWorker6C_5, nullptr);
    smoothWorker6C_6ID = CreateDWorker(SmoothWorker6C_6, nullptr);

    // create render(ground/shadow) DWorkers
    renderWorker2C_2ID = CreateDWorker(RenderWorker2C_2, nullptr);

    renderWorker4C_2ID = CreateDWorker(RenderWorker4C_2, nullptr);
    renderWorker4C_3ID = CreateDWorker(RenderWorker4C_3, nullptr);
    renderWorker4C_4ID = CreateDWorker(RenderWorker4C_4, nullptr);

    // resize DWorkers
    resizeWorker2C_2ID = CreateDWorker(ResizeWorker2C_2, nullptr);

    resizeWorker4C_2ID = CreateDWorker(ResizeWorker4C_2, nullptr);
    resizeWorker4C_3ID = CreateDWorker(ResizeWorker4C_3, nullptr);
    resizeWorker4C_4ID = CreateDWorker(ResizeWorker4C_4, nullptr);

    // load ressources
    if (LoadGIF16(&Tree2Surf16,"../Asset/PICS/TREE2.gif")==0) {
        printf("error loading TREE2.gif\n");
        exit(-1);
    }
    if (LoadPNG16(&Ground1Surf16,"../Asset/PICS/groundhd.png")==0) {
        printf("error loading groundhd.gif\n");
        exit(-1);
    }
    if (LoadPNG16(&BackSky16, "../Asset/PICS/Background2.png") == 0) {
        printf("error loading Background2.png\n");
        exit(-1);
    }
    // generate sky cylinder geometry (uv or (xt, yt)) PolyPt and ListPtPoly
    GenSkyCylinderGeometry();

    // load font
    if (!LoadFONT(&F1,"../Asset/FONT/HELLO.chr")) {
		printf("Error loading HELLO.chr\n"); exit(-1);
        exit(-1);
	}

    SetFONT(&F1);
    // allocate High Quality rendering Surfs
    if (!AllocSmoothSurfs()) {
		printf("No mem! failure to create HQ rendering Surfs\n"); exit(-1);
        exit(-1);
    }

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
    vLightNormals = (float*)malloc(MAX_VERTICES_COUNT*sizeof(float));
    vLightUPos = (int*)malloc(MAX_VERTICES_COUNT*sizeof(int));
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
        DFaces = (DFace*)malloc(sizeof(DFace)*countFaces+1024);
        dfaces = (DFace**)malloc(sizeof(DFace*)*countFaces);
        for (idt = 0; idt < countFaces; idt++)
            dfaces[idt] = &DFaces[idt];

        for (idt = 0; idt < countFaces; idt++) {
            DFaces[idt].vface = vfaces[idt];
            DFaces[idt].nface = vnfaces[idt];
            DFaces[idt].countVertices = (vfaces[idt] != NULL) ? vfaces[idt][0] : 0;
            DFaces[idt].idx = idt;
            DFaces[idt].shadowed = false;

            if (DFaces[idt].countVertices > 0) {
                DFaces[idt].shadowUVi = (DVEC2i*)CreateDVEC2Array(DFaces[idt].countVertices);
            } else {
                DFaces[idt].shadowUVi =  NULL;
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

    DgSetPreferredFullScreenMode(ScrResH, ScrResV, 0);
    // init video mode
    if (!DgInitMainWindowX("Shadow", ScrResH, ScrResV, 16, -1, -1, fullScreen, false, true))
    {
        DgQuit();
        exit(-1);
    }
    // enable double buffer
    DgSetEnabledDoubleBuff(true);
    // create gouroud lightening Surf
    int grdMaxCols = 64;
    //int grdStartR = 32, grdStartG = 32, grdStartB = 32;
    int grdStartR = 0, grdStartG = 0, grdStartB = 0;
    int grdEndR = 232, grdEndG = 232, grdEndB = 232;
    float grdStepR = float(grdEndR-grdStartR) / float(grdMaxCols);
    float grdStepG= float(grdEndG-grdStartG) / float(grdMaxCols);
    float grdStepB = float(grdEndB-grdStartB) / float(grdMaxCols);
    if (CreateSurf(&gouroudLightSurf, grdMaxCols, 1, 16)==0) {
        printf("no mem\n"); exit(-1);
    }
    for (int grdI=0; grdI < grdMaxCols; grdI++) {
        DgSurfCPutPixel16(gouroudLightSurf, grdI, 0, RGB16(int(grdStepR*grdI+grdStartR), int(grdStepG*grdI+grdStartG), int(grdStepB*grdI+grdStartB)));
    }

    // set Main window properties
    DgWindowResized = 0;
    ScrResH = RendSurf->ResH;
    ScrResV = RendSurf->ResV;
    DgSetMainWindowMinSize(320, 200);
    DgSetMainWindowResizeCallBack(ShadowWinPreResize, ShadowWinResize, renderMutex, &requestRenderMutex);

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
	DgSetEnabledDoubleBuff(true);
	SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);
	SetOrgSurf(RendFrontSurf, RendFrontSurf->ResH/2, RendFrontSurf->ResV/2);

	// RenderSurf should be cleared to avoid any garbage at start-up
    DgSetCurSurf(RendSurf);
    DgClear16(0); // clear by black
    DgUpdateWindow();

    // init synchro
    unsigned int LastDgTime = DgTime;
    unsigned int DgTimeToHandle = DgTime;
    unsigned int deltaDgTime = 0;
    float revDgTimeFreq = 1.0f / (float)DgTimerFreq;
    InitSynch(EventsLoopSynchBuff, NULL, 500); // speed of events scan per second, better same timer frequency else progress could be lost at high fps
    InitSynch(RenderSynchBuff, NULL, 60); // screen frequency
	// lunch render DWorker
	RunDWorker(renderWorkerID, false);

	// main loop
	for (int j=0;;j++) {
		// synchronise event loop
		if (Synch(EventsLoopSynchBuff, NULL) > 0) {
            float avgProgress = SynchLastTime(EventsLoopSynchBuff);

            // get key
            unsigned char keyCode;
            unsigned int keyFLAG;

            GetKey(&keyCode, &keyFLAG);
            switch (keyCode) {
                case KB_KEY_ESC:
                    exitApp = true;
                    break;
                case KB_KEY_F5: // F5 vertical synch e/d
                    SynchScreen=!SynchScreen;
                    break;
                case KB_KEY_F6: // F6 switch between solid/textured ground
                    groundTextured=!groundTextured;
                    refreshLightening = true;
                    break;
                case KB_KEY_SPACE: // Space to pause
                    pauseShadow=!pauseShadow;
                    break;
                case KB_KEY_F2: // switch smoothing Cores count
                    takeScreenShot = ((keyFLAG&(KB_SHIFT_PR|KB_CTRL_PR)) > 0);
                    if (!takeScreenShot) {
                        if (smoothingCores == 1)
                            smoothingCores = 2;
                        else if (smoothingCores == 2)
                            smoothingCores = 4;
                        else if (smoothingCores == 4)
                            smoothingCores = 6;
                        else if (smoothingCores == 6)
                            smoothingCores = 1;
                    }
                    break;
                case KB_KEY_F3: // switch render Cores count
                    if (resizeCores == 1)
                        resizeCores = 2;
                    else if (resizeCores == 2)
                        resizeCores = 4;
                    else if (resizeCores == 4)
                        resizeCores = 1;
                    break;
                case KB_KEY_F4: // switch render Cores count
                    if (renderCores == 1)
                        renderCores = 2;
                    else if (renderCores == 2)
                        renderCores = 4;
                    else if (renderCores == 4)
                        renderCores = 1;
                    break;
                case KB_KEY_F7 : // F7 High quality rendering
                    // avoid enabling HQ rendering on the middle of render loop to do not create flickering
                    if(!TryLockDMutex(renderMutex)) {
                        for (requestRenderMutex = true;requestRenderMutex;) DelayMs(1);
                        LockDMutex(renderMutex);
                    }
                    highQRendering=!highQRendering;
                    UnlockDMutex(renderMutex);
                    break;
                case KB_KEY_F8 :
                    skyBack = !skyBack;
                    break;
                case KB_KEY_F10 : // toggle full screen
                    if(!TryLockDMutex(renderMutex)) {
                        for (requestRenderMutex = true;requestRenderMutex;) DelayMs(1);
                        LockDMutex(renderMutex);
                    }
                    fullScreen = !fullScreen;
                    DgToggleFullScreen(fullScreen);
                    SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);
                    UnlockDMutex(renderMutex);
                    break;
                case KB_KEY_LEFT :
                    if ((KbFLAG&KB_SHIFT_PR) > 0) {
                        if ((smoothSurfRatio-HQ_SURF_RATIO_STEP) > MIN_HQR_SURF_RATIO) {
                            newSmoothSurfRatio = (smoothSurfRatio - HQ_SURF_RATIO_STEP);
                            triggerReallocSmoothSurfs = true;
                        }
                    }
                    break;
                case KB_KEY_RIGHT :
                    if ((KbFLAG&KB_SHIFT_PR) > 0) {
                        if ((smoothSurfRatio+HQ_SURF_RATIO_STEP) < MAX_HQR_SURF_RATIO) {
                            newSmoothSurfRatio = (smoothSurfRatio + HQ_SURF_RATIO_STEP);
                            triggerReallocSmoothSurfs = true;
                        }
                    }
                    break;
            }

            if ((KbFLAG&KB_SHIFT_PR) == 0) {
                if (IsKeyDown(KB_KEY_UP)) { // up
                    if((KbFLAG & KB_CTRL_PR))
                        camera.MoveUpDown(MoveSpeed * avgProgress);
                    else
                        camera.MoveForwardBackward(MoveSpeed * avgProgress);
                    refreshFacesSorting = true;
                }
                if (IsKeyDown(KB_KEY_DOWN)) { // down
                    if((KbFLAG & KB_CTRL_PR))
                        camera.MoveUpDown(-MoveSpeed * avgProgress);
                    else
                        camera.MoveForwardBackward(-MoveSpeed * avgProgress);
                    refreshFacesSorting = true;
                }

                if (IsKeyDown(KB_KEY_LEFT)) { // left
                     //camera.RotateCamera
                    camera.Rotate(0.0f, -RotSpeed*avgProgress, 0.0f);
                    refreshFacesSorting = true;
                }
                if (IsKeyDown(KB_KEY_RIGHT)) {  // right
                    camera.Rotate(0.0f, RotSpeed*avgProgress, 0.0f);
                    refreshFacesSorting = true;
                }
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

        } else if (!refreshWindow && SynchScreen) {
            DelayMs(1);
        }

		if (refreshWindow) {
            // synchronise
            if (SynchScreen) {
                WaitSynch(RenderSynchBuff,NULL); // limit fps
                DgWaitVSync(); // wait VSync
            } else {
                Synch(RenderSynchBuff,NULL);
            }

            DgUpdateWindow();
            refreshWindow = false;
		}
	}

	// wait render DWorker finish before exiting
	while(exitApp) {
        // revert to desktop display mode
        if (DgIsFullScreen()) {
            DgToggleFullScreen(false);
        }
        DgCheckEvents();
        DelayMs(1);
	}

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

	float accFps = 0.0f;
	int accCountFps = 0;
	int finalCountFps = 0;

	unsigned int frames = 0;
	DgView curView;
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

	varrayTreeRes = (DVEC4*)CreateDVEC4Array(4);
	varrayTreeProj = (DVEC4*)CreateDVEC4Array(4);
	varrayiTree = (DVEC2i*)CreateDVEC2Array(4);

	AddDVEC4(lightVecPos, plusVEC);

	for(;!exitApp;) {


		// synch screen display
		avgFps=SynchAverageTime(RenderSynchBuff);
		lastFps=SynchLastTime(RenderSynchBuff);
		if ((accFps+avgFps) <= 1.0f) {
            accCountFps ++;
		}
		accFps+=avgFps;

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
        //camera.SetFrustum(60, (float)(CurSurf.ResH)/(float)(CurSurf.ResV), 1.0f, 1000.0f);

		// transform
		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayRes(camera.GetTransform(), varray, countVertices, varrayWorldRes);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspRes(camera.GetProject(), varrayWorldRes, countVertices, varrayRes);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2i(matView, varrayRes, countVertices, varrayi);

        // sort DFaces
        if (refreshFacesSorting) {
            qsort (dfaces, countDFaces, sizeof(DFace*), compareDFace);
            refreshFacesSorting = false;
        }

        // render lines
        int *ptrFace = nullptr;
        int *ptrNFace = nullptr;
        int idx1 = 0;
        int idx2 = 0;
        int idx3 = 0;
        int idx4 = 0;

        //int rendCol = 0;
        float dotLightNormal = 0.0f;

        float dotShadEBLight = 0.0f;

        DotDVEC4(lightDir, shadEPlane, &dotShadEBLight);
        // compute each face lightening / shadow uv
        // do not recompute if light orientation is paused
        if (!pauseShadow || refreshLightening) {
            refreshLightening = false;
            for (int idt = 0; idt < countDFaces; idt++) {
                ptrFace = DFaces[idt].vface;
                if (ptrFace == nullptr || DFaces[idt].countVertices == 0)
                    continue;

                idx1 = ptrFace[1];
                idx2 = ptrFace[2];
                idx3 = ptrFace[3];
                bool uvPositive = false;

                // compute face lightening

                ptrNFace = DFaces[idt].nface;
                if (ptrNFace == nullptr) {
                    DFaces[idt].rendCol = BlndCol16(faceCol, shadowCol, 22);
                } else {
                    DotDVEC4(&vnarray[ptrNFace[1]], lightDir, &vLightNormals[idx1]);
                    DotDVEC4(&vnarray[ptrNFace[2]], lightDir, &vLightNormals[idx2]);
                    DotDVEC4(&vnarray[ptrNFace[3]], lightDir, &vLightNormals[idx3]);

                    // compute lightening according to normal of the first vertex of the poly
                    if (vLightNormals[idx1] < 0.0f && vLightNormals[idx2] < 0.0f && vLightNormals[idx3] < 0.0f) {
                        dotLightNormal = (vLightNormals[idx1] + vLightNormals[idx2] + vLightNormals[idx3]) / 3.0f;
                        if (!groundTextured) {
                            // compute new poly color
                            DFaces[idt].rendCol = BlndCol16(faceCol, shadowCol, (int)(20.0f + 18.0f * dotLightNormal));
                        } else {
                            DFaces[idt].rendCol = shadowCol | ((int)(18.0 + 18.0f * dotLightNormal)<<24);
                        }
                    }
                    else {
                        if (!groundTextured) {
                            DFaces[idt].rendCol = BlndCol16(faceCol, shadowCol, 22);
                        } else {
                            DFaces[idt].rendCol = shadowCol | ((int)(18.0f)<<24);
                        }
                    }
                    vLightUPos[idx1] = (vLightNormals[idx1] < 0.0f) ? (int)(vLightNormals[idx1]*-35.0f) : 0;
                    vLightUPos[idx2] = (vLightNormals[idx2] < 0.0f) ? (int)(vLightNormals[idx2]*-35.0f) : 0;
                    vLightUPos[idx3] = (vLightNormals[idx3] < 0.0f) ? (int)(vLightNormals[idx3]*-35.0f) : 0;
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

                DFaces[idt].shadowed = true;
                // avoid too thin shadow
                if (dotShadEBLight > 0.25 || dotShadEBLight < -0.25) {

                    if (newFacePlane) {
                        lastIntersectLight = true;
                        for (int iv=0; iv < 4; iv++) {
                            if (!IntersectRayPlaneRes(FacePlane, &varrayShadEB[iv], lightDir, &lighIntersect[iv])) {
                                DFaces[idt].shadowed = false;
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
                        DFaces[idt].shadowed = lastIntersectLight;
                    }
                    // compute u v texture coordinate
                    if (DFaces[idt].shadowed) {

                        for (int iv=0; iv < DFaces[idt].countVertices; iv++) {
                            DotDVEC4(SubDVEC4Res(&varray[ptrFace[iv+1]], &lighIntersect[0], vertShadowDirU), uShadow, &dotU);
                            DotDVEC4(vertShadowDirU, vShadow, &dotV);
                            uVert = (lengthV * dotU - dotUV * dotV) / detUV;
                            vVert = (lengthU * dotV - dotUV * dotU) / detUV;

                            if (uVert >= 1.0f || uVert <= -0.0f || vVert >= 1.0f || vVert <= -0.0f) {
                                DFaces[idt].shadowed = false;
                                break;
                            } else {
                                DFaces[idt].shadowUVi[iv].x = uVert * Tree2SurfShadE16->MaxX;
                                DFaces[idt].shadowUVi[iv].y = vVert * Tree2SurfShadE16->MaxY;
                            }
                        }
                    }

                } else {
                    DFaces[idt].shadowed = false;
                }
            }
        }

        // sky rendering

		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayRes(camera.GetTransform(), varraySkyCylinder, skyCylinderVertCount, varraySkyCylinderRes);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspRes(camera.GetProject(), varraySkyCylinderRes, skyCylinderVertCount, varraySkyCylinderProj);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2i(matView, varraySkyCylinderProj, skyCylinderVertCount, varrayiSkyCylinder);
        // copy result screen coordinates
        for (int skI = 0; skI<skyCylinderVertCount ; skI++) {
            ListSkyCylinderPts[skI].x = varrayiSkyCylinder[skI].x;
            ListSkyCylinderPts[skI].y = varrayiSkyCylinder[skI].y;
        }

        // tree sprite rendering

		// rotate/move according to camera position/orientation
        DMatrix4MulDVEC4ArrayRes(camera.GetTransform(), varrayShadE, 4, varrayTreeRes);
        // project into camera
        DMatrix4MulDVEC4ArrayPerspRes(camera.GetProject(), varrayTreeRes, 4, varrayTreeProj);
        // projection to screen
        DMatrix4MulDVEC4ArrayResDVec2i(matView, varrayTreeProj, 4, varrayiTree);

        ListPtTree_C5[0] = 4;
        TreePts_C5[0].x = varrayiTree[0].x;     TreePts_C5[0].y = varrayiTree[0].y;
        TreePts_C5[0].xt = vuviarrayShadE[0].x; TreePts_C5[0].yt = vuviarrayShadE[0].y;
        TreePts_C5[1].x = varrayiTree[1].x;     TreePts_C5[1].y = varrayiTree[1].y;
        TreePts_C5[1].xt = vuviarrayShadE[1].x; TreePts_C5[1].yt = vuviarrayShadE[1].y;
        TreePts_C5[2].x = varrayiTree[2].x;     TreePts_C5[2].y = varrayiTree[2].y;
        TreePts_C5[2].xt = vuviarrayShadE[2].x; TreePts_C5[2].yt = vuviarrayShadE[2].y;
        TreePts_C5[3].x = varrayiTree[3].x;     TreePts_C5[3].y = varrayiTree[3].y;
        TreePts_C5[3].xt = vuviarrayShadE[3].x; TreePts_C5[3].yt = vuviarrayShadE[3].y;

        // clear the entire view if no backgroud sky enabled
        if (!skyBack)
            DgClear16(0x1e|0x380);

        // render ground and casted shadow on it
        switch (renderCores) {
            case 1:
                RenderWorker1C_1(NULL, 0);
                break;
            case 2:
                RunDWorker(renderWorker2C_2ID, false);
                RenderWorker2C_1(NULL, 0);
                WaitDWorker(renderWorker2C_2ID);
                break;
            case 4:
                RunDWorker(renderWorker4C_2ID, false);
                RunDWorker(renderWorker4C_3ID, false);
                RunDWorker(renderWorker4C_4ID, false);
                RenderWorker4C_1(NULL, 0);
                WaitDWorker(renderWorker4C_2ID);
                WaitDWorker(renderWorker4C_3ID);
                WaitDWorker(renderWorker4C_4ID);
                break;
        }

        // render shadow emitter
        // restore full view
        if (highQRendering) {
            DgSetCurSurf(srcBlurSurf16);
        } else {
            DgSetCurSurf(RendSurf);
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
            switch (smoothingCores) {
                case 1:
                    SmoothWorker1C_1(NULL, 0);
                    break;
                case 2:
                    RunDWorker(smoothWorker2C_2ID, false);
                    SmoothWorker2C_1(NULL, 0);
                    WaitDWorker(smoothWorker2C_2ID);
                    break;
                case 4:
                    RunDWorker(smoothWorker2ID, false);
                    RunDWorker(smoothWorker3ID, false);
                    RunDWorker(smoothWorker4ID, false);
                    SmoothWorker1(NULL, 0);
                    //WaitDWorker(smoothWorker1ID);
                    WaitDWorker(smoothWorker2ID);
                    WaitDWorker(smoothWorker3ID);
                    WaitDWorker(smoothWorker4ID);
                    break;
                case 6:
                    RunDWorker(smoothWorker6C_2ID, false);
                    RunDWorker(smoothWorker6C_3ID, false);
                    RunDWorker(smoothWorker6C_4ID, false);
                    RunDWorker(smoothWorker6C_5ID, false);
                    RunDWorker(smoothWorker6C_6ID, false);
                    SmoothWorker6C_1(NULL, 0);
                    WaitDWorker(smoothWorker6C_2ID);
                    WaitDWorker(smoothWorker6C_3ID);
                    WaitDWorker(smoothWorker6C_4ID);
                    WaitDWorker(smoothWorker6C_5ID);
                    WaitDWorker(smoothWorker6C_6ID);
                    break;
            }
            // resize smoothed Surf to create HQ rendering
            //ResizeWorker1C_1(NULL, 0);
            switch (resizeCores) {
                case 1:
                    ResizeWorker1C_1(NULL, 0);
                    break;
                case 2:
                    RunDWorker(resizeWorker2C_2ID, false);
                    ResizeWorker2C_1(NULL, 0);
                    WaitDWorker(resizeWorker2C_2ID);
                    break;
                case 4:
                    RunDWorker(resizeWorker4C_2ID, false);
                    RunDWorker(resizeWorker4C_3ID, false);
                    RunDWorker(resizeWorker4C_4ID, false);
                    ResizeWorker4C_1(NULL, 0);
                    WaitDWorker(resizeWorker4C_2ID);
                    WaitDWorker(resizeWorker4C_3ID);
                    WaitDWorker(resizeWorker4C_4ID);
                    break;
            }
        }

		// restore original Screen View
		DgSetCurSurf(RendSurf);
		ClearText();
		#define SIZE_TEXT 511
		char text[SIZE_TEXT + 1];
		SetTextCol(0xffff);
        OutText16ModeFormat(AJ_RIGHT, text, SIZE_TEXT, "FPS %i\n", finalCountFps);

        if (accFps >= 1.0f) {
            finalCountFps = accCountFps;
            accFps -= 1.0f;
            accCountFps = 0;
        }
		ClearText();
		OutText16ModeFormat(AJ_LEFT, text, SIZE_TEXT,
                      "Ctrl+Up/Down  Move Up/Down\n"
                      "Arrows  Move\n"
                      "F2      Smoothing cores: %i\n"
                      "Shift+Left/Right  HQ Ratio %0.2f\n"
                      "F3      Resize cores: %i\n"
                      "F4      Render cores: %i\n"
                      "F5      Vertical Synch: %s\n"
                      "F6      Rendering: %s\n"
                      "F7      Quality: %s\n"
                      "F8      Sky background: %s\n"
                      "F10     FullScreen: %s\n"
                      "Space   Pause: %s\n"
                      "Esc     Exit\n",
                      smoothingCores, smoothSurfRatio,
                      resizeCores, renderCores,
                      (SynchScreen)?"ON":"OFF", (groundTextured)?"Textured":"SOLID",
                      (highQRendering)?"High":"Low", (skyBack)?"Yes":"No", (fullScreen)?"Yes":"No",
                      (pauseShadow)?"ON":"OFF");

		UnlockDMutex(renderMutex);

		refreshWindow = true;
        // wait until last frame displayed or an exit requested
        while(refreshWindow && !exitApp && !requestRenderMutex) {
            if (SynchScreen) {
                DelayMs(1);
            }
        }
        if (triggerReallocSmoothSurfs) {
            float saveRatio = smoothSurfRatio;
            smoothSurfRatio = newSmoothSurfRatio;
            // if failure revert old value
            if (!AllocSmoothSurfs()) {
                smoothSurfRatio = saveRatio;
            }
            triggerReallocSmoothSurfs = false;
        }
		if (requestRenderMutex) {
            requestRenderMutex = false;
            DelayMs(10); // wait for 10 ms to allow the renderMutex to be token by another thread or DWorker
		}
		frames++;
	}
	exitApp = false;
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

void ShadowWinPreResize(int w, int h) {
}

void ShadowWinResize(int w, int h) {
    if (RendSurf == NULL)
        return;

    SetOrgSurf(RendSurf, RendSurf->ResH/2, RendSurf->ResV/2);
    SetOrgSurf(RendFrontSurf, RendFrontSurf->ResH/2, RendFrontSurf->ResV/2);

    DestroySurf(blurSurf16);
    DestroySurf(srcBlurSurf16);

    DgWindowResized = 0;
    ScrResH = RendSurf->ResH;
    ScrResV = RendSurf->ResV;
    if (CreateSurf(&blurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        printf("no mem\n"); exit(-1);
    }
    SetOrgSurf(blurSurf16,blurSurf16->ResH/2,blurSurf16->ResV/2);

    if (CreateSurf(&srcBlurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        printf("no mem\n"); exit(-1);
    }
    SetOrgSurf(srcBlurSurf16,srcBlurSurf16->ResH/2,srcBlurSurf16->ResV/2);
}

// high quality rendering smooth funcs

// 1 core

void SmoothWorker1C_1(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV-1);
}

// 2 cores

void SmoothWorker2C_1(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV/2);
}

void SmoothWorker2C_2(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/2+1, srcBlurSurf16->ResV-1);
}

// 4 cores - orig
void SmoothWorker1(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV/4);
}

void SmoothWorker2(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/4+1, srcBlurSurf16->ResV/2);
}

void SmoothWorker3(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/2+1, srcBlurSurf16->ResV*3/4);
}

void SmoothWorker4(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*3/4+1, srcBlurSurf16->ResV-1);
}

// 6 cores
void SmoothWorker6C_1(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, 0, srcBlurSurf16->ResV/6);
}

void SmoothWorker6C_2(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV/6+1, srcBlurSurf16->ResV*2/6);
}

void SmoothWorker6C_3(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*2/6+1, srcBlurSurf16->ResV*3/6);
}

void SmoothWorker6C_4(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*3/6+1, srcBlurSurf16->ResV*4/6);
}

void SmoothWorker6C_5(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*4/6+1, srcBlurSurf16->ResV*5/6);
}

void SmoothWorker6C_6(void *, int wid) {
    Blur16((void*)blurSurf16->rlfb, (void*)srcBlurSurf16->rlfb, srcBlurSurf16->ResH, srcBlurSurf16->ResV, srcBlurSurf16->ResV*5/6+1, srcBlurSurf16->ResV-1);
}

// multi-core (workers) render functions ////////////

// full view
void RenderWorker1C_1(void *, int wid) {
    DgView curView;
    int *ptrFace = nullptr;
    int idx1 = 0;
    int idx2 = 0;
    int idx3 = 0;
    int idx4 = 0;

    if (highQRendering) {
        DgSetCurSurf(srcBlurSurf16);
    } else {
        DgSetCurSurf(RendSurf);
    }

    RenderViewCore(&dgCores[0], ListPtTree, TreePts);
}

// left, right
void RenderWorker2C_1(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf(srcBlurSurf16);
    } else {
        DgSetCurSurf(RendSurf);
    }
    GetSurfView(&CurSurf, &curView);
    curView.MaxX = 0;
    SetSurfView(&CurSurf, &curView);

    RenderViewCore(&dgCores[0], ListPtTree, TreePts);
}

void RenderWorker2C_2(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf_C2(srcBlurSurf16);
    } else {
        DgSetCurSurf_C2(RendSurf);
    }
    GetSurfView(&CurSurf_C2, &curView);
    curView.MinX = 1;
    SetSurfView(&CurSurf_C2, &curView);

    RenderViewCore(&dgCores[1], ListPtTree_C2, TreePts_C2);
}
// top (left, right), bottom (left, right)
void RenderWorker4C_1(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf(srcBlurSurf16);
    } else {
        DgSetCurSurf(RendSurf);
    }
    GetSurfView(&CurSurf, &curView);
    curView.MaxX = 0;
    curView.MinY = 1;
    SetSurfView(&CurSurf, &curView);

    RenderViewCore(&dgCores[0], ListPtTree, TreePts);
}

void RenderWorker4C_2(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf_C2(srcBlurSurf16);
    } else {
        DgSetCurSurf_C2(RendSurf);
    }
    GetSurfView(&CurSurf_C2, &curView);
    curView.MinX = 1;
    curView.MinY = 1;
    SetSurfView(&CurSurf_C2, &curView);

    RenderViewCore(&dgCores[1], ListPtTree_C2, TreePts_C2);
}

void RenderWorker4C_3(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf_C3(srcBlurSurf16);
    } else {
        DgSetCurSurf_C3(RendSurf);
    }
    GetSurfView(&CurSurf_C3, &curView);
    curView.MaxX = 0;
    curView.MaxY = 0;
    SetSurfView(&CurSurf_C3, &curView);

    RenderViewCore(&dgCores[2], ListPtTree_C3, TreePts_C3);
}

void RenderWorker4C_4(void *, int wid) {
    DgView curView;

    if (highQRendering) {
        DgSetCurSurf_C4(srcBlurSurf16);
    } else {
        DgSetCurSurf_C4(RendSurf);
    }
    GetSurfView(&CurSurf_C4, &curView);
    curView.MinX = 1;
    curView.MaxY = 0;
    SetSurfView(&CurSurf_C4, &curView);

    RenderViewCore(&dgCores[3], ListPtTree_C4, TreePts_C4);
}

// common Render
void RenderViewCore(DGCORE *curCore, int *curListPtTree, PolyPt *curTreePts) {
    int *ptrFace = nullptr;
    int idx1 = 0, idx2 = 0, idx3 = 0, idx4 = 0;
    int i = 0, j = 0, quadCount = 0, iniIdx = 0;

    // render background sky if enabled
    if (skyBack) {
        curCore->DgSetSrcSurf(BackSky16);
        for (i = 0; i < skyCylinderYSplits; i++) {
            iniIdx = i * skyCylinderLevelVertCount;
            for (j = 0; j < skyCylinderCircleSplits; j++,quadCount++) {
                idx1 = iniIdx+j;
                idx2 = iniIdx+j+1;
                idx3 = iniIdx+j+1+skyCylinderLevelVertCount;
                idx4 = iniIdx+j+skyCylinderLevelVertCount;
                if (varraySkyCylinderProj[idx1].z > 0.1f && varraySkyCylinderProj[idx2].z > 0.1f && varraySkyCylinderProj[idx3].z > 0.1f && varraySkyCylinderProj[idx4].z > 0.1f) {
                    curCore->Poly16(&ListPtSkyCylinder[quadCount*5], NULL, POLY16_TEXT | POLY16_FLAG_DBL_SIDED, 0);
//  debug
//                    curCore->Line16(&varrayiSkyCylinder[idx1], &varrayiSkyCylinder[idx2], 0);
//                    curCore->Line16(&varrayiSkyCylinder[idx2], &varrayiSkyCylinder[idx3], 0);
//                    curCore->Line16(&varrayiSkyCylinder[idx3], &varrayiSkyCylinder[idx4], 0);
//                    curCore->Line16(&varrayiSkyCylinder[idx1], &varrayiSkyCylinder[idx4], 0);
                }
            }
        }
    }

    // render ground and casted shadow on it
    for (int idt = 0; idt < countDFaces; idt++) {
        ptrFace = dfaces[idt]->vface;
        if (ptrFace == nullptr || dfaces[idt]->countVertices == 0)
            continue;
        idx1 = ptrFace[1];
        idx2 = ptrFace[2];
        idx3 = ptrFace[3];

        // render face
        switch (ptrFace[0]) {
        case 3:
            if ((varrayRes[idx1].z > 0.1f && varrayRes[idx2].z > 0.1f && varrayRes[idx3].z > 0.1f))// &&
            {
                curListPtTree[0] = 3;
                curTreePts[0].x = varrayi[idx1].x; curTreePts[0].y = varrayi[idx1].y;
                curTreePts[1].x = varrayi[idx2].x; curTreePts[1].y = varrayi[idx2].y;
                curTreePts[2].x = varrayi[idx3].x; curTreePts[2].y = varrayi[idx3].y;
                if (!groundTextured) {
                    curCore->Poly16(curListPtTree, NULL, POLY16_SOLID, faceCol);
                    curTreePts[0].xt = vLightUPos[idx1];
                    curTreePts[0].yt = 0;
                    curTreePts[1].xt = vLightUPos[idx2];
                    curTreePts[1].yt = 0;
                    curTreePts[2].xt = vLightUPos[idx3];
                    curTreePts[2].yt = 0;
                    curCore->RePoly16(NULL, gouroudLightSurf, POLY16_TEXT_TRANS, 13);
                } else {
                    curTreePts[0].xt = varrayUVi[idx1].x; curTreePts[0].yt = varrayUVi[idx1].y;
                    curTreePts[1].xt = varrayUVi[idx2].x; curTreePts[1].yt = varrayUVi[idx2].y;
                    curTreePts[2].xt = varrayUVi[idx3].x; curTreePts[2].yt = varrayUVi[idx3].y;
                    curCore->Poly16(curListPtTree, Ground1Surf16, POLY16_TEXT, dfaces[idt]->rendCol);
                    curTreePts[0].xt = vLightUPos[idx1];
                    curTreePts[0].yt = 0;
                    curTreePts[1].xt = vLightUPos[idx2];
                    curTreePts[1].yt = 0;
                    curTreePts[2].xt = vLightUPos[idx3];
                    curTreePts[2].yt = 0;
                    curCore->RePoly16(NULL, gouroudLightSurf, POLY16_TEXT_TRANS, 13);
                }
                if (dfaces[idt]->shadowed) {
                    curTreePts[0].xt = dfaces[idt]->shadowUVi[0].x; curTreePts[0].yt = dfaces[idt]->shadowUVi[0].y;
                    curTreePts[1].xt = dfaces[idt]->shadowUVi[1].x; curTreePts[1].yt = dfaces[idt]->shadowUVi[1].y;
                    curTreePts[2].xt = dfaces[idt]->shadowUVi[2].x; curTreePts[2].yt = dfaces[idt]->shadowUVi[2].y;
                    curCore->RePoly16(curListPtTree, Tree2SurfShadE16, POLY16_MASK_TEXT_TRANS, 15);
                }
            }
            break;
        case 4:
            idx4 = ptrFace[4];
            if (varrayRes[idx1].z > 0.1f && varrayRes[idx2].z > 0.1f && varrayRes[idx3].z > 0.1f && varrayRes[idx4].z > 0.1f) // &&
            {
                curListPtTree[0] = 4;
                curTreePts[0].x = varrayi[idx1].x; curTreePts[0].y = varrayi[idx1].y;
                curTreePts[1].x = varrayi[idx2].x; curTreePts[1].y = varrayi[idx2].y;
                curTreePts[2].x = varrayi[idx3].x; curTreePts[2].y = varrayi[idx3].y;
                curTreePts[3].x = varrayi[idx4].x; curTreePts[3].y = varrayi[idx4].y;
                curCore->Poly16(curListPtTree, NULL, POLY16_SOLID, dfaces[idt]->rendCol);
            }
            break;
        }
    }
    // render Tree quad if not behind camera
    if (varrayTreeProj[0].z > 0.1f && varrayTreeProj[1].z > 0.1f && varrayTreeProj[2].z > 0.1f && varrayTreeProj[3].z > 0.1f) // &&
    {
        curCore->Poly16(&ListPtTree_C5, Tree2Surf16, POLY16_MASK_TEXT | POLY16_FLAG_DBL_SIDED, RGB16(255,0,0));
    }
}
// resize worker smooth to screen (HQ rendering)

void ResizeWorker1C_1(void *, int wid) {
    DgSetCurSurf(RendSurf);
    ResizeViewSurf16(blurSurf16, 0, 0);
}

// top, bottom
void ResizeWorker2C_1(void *, int wid) {
    DgSetCurSurf(RendSurf);
    CurSurf.MinY = 1;
    DgSetSrcSurf(blurSurf16);
    SrcSurf.MinY = 1;
    ResizeViewSurf16(NULL, 0, 0);
}

void ResizeWorker2C_2(void *, int wid) {
    DgSetCurSurf_C2(RendSurf);
    CurSurf_C2.MaxY = 0;
    DgSetSrcSurf_C2(blurSurf16);
    SrcSurf_C2.MaxY = 0;
    ResizeViewSurf16_C2(NULL, 0, 0);
}

// top, bottom (left, right)
void ResizeWorker4C_1(void *, int wid) {
    DgSetCurSurf(RendSurf);
    CurSurf.MinY = 1;
    CurSurf.MaxX = 0;
    DgSetSrcSurf(blurSurf16);
    SrcSurf.MinY = 1;
    SrcSurf.MaxX = 0;
    ResizeViewSurf16(NULL, 0, 0);
}

void ResizeWorker4C_2(void *, int wid) {
    DgSetCurSurf_C2(RendSurf);
    CurSurf_C2.MaxY = 0;
    CurSurf_C2.MaxX = 0;
    DgSetSrcSurf_C2(blurSurf16);
    SrcSurf_C2.MaxY = 0;
    SrcSurf_C2.MaxX = 0;
    ResizeViewSurf16_C2(NULL, 0, 0);
}

void ResizeWorker4C_3(void *, int wid) {
    DgSetCurSurf_C3(RendSurf);
    CurSurf_C3.MinY = 1;
    CurSurf_C3.MinX = 1;
    DgSetSrcSurf_C3(blurSurf16);
    SrcSurf_C3.MinY = 1;
    SrcSurf_C3.MinX = 1;
    ResizeViewSurf16_C3(NULL, 0, 0);
}

void ResizeWorker4C_4(void *, int wid) {
    DgSetCurSurf_C4(RendSurf);
    CurSurf_C4.MaxY = 0;
    CurSurf_C4.MinX = 1;
    DgSetSrcSurf_C4(blurSurf16);
    SrcSurf_C4.MaxY = 0;
    SrcSurf_C4.MinX = 1;
    ResizeViewSurf16_C4(NULL, 0, 0);
}

// alloc smooth DgSurf(s)
bool AllocSmoothSurfs() {
    DgSurf *newBlurSurf16 = NULL;
    DgSurf *newSrcBlurSurf16 = NULL;
    if (CreateSurf(&newBlurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        return false; // no mem
    }
    SetOrgSurf(newBlurSurf16,newBlurSurf16->ResH/2,newBlurSurf16->ResV/2);

    if (CreateSurf(&newSrcBlurSurf16, (int)(ScrResH*smoothSurfRatio)&0xfffffffe, (int)(ScrResV*smoothSurfRatio)&0xfffffffe, 16)==0) {
        DestroySurf(newBlurSurf16);
        return false; // no mem
    }
    SetOrgSurf(newSrcBlurSurf16,newSrcBlurSurf16->ResH/2,newSrcBlurSurf16->ResV/2);
    // destroy old Surfs and set new ones
    if (blurSurf16 != NULL)
        DestroySurf(blurSurf16);
    if (srcBlurSurf16 != NULL)
        DestroySurf(srcBlurSurf16);
    blurSurf16=newBlurSurf16;
    srcBlurSurf16=newSrcBlurSurf16;
    return true;
}

// sky cylinder geometry generation

void GenSkyCylinderGeometry() {
    int i = 0, j = 0, iniIdx = 0;
    int wStep = 0, hStep = 0;
    int levelYT = 0;
    int quadCount = 0;

    // loaded BackSky DgSurf is PREREQUISITE
    if (BackSky16 == NULL || skyCylinderCircleSplits < 1) {
        return;
    }

    // init cylinder geometry
    double radStep = (2.0 * M_PI) / (double) (skyCylinderCircleSplits);
    double radStart = 0.0;
    double YStep = skyCylinderHeight / (double) (skyCylinderYSplits);
    double YStart = skyCylinderYStart;

    for (i = 0; i < skyCylinderYSplits+1; i++) {
        radStart = 0.0;
        iniIdx = i * skyCylinderLevelVertCount;
        for (j = 0; j <skyCylinderCircleSplits+1; j++, radStart += radStep) {
            varraySkyCylinder[iniIdx + j].x = cos(radStart) * skyCylinderRay;
            varraySkyCylinder[iniIdx + j].y = YStart;
            varraySkyCylinder[iniIdx + j].z = sin(radStart) * skyCylinderRay;
        }
        YStart += YStep;
    }

    // init PolyPt array with xt,yt (or UV) inside BackSky16
    wStep = BackSky16->ResH / skyCylinderCircleSplits;
    hStep = BackSky16->ResV / skyCylinderYSplits;
    for (i = 0; i < skyCylinderYSplits+1; i++) {
        iniIdx = i * skyCylinderLevelVertCount;
        levelYT = (i < skyCylinderYSplits ) ? (hStep * i) : (BackSky16->ResV - 1);
        for (j = 0; j <skyCylinderCircleSplits+1; j++) {
            ListSkyCylinderPts[iniIdx + j].xt = ( j < skyCylinderCircleSplits) ? (j * wStep) : (BackSky16->ResH - 1);
            ListSkyCylinderPts[iniIdx + j].yt = levelYT;
        }
    }

    // init ListPts (Poly16 input)
    for (i = 0; i < skyCylinderYSplits; i++) {
        iniIdx = i * skyCylinderLevelVertCount;
        for (j = 0; j < skyCylinderCircleSplits; j++,quadCount++) {
            ListPtSkyCylinder[quadCount*5] = 4; // quad with 4 points
            ListPtSkyCylinder[quadCount*5+1] = (int)(&ListSkyCylinderPts[iniIdx+j]);
            ListPtSkyCylinder[quadCount*5+2] = (int)(&ListSkyCylinderPts[iniIdx+j+1]);
            ListPtSkyCylinder[quadCount*5+3] = (int)(&ListSkyCylinderPts[iniIdx+j+1+skyCylinderLevelVertCount]);
            ListPtSkyCylinder[quadCount*5+4] = (int)(&ListSkyCylinderPts[iniIdx+j+skyCylinderLevelVertCount]);
        }
    }

}
