/*  Dust Ultimate Game Library (DUGL)
    Copyright (C) 2023  Fakhri Feki

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

    contact: libdugl(at)hotmail.com    */

#ifndef DCORE_H_INCLUDED
#define DCORE_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

#define DUGL_VERSION_MAJOR      1
#define DUGL_VERSION_MINOR      0
#define DUGL_VERSION_TYPE       'r' // a alpha, b beta, r release
#define DUGL_VERSION_PATCH      1

typedef struct
{   int ScanLine;
    int rlfb;
    int OrgX, OrgY;
    int MaxX, MaxY, MinX, MinY;
    int Mask, ResH, ResV;
    int vlfb;
    int NegScanLine;
    int OffVMem;
    int BitsPixel;
    int SizeSurf;
} DgSurf;

typedef struct
{   int OrgX, OrgY;
    int MaxX, MaxY, MinX, MinY;
} DgView;

// DUGL Main global variables

extern DgSurf   *RendSurf; // main destination render
extern DgSurf   *RendFrontSurf; // currently displayed if double buffer enabled

extern DgSurf   CurSurf; // The Surf that graphic functions will render to as DgClear16, Line16, Poly16 ...
extern DgSurf   SrcSurf; // The source Surf used by graphic functions as Poly16, PutSurf16, ResizeViewSurf16 ..
extern char LastPolyStatus; // Last Rendered Poly Status: ='N' not rendered, ='C' clipped, ='I' In rendererd

extern unsigned char DgWindowFocused; // set to 1 if MainWindow get Focused, 0 else
extern unsigned char DgWindowFocusLost; // set to 1 if MainWindow lose Focus, 0 else
extern unsigned char DgWindowRequestClose; // set to 1 if MainWindow receive close request, 0 else. it's up to user to reset its value to 0 once set to 1
extern unsigned char DgWindowResized; // set to 1 if MainWindow has been resized, (user window resize, or toggle full screen event...). it's up to user to reset its value to 0 once set to 1

// init all ressources required to run DUGL
// return 1 if success 0 if fail
int DgInit();
// free all ressources allocated to run DUGL
void DgQuit();
// Get Last DUGL Errors ID, 0 if none
int DgGetLastErr();

// Init Main DUGL window
// for BitPixels only is 16 bpp
// return 1 if success 0 if fail
int DgInitMainWindow(const char *title, int ResHz, int ResVt, char BitsPixel);
// extended parameters
int DgInitMainWindowX(const char *title, int ResHz, int ResVt, char BitsPixel, int PosX, int PosY, bool FullScreen, bool Borderless, bool ResizeWin);
// Set MainWindow size
void DgSetMainWindowSize(int ResHz, int ResVt);
// Set MainWindow minimum size
void DgSetMainWindowMinSize(int minResHz, int minResVt);
// Set MainWindow maximum size
void DgSetMainWindowMaxSize(int maxResHz, int maxResVt);
// Get MainWindow size
void DgGetMainWindowSize(int *ResHz, int *ResVt);
// Get MainWindow minimum size
void DgGetMainWindowMinSize(int *minResHz, int *minResVt);
// Get MainWindow maximum size
void DgGetMainWindowMaxSize(int *maxResHz, int *maxResVt);

// events
typedef void (*DgWindowResizeCallBack)(int,int);
// Set MainWindow resize event call back, pass NULL to disable
// preresizeCallBack is called with old (w, h), resizeCallBack is called with new (w, h)
// if RendSurf and or RendFrontSurf are accessed by another thread a DMutex locked/unlocked by this thread is required
// to avoid concurrency problem, if this thread is very fast a boolean activating a Delay of 10msec with this mutex unlocked
// and setting the boolean to false to tell that the delay of 10 msec started
void DgSetMainWindowResizeCallBack(DgWindowResizeCallBack preresizeCallBack, DgWindowResizeCallBack resizeCallBack, PDMutex resizeMutex, bool *requestResizeMutex);
// Get MainWindow resize event call back, return NULL if disabled
DgWindowResizeCallBack GetMainWindowResizeCallBack();
// update window with contents of RendSurf, and swap RendFrontSurf and RendSurf
void DgUpdateWindow();
// toggle full screen
void DgToggleFullScreen(bool fullScreen);
// Full screen Enabled
bool DgIsFullScreen();
// Set/Get Preferred full screen resolution, refresh rate, set 0 DgWindow res, and current display refresh
void DgSetPreferredFullScreenMode(int width, int height, int refreshRate);
void DgGetPreferredFullScreenMode(int *width, int *height, int *refreshRate);
// Enumerate current window full display modes
// return count of display mode, and fill attributes of first display mode, if any
int DgGetFirstDisplayMode(int *width, int *height, int *bpp, int *refreshRate);
// return true, and fill Display mode attributes if any, else return false
bool DgGetNextDisplayMode(int *width, int *height, int *bpp, int *refreshRate);
// Check events
void DgCheckEvents();
// Set/Get Double buffers or screen swap when DgUpdateWindow is called
void DgSetEnabledDoubleBuff(bool dblBuffEnabled);
bool DgGetEnabledDoubleBuff();
// set window icone
void DgSetWindowIcone(DgSurf *S);

// DgSurf handling ========================

// Set Current DgSurf for rendering
void DgSetCurSurf(DgSurf *S);
// Get copy of CurSurf
void DgGetCurSurf(DgSurf *S);
// Set Source DgSurf
void DgSetSrcSurf(DgSurf *S);

// thread safe functions //////////////////
// Gets Max Height in pixels for a DgSurf used with SetCurSurf
int  GetMaxResVSetSurf();
// mix RGB components of src and dst color according to blndVal
// blndVal = 0 => srcCol, blndVal = 31 => dstCol, other value give intermediate
int BlndCol16(int srcCol16, int dslCol16, int blndVal);
// Set Origin of DgSurf
void SetOrgSurf(DgSurf *S,int newOrgX,int newOrgY);
// Create a DgSurf by allocating its buffer and initializing DgSurf, return new created DgSurf in *S
int CreateSurf(DgSurf **S, int ResHz, int ResVt, char BitsPixel);
// Destroy DgSurf created with CreateSurf
void DestroySurf(DgSurf *S);
// Create DgSurf from buffer
// return 1 if success 0 if fail, return new created DgSurf in *S if success
int CreateSurfBuff(DgSurf **S, int ResHz, int ResVt, char BitsPixel, void *Buff);

// View or (clipped area) handling ===========

// sets View port relatively to the new View Origin
void SetSurfView(DgSurf *S, DgView *V);
// sets View port according to the current origin (ignore View origin for faster operation when no requirement to change it)
void SetSurfViewBounds(DgSurf *S, DgView *V);
// sets View port clipped inside current DgSurf view port
void SetSurfInView(DgSurf *S, DgView *V);
// sets View port according to the current origin clipped inside current DgSurf view port
void SetSurfInViewBounds(DgSurf *S, DgView *V);
// get current Surf view port
void GetSurfView(DgSurf *S, DgView *V);

// Render functions ============================

void DgClear16(int col); // clear all the CurSurf
void ClearSurf16(int clrcol); // clear only current view port of CurSurf - use InBar16
// PutPixel
void DgPutPixel16(int x, int y, int col);
// View port clipped PutPixel
void DgCPutPixel16(int x, int y, int col);
// Get Pixel
unsigned int DgGetPixel16(int x, int y);
// View port clipped GetPixel, return 0xFFFFFFFF if clipped, else the pixel on the low word
unsigned int DgCGetPixel16(int x, int y);
// Clipped lines
void line16(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void lineblnd16(int X1,int Y1,int X2,int Y2,int LgCol);
void linemapblnd16(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void Line16(void *Point1,void *Point2,int col);
void LineMap16(void *Point1,void *Point2,int col,unsigned int Map);
void LineBlnd16(void *Point1,void *Point2,int col);
void LineMapBlnd16(void *Point1,void *Point2,int col,unsigned int Map);

void InBar16(int minX,int minY,int maxX,int maxY,int barCol); // fast filled rectangle with coordinates inside the current View (no checking or clipping)
void Bar16(void *Pt1,void *Pt2,int bcol);  // use InBar16 / clipped
void bar16(int x1,int y1,int x2,int y2,int bcol);  // use InBar16  / clipped
void InBarBlnd16(int minX,int minY,int maxX,int maxY,int blendCol); // fast filled transluent rectangle with coordinates inside the current View (no checking or clipping)
void BarBlnd16(void *Pt1,void *Pt2,int bcol);  // use InBarBlnd16  / clipped
void barblnd16(int x1,int y1,int x2,int y2,int bcol);  // use InBarBlnd16  / clipped
// draw empty rectangle
void rect16(int x1,int y1,int x2,int y2,int rcol);
void rectmap16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);
void rectblnd16(int x1,int y1,int x2,int y2,int rcol);
void rectmapblnd16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);

// brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
void SurfMaskCopyBlnd16(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
void SurfMaskCopyTrans16(DgSurf *S16Dst, DgSurf *S16Src,int trans);

// resize SSrcSurf into CurSurf taking account of source and destination Views
// call to those functions will change SrcSurf, SSrcSurf could be null if there is a valid SrcSurf
void ResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt); // fast resize source view => into dest view
void MaskResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt); // use SrcSurf::Mask to mask pixels
void TransResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // transparency 0->31 (31 completely opaq)
void MaskTransResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // Mask pixels with value Mask, transparency 0->31 (31 completely opaq)
void BlndResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
void MaskBlndResizeViewSurf16(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
// 16bpp Surf blitting functions
#define PUTSURF_NORM    0 // as it
#define PUTSURF_INV_HZ  1 // reversed horizontally
#define PUTSURF_INV_VT  2 // reversed vertically
// Blit the Source DgSurf into current DgSurf taking care of current views
void PutSurf16(DgSurf *S,int X,int Y,int PType);
void PutMaskSurf16(DgSurf *S,int X,int Y,int PType);
void PutSurfBlnd16(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutMaskSurfBlnd16(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutSurfTrans16(DgSurf *S,int X,int Y,int PType,int trans);
void PutMaskSurfTrans16(DgSurf *S,int X,int Y,int PType,int trans);

// *ListPt FORMAT : [int CountVertices]|[Ptr * Point1] .. [Ptr * Point(CountVertices)]
// Point FORMAT [int ScreenX][int ScreenY][int Z reserved][int U texture coordinate][int V texture coordinate]
// all TEXTURE Functions uses a simple affine texture interpolation mapping (not perspective corrected)
#define POLY16_SOLID            0
#define POLY16_TEXT             1
#define POLY16_MASK_TEXT        2
#define POLY16_TEXT_TRANS       10
#define POLY16_MASK_TEXT_TRANS  11
#define POLY16_RGB              12
#define POLY16_SOLID_BLND       13
#define POLY16_TEXT_BLND        14
#define POLY16_MASK_TEXT_BLND   15
#define POLY16_MAX_TYPE         15
#define POLY16_FLAG_DBL_SIDED   0x80000000
void Poly16(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);
// Redo the last rendered Poly16: *ListPt and DBL_SIDED FLAG are ignored in this call,
// user can update *SS, TypePoly, ColPoly and texture coordinates[U,V] using the same Point List pointers the Poly16 was called with
void RePoly16(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);


// thread safe functions /////////////////////////////////////////////////////////////////////

unsigned int DgSurfCGetPixel16(DgSurf *S, int x, int y);
void DgSurfCPutPixel16(DgSurf *S, int x, int y, int col);

// brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
void SurfCopy(DgSurf *Sdst,DgSurf *Ssrc);
void SurfMaskCopy16(DgSurf *Sdst,DgSurf *Ssrc);
void SurfCopyBlnd16(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
void SurfCopyTrans16(DgSurf *S16Dst, DgSurf *S16Src,int trans);


#ifdef __cplusplus
        }  // extern "C" {
#endif

// utils macro
#define RGB16(r,g,b) ((b>>3)|((g>>2)<<5)|((r>>3)<<11))

#endif // DCORE_H_INCLUDED
