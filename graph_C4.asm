; Dust Ultimate Game Library (DUGL)
;   Copyright (C) 2023  Fakhri Feki
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.

;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.

;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <https://www.gnu.org/licenses/>.
;
;    contact: libdugl(at)hotmail.com
;=============================================================================


; rename global functions and vars to allow multi-core!
; GLOBAL Functions
%define DgSetCurSurf                DgSetCurSurf_C4
%define DgSetSrcSurf                DgSetSrcSurf_C4
%define DgGetCurSurf                DgGetCurSurf_C4
%define DgClear16                   DgClear16_C4
%define ClearSurf16                 ClearSurf16_C4
%define InBar16                     InBar16_C4
%define DgPutPixel16                DgPutPixel16_C4
%define DgCPutPixel16               DgCPutPixel16_C4
%define DgGetPixel16                DgGetPixel16_C4
%define DgCGetPixel16               DgCGetPixel16_C4

%define line16                      line16_C4
%define Line16                      Line16_C4
%define linemap16                   linemap16_C4
%define LineMap16                   LineMap16_C4
%define lineblnd16                  lineblnd16_C4
%define LineBlnd16                  LineBlnd16_C4
%define linemapblnd16               linemapblnd16_C4
%define LineMapBlnd16               LineMapBlnd16_C4
%define Poly16                      Poly16_C4
%define RePoly16                    RePoly16_C4
%define PutSurf16                   PutSurf16_C4
%define PutMaskSurf16               PutMaskSurf16_C4
%define PutSurfBlnd16               PutSurfBlnd16_C4
%define PutMaskSurfBlnd16           PutMaskSurfBlnd16_C4
%define PutSurfTrans16              PutSurfTrans16_C4
%define PutMaskSurfTrans16          PutMaskSurfTrans16_C4
%define ResizeViewSurf16            ResizeViewSurf16_C4
%define MaskResizeViewSurf16        MaskResizeViewSurf16_C4
%define TransResizeViewSurf16       TransResizeViewSurf16_C4
%define MaskTransResizeViewSurf16   MaskTransResizeViewSurf16_C4
%define BlndResizeViewSurf16        BlndResizeViewSurf16_C4
%define MaskBlndResizeViewSurf16    MaskBlndResizeViewSurf16_C4
%define SurfMaskCopyBlnd16          SurfMaskCopyBlnd16_C4
%define SurfMaskCopyTrans16         SurfMaskCopyTrans16_C4

; GLOBAL vars
%define CurSurf                     CurSurf_C4
%define SrcSurf                     SrcSurf_C4
%define TPolyAdDeb                  TPolyAdDeb_C4
%define TPolyAdFin                  TPolyAdFin_C4
%define TexXDeb                     TexXDeb_C4
%define TexXFin                     TexXFin_C4
%define TexYDeb                     TexYDeb_C4
%define TexYFin                     TexYFin_C4
%define PColDeb                     PColDeb_C4
%define PColFin                     PColFin_C4
%define DebYPoly                    DebYPoly_C4
%define FinYPoly                    FinYPoly_C4
%define LastPolyStatus              LastPolyStatus_C4

%define vlfb                        vlfb_C4
%define rlfb                        rlfb_C4
%define ResH                        ResH_C4
%define ResV                        ResV_C4
%define MaxX                        MaxX_C4
%define MaxY                        MaxY_C4
%define MinX                        MinX_C4
%define MinY                        MinY_C4
%define OrgY                        OrgY_C4
%define OrgX                        OrgX_C4
%define SizeSurf                    SizeSurf_C4
%define OffVMem                     OffVMem_C4
%define BitsPixel                   BitsPixel_C4
%define ScanLine                    ScanLine_C4
%define Mask                        Mask_C4
%define NegScanLine                 NegScanLine_C4

; redefine FILLRET and some jumps as renaming fail to update them
%macro  @FILLRET_C4    0
    JMP Poly16_C4.PasDrawPoly
%endmacro


%define @FILLRET                    @FILLRET_C4
%define Line16.DoLine16             Line16_C4.DoLine16
%define LineMap16.DoLine16          LineMap16_C4.DoLine16
%define LineBlnd16.DoLine16         LineBlnd16_C4.DoLine16
%define LineMapBlnd16.DoLine16      LineMapBlnd16_C4.DoLine16
%define InBar16.CommonInBar16       InBar16_C4.CommonInBar16
%define Poly16.PasDrawPoly          Poly16_C4.PasDrawPoly

%include "graph.asm"
