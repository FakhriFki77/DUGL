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
// draw empty rectangle
void rect16_C2(int x1,int y1,int x2,int y2,int rcol);
void rectmap16_C2(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);
void rectblnd16_C2(int x1,int y1,int x2,int y2,int rcol);
void rectmapblnd16_C2(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap);

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
#define PUTSURF_NORM    0 // as it
#define PUTSURF_INV_HZ  1 // reversed horizontally
#define PUTSURF_INV_VT  2 // reversed vertically
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
void Poly16_C2(void *ListPt, DgSurf *SS, unsigned int TypePoly, int ColPoly);

#ifdef __cplusplus
        }  // extern "C" {
#endif


#endif // DCORE2_H_INCLUDED

