;   Dust Ultimate Game Library (DUGL)
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

        struc DuglSurf
.ScanLine           RESD  1
.rlfb               RESD  1
.OrgX               RESD  1
.OrgY               RESD  1
.MaxX               RESD  1
.MaxY               RESD  1
.MinX               RESD  1
.MinY               RESD  1;-----------------------
.Mask               RESD  1
.ResH               RESD  1
.ResV               RESD  1
.vlfb               RESD  1
.NegScanLine        RESD  1
.OffVMem            RESD  1
.BitsPixel          RESD  1
.SizeSurf           RESD  1;-----------------------
.Size:
        endstruc

; constants

Prec                EQU 12
MaxResV             EQU 4096
BlendMask           EQU 0x1f
CMaskB_RGB16        EQU 0x1f   ; blue bits 0->4
CMaskG_RGB16        EQU 0x3f<<5  ; green bits 5->10
CMaskR_RGB16        EQU 0x1f<<11 ; red bits 11->15


; param ESI: source Surf, EDI: Dest Surf
; use mm0, ... , mm3
; return no : surf copied

%macro  CopySurfDA  0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
        MOVDQA      xmm0,[ESI]
        MOVDQA      xmm1,[ESI+32]
        MOVDQA      xmm2,[ESI+16]
        MOVDQA      xmm3,[ESI+48]

        MOVDQA      [EDI],xmm0
        MOVDQA      [EDI+32],xmm1
        MOVDQA      [EDI+16],xmm2
        MOVDQA      [EDI+48],xmm3
%%NoCopySurf:
%endmacro

%macro  CopySurfSA  0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
        MOVDQA      xmm0,[ESI]
        MOVDQA      xmm1,[ESI+32]
        MOVDQA      xmm2,[ESI+16]
        MOVDQA      xmm3,[ESI+48]

        MOVDQU      [EDI],xmm0
        MOVDQU      [EDI+32],xmm1
        MOVDQU      [EDI+16],xmm2
        MOVDQU      [EDI+48],xmm3
%%NoCopySurf:
%endmacro

%macro  CopySurfSNA 0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
        MOVDQU      xmm0,[ESI]
        MOVDQU      xmm1,[ESI+32]
        MOVDQU      xmm2,[ESI+16]
        MOVDQU      xmm3,[ESI+48]

        MOVDQA      [EDI],xmm0
        MOVDQA      [EDI+32],xmm1
        MOVDQA      [EDI+16],xmm2
        MOVDQA      [EDI+48],xmm3
%%NoCopySurf:
%endmacro
