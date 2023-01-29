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



;********************************************************
; special fast hline for resize: EBP PNT X, ESI now SrcStartPtr (ESI = YT1, EBX = XT1), EDI = dest hline ptr
; used xmm: xmm0
;********************************************************
%macro  @InFastTextHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        DEC         ECX
        STOSW
        JZ          %%FinSHLine

        JMP         SHORT %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          SHORT %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:

;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7
        SUB         CX,BYTE 4
        MOVDQA      [EDI],xmm0
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        DEC         CL
%%LastB:
        STOSW
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************
; special fast hline for resize: EBP PNT X, ESI now SrcStartPtr (ESI = YT1, EBX = XT1), EDI = dest hline ptr
; used xmm: xmm0
;********************************************************
%macro  @InFastMaskTextHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JZ          SHORT %%NoPutBAv
        MOV         [EDI],AX
%%NoPutBAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine

        JMP         SHORT %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          SHORT %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ
        MOVQ        xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5

        MOVQ        [EDI],xmm3 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:

;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7

        MOVDQA      xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5
        SUB         CX,BYTE 4
        MOVDQA      [EDI],xmm3 ; write the 16 bytes

        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5
        MOVQ        [EDI],xmm3 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JZ          SHORT %%NoPutBAp
        MOV         [EDI],AX
%%NoPutBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
; special fast hline for resize: EBP PNT X, ESI now SrcStartPtr (ESI = YT1, EBX = XT1), EDI = dest hline ptr
; used xmm: xmm0
;********************************************************
%macro  @InFastTransTextHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX*2],0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ
        DEC         ECX
        PEXTRW      [EDI],xmm0,0
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine

        JMP         %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        MOVQ        xmm3,[EDI]
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        @TransBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:

;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7

        MOVDQA      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ
        SUB         CX,BYTE 4
        MOVDQA      [EDI],xmm0 ; write the 16 bytes

        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVQ        xmm3,[EDI]
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        @TransBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX*2],0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ
        DEC         CL
        PEXTRW      [EDI],xmm0,0
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************
; special fast hline for resize: EBP PNT X, ESI now SrcStartPtr (ESI = YT1, EBX = XT1), EDI = dest hline ptr
; used xmm: xmm0
;********************************************************
%macro  @TransBlndQ_QMulSrcBlend 0
        PAND        xmm0,[QBlue16Mask]
        PAND        xmm3,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        PAND        xmm4,[QGreen16Mask]
        PAND        xmm2,[QRed16Mask]
        PAND        xmm5,[QRed16Mask]
        PMULLW      xmm0,[QMulSrcBlend] ; [blend_src]
        PMULLW      xmm3,xmm6 ; [blend_dst]
        PSRLW       xmm2,5
        PSRLW       xmm5,5
        PMULLW      xmm4,xmm6 ; [blend_dst]
        PMULLW      xmm1,[QMulSrcBlend] ; [blend_src]
        PMULLW      xmm5,xmm6 ; [blend_dst]
        PMULLW      xmm2,[QMulSrcBlend] ; [blend_src]

        PADDW       xmm0,xmm3
        PADDW       xmm1,xmm4
        PADDW       xmm2,xmm5
        PSRLW       xmm0,5
        PSRLW       xmm1,5
        PAND        xmm2,[QRed16Mask]
        ;PAND       mm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        POR         xmm0,xmm2
        POR         xmm0,xmm1
%endmacro

%macro  @InFastMaskTransTextHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JE          .NoStBAv
        PINSRW      xmm3,[EDI],0
        MOVD        xmm0,EAX
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ_QMulSrcBlend
        PEXTRW      [EDI],xmm0,0
.NoStBAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine
        JMP         %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        MOVQ        xmm3,[EDI]
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        MOVQ        xmm7,xmm0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        MOVQ        xmm1,xmm7
        MOVQ        xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4
        MOVQ        [EDI],xmm7 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:

;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7

        MOVDQA      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm7,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        SUB         CX,BYTE 4

        MOVDQA      xmm1,xmm7
        MOVDQA      xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4
        MOVDQA      [EDI],xmm7 ; write the Masked 16 bytes

        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVQ        xmm3,[EDI]
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        MOVQ        xmm7,xmm0
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        MOVQ        xmm1,xmm7
        MOVQ        xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4
        MOVQ        [EDI],xmm7 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JE          .NoStBAp
        PINSRW      xmm3,[EDI],0
        MOVD        xmm0,EAX
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ_QMulSrcBlend
        PEXTRW      [EDI],xmm0,0
.NoStBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************
; special fast hline for resize: EBP PNT X, ESI now SrcStartPtr (ESI = YT1, EBX = XT1), EDI = dest hline ptr
; used xmm: xmm0
;********************************************************
%macro  @FastSolidTextBlndW 0
        MOVDQA      xmm2,xmm0 ; R
        PUNPCKLWD   xmm0,xmm0 ; G | B
        PAND        xmm2,xmm6; [_QRed16Mask]
        PAND        xmm0,[WBGR16Mask]
        PSRLW       xmm2,5
        PMULLW      xmm0,xmm7 ; * QMulSrcBlend
        PMULLW      xmm2,xmm7 ; * QMulSrcBlend
        PADDW       xmm0,[WBGR16Blend]
        PADDW       xmm2,xmm5 ; * QRed16Blend
        PSRLW       xmm0,5
        PAND        xmm2,xmm6 ; [_QRed16Mask]
        PAND        xmm0,[WBGR16Mask]

        PSHUFLW     xmm1,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        POR         xmm2,xmm0
        POR         xmm2,xmm1
%endmacro

%macro  @FastSolidTextBlndQ 0
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        PAND        xmm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        PAND        xmm2,xmm6 ; [_QRed16Mask]
        PMULLW      xmm0,xmm7 ; * QMulSrcBlend
        PSRLW       xmm2,5
        PMULLW      xmm1,xmm7
        PMULLW      xmm2,xmm7
        PADDW       xmm0,xmm3 ; * QBlue16Blend
        PADDW       xmm1,xmm4 ; * QGreen16Blend
        PADDW       xmm2,xmm5 ; * QRed16Blend
        PSRLW       xmm0,5
        PSRLW       xmm1,5
        PAND        xmm2,xmm6 ; [_QRed16Mask]
        ;PAND       mm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        POR         xmm0,xmm2
        POR         xmm0,xmm1
%endmacro


%macro  @InFastTextBlndHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        DEC         ECX
        PINSRW      xmm0,[ESI+EBX*2],0
        @FastSolidTextBlndW
        PEXTRW      [EDI],xmm2,0
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine
        JMP         SHORT %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ
        @FastSolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7
        SUB         CX,BYTE 4
        @FastSolidTextBlndQ
        TEST        CX,0xFFFC
        MOVDQA      [EDI],xmm0
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @FastSolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        DEC         CL
        PINSRW      xmm0,[ESI+EBX*2],0
        @FastSolidTextBlndW
        PEXTRW      [EDI],xmm2,0
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%FinSHLine:
%endmacro


%macro  @FastSolidTextBlndQ_QRed16Mask 0
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        PAND        xmm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        PAND        xmm2,[QRed16Mask]
        PMULLW      xmm0,xmm7 ; * QMulSrcBlend
        PSRLW       xmm2,5
        PMULLW      xmm1,xmm7
        PMULLW      xmm2,xmm7
        PADDW       xmm0,xmm3 ; * QBlue16Blend
        PADDW       xmm1,xmm4 ; * QGreen16Blend
        PADDW       xmm2,xmm5 ; * QRed16Blend
        PSRLW       xmm0,5
        PSRLW       xmm1,5
        PAND        xmm2,[QRed16Mask]
        ;PAND       mm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        POR         xmm0,xmm2
        POR         xmm0,xmm1
%endmacro

%macro  @FastSolidTextBlndW_QRed16Mask 0
        MOVDQA      xmm2,xmm0 ; R
        PUNPCKLWD   xmm0,xmm0 ; G | B
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]
        PSRLW       xmm2,5
        PMULLW      xmm0,xmm7 ; * QMulSrcBlend
        PMULLW      xmm2,xmm7 ; * QMulSrcBlend
        PADDW       xmm0,[WBGR16Blend]
        PADDW       xmm2,xmm5 ; * QRed16Blend
        PSRLW       xmm0,5
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]

        PSHUFLW     xmm1,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        POR         xmm2,xmm0
        POR         xmm2,xmm1
%endmacro


%macro  @InFastMaskTextBlndHLineDYZ16 0
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JE          %%NoDBAv
        MOVD        xmm0,EAX
        @FastSolidTextBlndW_QRed16Mask
        PEXTRW      [EDI],xmm2,0
%%NoDBAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine
        JMP         %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
        TEST        EDI, 8
        JZ          %%PasStQAv
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ
        MOVDQA      xmm6,xmm0
        @FastSolidTextBlndQ_QRed16Mask
        MOVQ        xmm1,[EDI]
        MOVDQA      xmm2,xmm6
        PCMPEQW     xmm2,[DQ16Mask]
        PCMPEQW     xmm6,[DQ16Mask]
        PANDN       xmm2,xmm0
        PAND        xmm1,xmm6
        POR         xmm2,xmm1
        MOVQ        [EDI],xmm2 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%PasStQAv:
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        SUB         CX,BYTE 4
        @AjAdDYZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX*2], 3
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7
        SUB         CX,BYTE 4
        MOVDQA      xmm6,xmm0
        @FastSolidTextBlndQ_QRed16Mask
        TEST        CX,0xFFFC
        MOVDQA      xmm1,[EDI]
        MOVDQA      xmm2,xmm6
        PCMPEQW     xmm2,[DQ16Mask]
        PCMPEQW     xmm6,[DQ16Mask]
        PANDN       xmm2,xmm0
        PAND        xmm1,xmm6
        POR         xmm2,xmm1
        MOVDQA      [EDI],xmm2 ; write the masked 16 bytes
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVDQA      xmm6,xmm0
        @FastSolidTextBlndQ_QRed16Mask
        MOVQ        xmm1,[EDI]
        MOVDQA      xmm2,xmm6
        PCMPEQW     xmm2,[DQ16Mask]
        PCMPEQW     xmm6,[DQ16Mask]
        PANDN       xmm2,xmm0
        PAND        xmm1,xmm6
        POR         xmm2,xmm1
        MOVQ        [EDI],xmm2 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JE          %%NoDBAp
        MOVD        xmm0,EAX
        @FastSolidTextBlndW_QRed16Mask
        PEXTRW      [EDI],xmm2,0
%%NoDBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%FinSHLine:
%endmacro

