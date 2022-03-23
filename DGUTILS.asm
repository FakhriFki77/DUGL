;	Dust Ultimate Game Library (DUGL)
;   Copyright (C) 2022	Fakhri Feki
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
;    contact: libdugl@hotmail.com
;=============================================================================

; param ESI: source Surf, EDI: Dest Surf
; use mm0, ... , mm7
; return no : surf copied
%macro	CopySurf	0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
		MOVDQU		xmm0,[ESI]
		MOVDQU		xmm1,[ESI+32]
		MOVDQU		xmm2,[ESI+64]
		MOVDQU		xmm3,[ESI+16]
		MOVDQU		xmm4,[ESI+48]
		MOVDQU		xmm7,[ESI+80]

		MOVDQU		[EDI],xmm0
		MOVDQU		[EDI+32],xmm1
		MOVDQU		[EDI+64],xmm2
		MOVDQU		[EDI+16],xmm3
		MOVDQU		[EDI+48],xmm4
        MOVDQU		[EDI+80],xmm7
%%NoCopySurf:
%endmacro

%macro	CopySurfDA	0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
		MOVDQU		xmm0,[ESI]
		MOVDQU		xmm1,[ESI+32]
		MOVDQU		xmm2,[ESI+64]
		MOVDQU		xmm3,[ESI+16]
		MOVDQU		xmm4,[ESI+48]
		MOVDQU		xmm7,[ESI+80]

		MOVDQA		[EDI],xmm0
		MOVDQA		[EDI+32],xmm1
		MOVDQA		[EDI+64],xmm2
		MOVDQA		[EDI+16],xmm3
		MOVDQA		[EDI+48],xmm4
        MOVDQA		[EDI+80],xmm7
%%NoCopySurf:
%endmacro

%macro	CopySurfSA	0
        OR          ESI,ESI
        JZ          SHORT %%NoCopySurf
; SSE/SSE2
		MOVDQA		xmm0,[ESI]
		MOVDQA		xmm1,[ESI+32]
		MOVDQA		xmm2,[ESI+64]
		MOVDQA		xmm3,[ESI+16]
		MOVDQA		xmm4,[ESI+48]
		MOVDQA		xmm7,[ESI+80]

		MOVDQU		[EDI],xmm0
		MOVDQU		[EDI+32],xmm1
		MOVDQU		[EDI+64],xmm2
		MOVDQU		[EDI+16],xmm3
		MOVDQU		[EDI+48],xmm4
        MOVDQU		[EDI+80],xmm7
%%NoCopySurf:
%endmacro
