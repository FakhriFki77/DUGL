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
%define DgSetCurSurf                DgSetCurSurf_C2
%define DgSetSrcSurf                DgSetSrcSurf_C2
%define DgGetCurSurf                DgGetCurSurf_C2
%define DgClear16                   DgClear16_C2
%define ClearSurf16                 ClearSurf16_C2
%define Bar16                       Bar16_C2
%define InBar16                     InBar16_C2
%define BarBlnd16                   BarBlnd16_C2
%define InBarBlnd16                 InBarBlnd16_C2
%define DgPutPixel16                DgPutPixel16_C2
%define DgCPutPixel16               DgCPutPixel16_C2
%define DgGetPixel16                DgGetPixel16_C2
%define DgCGetPixel16               DgCGetPixel16_C2

%define line16                      line16_C2
%define Line16                      Line16_C2
%define linemap16                   linemap16_C2
%define LineMap16                   LineMap16_C2
%define lineblnd16                  lineblnd16_C2
%define LineBlnd16                  LineBlnd16_C2
%define linemapblnd16               linemapblnd16_C2
%define LineMapBlnd16               LineMapBlnd16_C2
%define Poly16                      Poly16_C2
%define RePoly16                    RePoly16_C2
%define PutSurf16                   PutSurf16_C2
%define PutMaskSurf16               PutMaskSurf16_C2
%define PutSurfBlnd16               PutSurfBlnd16_C2
%define PutMaskSurfBlnd16           PutMaskSurfBlnd16_C2
%define PutSurfTrans16              PutSurfTrans16_C2
%define PutMaskSurfTrans16          PutMaskSurfTrans16_C2
%define ResizeViewSurf16            ResizeViewSurf16_C2
%define MaskResizeViewSurf16        MaskResizeViewSurf16_C2
%define TransResizeViewSurf16       TransResizeViewSurf16_C2
%define MaskTransResizeViewSurf16   MaskTransResizeViewSurf16_C2
%define BlndResizeViewSurf16        BlndResizeViewSurf16_C2
%define MaskBlndResizeViewSurf16    MaskBlndResizeViewSurf16_C2
%define SurfMaskCopyBlnd16          SurfMaskCopyBlnd16_C2
%define SurfMaskCopyTrans16         SurfMaskCopyTrans16_C2

; GLOBAL vars
%define CurSurf                     CurSurf_C2
%define SrcSurf                     SrcSurf_C2
%define TPolyAdDeb                  TPolyAdDeb_C2
%define TPolyAdFin                  TPolyAdFin_C2
%define TexXDeb                     TexXDeb_C2
%define TexXFin                     TexXFin_C2
%define TexYDeb                     TexYDeb_C2
%define TexYFin                     TexYFin_C2
%define PColDeb                     PColDeb_C2
%define PColFin                     PColFin_C2
%define DebYPoly                    DebYPoly_C2
%define FinYPoly                    FinYPoly_C2
%define PolyMaxY                    PolyMaxY_C2
%define PolyMinY                    PolyMinY_C2
%define LastPolyStatus              LastPolyStatus_C2
%define PolyCheckCorners            PolyCheckCorners_C2

%define vlfb                        vlfb_C2
%define rlfb                        rlfb_C2
%define ResH                        ResH_C2
%define ResV                        ResV_C2
%define MaxX                        MaxX_C2
%define MaxY                        MaxY_C2
%define MinX                        MinX_C2
%define MinY                        MinY_C2
%define OrgY                        OrgY_C2
%define OrgX                        OrgX_C2
%define SizeSurf                    SizeSurf_C2
%define OffVMem                     OffVMem_C2
%define BitsPixel                   BitsPixel_C2
%define ScanLine                    ScanLine_C2
%define Mask                        Mask_C2
%define NegScanLine                 NegScanLine_C2

; redefine FILLRET and some jumps as renaming fail to update them
%macro  @FILLRET_C2    0
    JMP Poly16_C2.PasDrawPoly
%endmacro


%define @FILLRET                    @FILLRET_C2
%define Line16.DoLine16             Line16_C2.DoLine16
%define LineMap16.DoLine16          LineMap16_C2.DoLine16
%define LineBlnd16.DoLine16         LineBlnd16_C2.DoLine16
%define LineMapBlnd16.DoLine16      LineMapBlnd16_C2.DoLine16
%define InBar16.CommonInBar16       InBar16_C2.CommonInBar16
%define InBar16.EndInBar            InBar16_C2.EndInBar
%define InBarBlnd16.EndInBarBlnd    InBarBlnd16_C2.EndInBarBlnd
%define InBarBlnd16.CommonInBar16   InBarBlnd16_C2.CommonInBar16
%define Poly16.PasDrawPoly          Poly16_C2.PasDrawPoly

%include "graph.asm"
