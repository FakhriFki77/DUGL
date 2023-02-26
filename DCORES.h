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

#ifndef DCORE2_H_INCLUDED
#define DCORE2_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    DgSurf   *CurSurf; // Pointer to current render DgSurf
    DgSurf   *SrcSurf; // Pointer to current source DgSurf

    // DgSurf handling functions ============================

    void (*DgSetCurSurf)(DgSurf *S);
    void (*DgGetCurSurf)(DgSurf *S);
    void (*DgSetSrcSurf)(DgSurf *S);

    // Render functions ======================================

    void (*DgClear16)(int col); // clear all the CurSurf
    void (*ClearSurf16)(int clrcol); // clear only current view port of CurSurf - use InBar16
    void (*DgPutPixel16)(int x, int y, int col);
    void (*DgCPutPixel16)(int x, int y, int col);
    unsigned int (*DgGetPixel16)(int x, int y);
    unsigned int (*DgCGetPixel16)(int x, int y);
    // Clipped lines
    void (*line16)(int X1,int Y1,int X2,int Y2,int LgCol);
    void (*linemap16)(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
    void (*lineblnd16)(int X1,int Y1,int X2,int Y2,int LgCol);
    void (*linemapblnd16)(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
    void (*Line16)(void *Point1,void *Point2,int col);
    void (*LineMap16)(void *Point1,void *Point2,int col,unsigned int Map);
    void (*LineBlnd16)(void *Point1,void *Point2,int col);
    void (*LineMapBlnd16)(void *Point1,void *Point2,int col,unsigned int Map);

    void (*InBar16)(int minX,int minY,int maxX,int maxY,int rectCcol);

    // brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
    void (*SurfMaskCopyBlnd16)(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
    void (*SurfMaskCopyTrans16)(DgSurf *S16Dst, DgSurf *S16Src,int trans);

    // resize SSrcSurf into CurSurf taking account of source and destination Views
    void (*ResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt);
    void (*MaskResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt);
    void (*TransResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency);
    void (*MaskTransResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency);
    void (*BlndResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd);
    void (*MaskBlndResizeViewSurf16)(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd);
    // 16bpp Surf blitting functions
    void (*PutSurf16)(DgSurf *S,int X,int Y,int PType);
    void (*PutMaskSurf16)(DgSurf *S,int X,int Y,int PType);
    void (*PutSurfBlnd16)(DgSurf *S,int X,int Y,int PType,int colBlnd);
    void (*PutMaskSurfBlnd16)(DgSurf *S,int X,int Y,int PType,int colBlnd);
    void (*PutSurfTrans16)(DgSurf *S,int X,int Y,int PType,int trans);
    void (*PutMaskSurfTrans16)(DgSurf *S,int X,int Y,int PType,int trans);

    void (*Poly16)(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);

} DGCORE;

// DGCORE Handling function

#define DGCORES_COUNT   4

// fill dgCore struct by pointers to asked core index: from 0 to (DGCORES_COUNT - 1)
bool GetDGCORE(DGCORE *dgCore, int idxDgCore);

// DUGL CORE 2 //////////////////////////////////////////////////////////////////////////////////////////////////////////

// DUGL Core2 Main global variables

extern DgSurf   CurSurf_C2; // The Surf that graphic functions will render to as DgClear16_C2, Line16_C2, Poly16_C2 ...
extern DgSurf   SrcSurf_C2; // The source Surf used by graphic functions as Poly16_C2, PutSurf16_C2, ResizeViewSurf16_C2 ..

// DgSurf handling ========================

// Set Current DgSurf for rendering
void DgSetCurSurf_C2(DgSurf *S);
// Get copy of CurSurf
void DgGetCurSurf_C2(DgSurf *S);
// Set Source DgSurf
void DgSetSrcSurf_C2(DgSurf *S);


// Render functions ============================

void DgClear16_C2(int col); // clear all the CurSurf
void ClearSurf16_C2(int clrcol); // clear only current view port of CurSurf - use InBar16
// PutPixel
void DgPutPixel16_C2(int x, int y, int col);
// View port clipped PutPixel
void DgCPutPixel16_C2(int x, int y, int col);
// Get Pixel
unsigned int DgGetPixel16_C2(int x, int y);
// View port clipped GetPixel, return 0xFFFFFFFF if clipped, else the pixel on the low word
unsigned int DgCGetPixel16_C2(int x, int y);
// Clipped lines
void line16_C2(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap16_C2(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void lineblnd16_C2(int X1,int Y1,int X2,int Y2,int LgCol);
void linemapblnd16_C2(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void Line16_C2(void *Point1,void *Point2,int col);
void LineMap16_C2(void *Point1,void *Point2,int col,unsigned int Map);
void LineBlnd16_C2(void *Point1,void *Point2,int col);
void LineMapBlnd16_C2(void *Point1,void *Point2,int col,unsigned int Map);

void InBar16_C2(int minX,int minY,int maxX,int maxY,int rectCcol); // fast filled rectangle with coordinates inside the current View (no checking or clipping)

// brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
void SurfMaskCopyBlnd16_C2(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
void SurfMaskCopyTrans16_C2(DgSurf *S16Dst, DgSurf *S16Src,int trans);

// resize SSrcSurf into CurSurf taking account of source and destination Views
// call to those functions will change SrcSurf, SSrcSurf could be null if there is a valid SrcSurf
void ResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt); // fast resize source view => into dest view
void MaskResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt); // use SrcSurf::Mask to mask pixels
void TransResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // transparency 0->31 (31 completely opaq)
void MaskTransResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // Mask pixels with value Mask, transparency 0->31 (31 completely opaq)
void BlndResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
void MaskBlndResizeViewSurf16_C2(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
// 16bpp Surf blitting functions
// Blit the Source DgSurf into current DgSurf taking care of current views
void PutSurf16_C2(DgSurf *S,int X,int Y,int PType);
void PutMaskSurf16_C2(DgSurf *S,int X,int Y,int PType);
void PutSurfBlnd16_C2(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutMaskSurfBlnd16_C2(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutSurfTrans16_C2(DgSurf *S,int X,int Y,int PType,int trans);
void PutMaskSurfTrans16_C2(DgSurf *S,int X,int Y,int PType,int trans);

// *ListPt FORMAT : [int CountVertices]|[Ptr * Point1] .. [Ptr * Point(CountVertices)]
// Point FORMAT [int ScreenX][int ScreenY][int Z reserved][int U texture coordinate][int V texture coordinate]
// all TEXTURE Functions uses a simple affine texture interpolation mapping (not perspective corrected)
void Poly16_C2(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);

// DUGL CORE 3 //////////////////////////////////////////////////////////////////////////////////////////////////////////

// DUGL Core3 Main global variables

extern DgSurf   CurSurf_C3; // The Surf that graphic functions will render to as DgClear16_C3, Line16_C3, Poly16_C3 ...
extern DgSurf   SrcSurf_C3; // The source Surf used by graphic functions as Poly16_C3, PutSurf16_C3, ResizeViewSurf16_C3 ..

// DgSurf handling ========================

// Set Current DgSurf for rendering
void DgSetCurSurf_C3(DgSurf *S);
// Get copy of CurSurf
void DgGetCurSurf_C3(DgSurf *S);
// Set Source DgSurf
void DgSetSrcSurf_C3(DgSurf *S);


// Render functions ============================

void DgClear16_C3(int col); // clear all the CurSurf
void ClearSurf16_C3(int clrcol); // clear only current view port of CurSurf - use InBar16
// PutPixel
void DgPutPixel16_C3(int x, int y, int col);
// View port clipped PutPixel
void DgCPutPixel16_C3(int x, int y, int col);
// Get Pixel
unsigned int DgGetPixel16_C3(int x, int y);
// View port clipped GetPixel, return 0xFFFFFFFF if clipped, else the pixel on the low word
unsigned int DgCGetPixel16_C3(int x, int y);
// Clipped lines
void line16_C3(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap16_C3(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void lineblnd16_C3(int X1,int Y1,int X2,int Y2,int LgCol);
void linemapblnd16_C3(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void Line16_C3(void *Point1,void *Point2,int col);
void LineMap16_C3(void *Point1,void *Point2,int col,unsigned int Map);
void LineBlnd16_C3(void *Point1,void *Point2,int col);
void LineMapBlnd16_C3(void *Point1,void *Point2,int col,unsigned int Map);

void InBar16_C3(int minX,int minY,int maxX,int maxY,int rectCcol); // fast filled rectangle with coordinates inside the current View (no checking or clipping)

// brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
void SurfMaskCopyBlnd16_C3(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
void SurfMaskCopyTrans16_C3(DgSurf *S16Dst, DgSurf *S16Src,int trans);

// resize SSrcSurf into CurSurf taking account of source and destination Views
// call to those functions will change SrcSurf, SSrcSurf could be null if there is a valid SrcSurf
void ResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt); // fast resize source view => into dest view
void MaskResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt); // use SrcSurf::Mask to mask pixels
void TransResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // transparency 0->31 (31 completely opaq)
void MaskTransResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // Mask pixels with value Mask, transparency 0->31 (31 completely opaq)
void BlndResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
void MaskBlndResizeViewSurf16_C3(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
// 16bpp Surf blitting functions
void PutSurf16_C3(DgSurf *S,int X,int Y,int PType);
void PutMaskSurf16_C3(DgSurf *S,int X,int Y,int PType);
void PutSurfBlnd16_C3(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutMaskSurfBlnd16_C3(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutSurfTrans16_C3(DgSurf *S,int X,int Y,int PType,int trans);
void PutMaskSurfTrans16_C3(DgSurf *S,int X,int Y,int PType,int trans);

// *ListPt FORMAT : [int CountVertices]|[Ptr * Point1] .. [Ptr * Point(CountVertices)]
// Point FORMAT [int ScreenX][int ScreenY][int Z reserved][int U texture coordinate][int V texture coordinate]
// all TEXTURE Functions uses a simple affine texture interpolation mapping (not perspective corrected)
void Poly16_C3(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);

// DUGL CORE 4 //////////////////////////////////////////////////////////////////////////////////////////////////////////

// DUGL Core4 Main global variables

extern DgSurf   CurSurf_C4; // The Surf that graphic functions will render to as DgClear16_C4, Line16_C4, Poly16_C4 ...
extern DgSurf   SrcSurf_C4; // The source Surf used by graphic functions as Poly16_C4, PutSurf16_C4, ResizeViewSurf16_C4 ..

// DgSurf handling ========================

// Set Current DgSurf for rendering
void DgSetCurSurf_C4(DgSurf *S);
// Get copy of CurSurf
void DgGetCurSurf_C4(DgSurf *S);
// Set Source DgSurf
void DgSetSrcSurf_C4(DgSurf *S);


// Render functions ============================

void DgClear16_C4(int col); // clear all the CurSurf
void ClearSurf16_C4(int clrcol); // clear only current view port of CurSurf - use InBar16
// PutPixel
void DgPutPixel16_C4(int x, int y, int col);
// View port clipped PutPixel
void DgCPutPixel16_C4(int x, int y, int col);
// Get Pixel
unsigned int DgGetPixel16_C4(int x, int y);
// View port clipped GetPixel, return 0xFFFFFFFF if clipped, else the pixel on the low word
unsigned int DgCGetPixel16_C4(int x, int y);
// Clipped lines
void line16_C4(int X1,int Y1,int X2,int Y2,int LgCol);
void linemap16_C4(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void lineblnd16_C4(int X1,int Y1,int X2,int Y2,int LgCol);
void linemapblnd16_C4(int X1,int Y1,int X2,int Y2,int LgCol,unsigned int Map);
void Line16_C4(void *Point1,void *Point2,int col);
void LineMap16_C4(void *Point1,void *Point2,int col,unsigned int Map);
void LineBlnd16_C4(void *Point1,void *Point2,int col);
void LineMapBlnd16_C4(void *Point1,void *Point2,int col,unsigned int Map);

void InBar16_C4(int minX,int minY,int maxX,int maxY,int rectCcol); // fast filled rectangle with coordinates inside the current View (no checking or clipping)

// brute copy pixels data from DgSurf src to dst without any verification of BitsPixel or size
void SurfMaskCopyBlnd16_C4(DgSurf *S16Dst, DgSurf *S16Src,int colBlnd);
void SurfMaskCopyTrans16_C4(DgSurf *S16Dst, DgSurf *S16Src,int trans);

// resize SSrcSurf into CurSurf taking account of source and destination Views
// call to those functions will change SrcSurf, SSrcSurf could be null if there is a valid SrcSurf
void ResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt); // fast resize source view => into dest view
void MaskResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt); // use SrcSurf::Mask to mask pixels
void TransResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // transparency 0->31 (31 completely opaq)
void MaskTransResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt, int transparency); // Mask pixels with value Mask, transparency 0->31 (31 completely opaq)
void BlndResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
void MaskBlndResizeViewSurf16_C4(DgSurf *SSrcSurf, int swapHz, int swapVt, int colBlnd); // ColBnd =  color16 | (blend << 24),  blend 0->31 (31 color16)
// 16bpp Surf blitting functions
// Blit the Source DgSurf into current DgSurf taking care of current views
void PutSurf16_C4(DgSurf *S,int X,int Y,int PType);
void PutMaskSurf16_C4(DgSurf *S,int X,int Y,int PType);
void PutSurfBlnd16_C4(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutMaskSurfBlnd16_C4(DgSurf *S,int X,int Y,int PType,int colBlnd);
void PutSurfTrans16_C4(DgSurf *S,int X,int Y,int PType,int trans);
void PutMaskSurfTrans16_C4(DgSurf *S,int X,int Y,int PType,int trans);

// *ListPt FORMAT : [int CountVertices]|[Ptr * Point1] .. [Ptr * Point(CountVertices)]
// Point FORMAT [int ScreenX][int ScreenY][int Z reserved][int U texture coordinate][int V texture coordinate]
// all TEXTURE Functions uses a simple affine texture interpolation mapping (not perspective corrected)
void Poly16_C4(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);


#ifdef __cplusplus
        }  // extern "C" {
#endif


#endif // DCORE2_H_INCLUDED

