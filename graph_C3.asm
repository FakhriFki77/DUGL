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
%define DgSetCurSurf                DgSetCurSurf_C3
%define DgSetSrcSurf                DgSetSrcSurf_C3
%define DgGetCurSurf                DgGetCurSurf_C3
%define DgClear16                   DgClear16_C3
%define ClearSurf16                 ClearSurf16_C3
%define InBar16                     InBar16_C3
%define DgPutPixel16                DgPutPixel16_C3
%define DgCPutPixel16               DgCPutPixel16_C3
%define DgGetPixel16                DgGetPixel16_C3
%define DgCGetPixel16               DgCGetPixel16_C3

%define line16                      line16_C3
%define Line16                      Line16_C3
%define linemap16                   linemap16_C3
%define LineMap16                   LineMap16_C3
%define lineblnd16                  lineblnd16_C3
%define LineBlnd16                  LineBlnd16_C3
%define linemapblnd16               linemapblnd16_C3
%define LineMapBlnd16               LineMapBlnd16_C3
%define Poly16                      Poly16_C3
%define PutSurf16                   PutSurf16_C3
%define PutMaskSurf16               PutMaskSurf16_C3
%define PutSurfBlnd16               PutSurfBlnd16_C3
%define PutMaskSurfBlnd16           PutMaskSurfBlnd16_C3
%define PutSurfTrans16              PutSurfTrans16_C3
%define PutMaskSurfTrans16          PutMaskSurfTrans16_C3
%define ResizeViewSurf16            ResizeViewSurf16_C3
%define MaskResizeViewSurf16        MaskResizeViewSurf16_C3
%define TransResizeViewSurf16       TransResizeViewSurf16_C3
%define MaskTransResizeViewSurf16   MaskTransResizeViewSurf16_C3
%define BlndResizeViewSurf16        BlndResizeViewSurf16_C3
%define MaskBlndResizeViewSurf16    MaskBlndResizeViewSurf16_C3
%define SurfMaskCopyBlnd16          SurfMaskCopyBlnd16_C3
%define SurfMaskCopyTrans16         SurfMaskCopyTrans16_C3

; GLOBAL vars
%define CurSurf                     CurSurf_C3
%define SrcSurf                     SrcSurf_C3
%define TPolyAdDeb                  TPolyAdDeb_C3
%define TPolyAdFin                  TPolyAdFin_C3
%define TexXDeb                     TexXDeb_C3
%define TexXFin                     TexXFin_C3
%define TexYDeb                     TexYDeb_C3
%define TexYFin                     TexYFin_C3
%define PColDeb                     PColDeb_C3
%define PColFin                     PColFin_C3

%define vlfb                        vlfb_C3
%define rlfb                        rlfb_C3
%define ResH                        ResH_C3
%define ResV                        ResV_C3
%define MaxX                        MaxX_C3
%define MaxY                        MaxY_C3
%define MinX                        MinX_C3
%define MinY                        MinY_C3
%define OrgY                        OrgY_C3
%define OrgX                        OrgX_C3
%define SizeSurf                    SizeSurf_C3
%define OffVMem                     OffVMem_C3
%define BitsPixel                   BitsPixel_C3
%define ScanLine                    ScanLine_C3
%define Mask                        Mask_C3
%define NegScanLine                 NegScanLine_C3

; redefine FILLRET and some jumps as renaming fail to update them
%macro  @FILLRET_C3    0
    JMP Poly16_C3.PasDrawPoly
%endmacro


%define @FILLRET                    @FILLRET_C3
%define Line16.DoLine16             Line16_C3.DoLine16
%define LineMap16.DoLine16          LineMap16_C3.DoLine16
%define LineBlnd16.DoLine16         LineBlnd16_C3.DoLine16
%define LineMapBlnd16.DoLine16      LineMapBlnd16_C3.DoLine16
%define InBar16.CommonInBar16       InBar16_C3.CommonInBar16


%include "graph.asm"
