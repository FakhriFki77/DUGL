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

%include "PARAM.asm"

; enable windows/linux win32/elf32 building
%pragma elf32 gprefix
%pragma win32 gprefix   _

; GLOBAL Function*************************************************************
GLOBAL Blur16, ConvB8ToB16Pal

; EXTERN GLOBAL VARS
EXTERN QBlue16Mask, QGreen16Mask, QRed16Mask

SECTION .text
ALIGN 32
[BITS 32]

; convert a 8bpp paletted buffer to 16bpp (5:6:5:rgb) buffer
ConvB8ToB16Pal:
    ARG    PC816BuffImgSrc, 4, PC816BuffImgDst, 4, PC816ImgResHz, 4, PC816ImgResVt, 4, PC816SrcPal, 4

        PUSH        ESI
        PUSH        EDI
        PUSH        EBX

        ; valid params ?
        MOV         ESI,[EBP+PC816BuffImgSrc]
        MOV         ECX,[EBP+PC816ImgResVt]
        MOV         EDI,[EBP+PC816BuffImgDst]
        IMUL        ECX,[EBP+PC816ImgResHz]
        MOV         EBX,[EBP+PC816SrcPal]
        JECXZ       .errorEnd
        MOV         EBP,ECX
        MOVD        xmm4,ECX ; or EBP
        SHR         EBP,1
        XOR         ECX,ECX

.loop8To16B:
        MOV         CL,BYTE [ESI]
        MOV         EAX,[EBX+ECX*4]
        SHR         AH,2
        MOV         CL,BYTE [ESI+1] ; -
        ROR         EAX,3+11
        MOV         EDX,[EBX+ECX*4] ; -
        SHR         AX,3+2
        SHR         DH,2 ; -
        ROL         EAX,11
        ROR         EDX,3+11 ; -
        AND         EAX,0xFFFF
        SHR         DX,3+2 ; -
        ROL         EDX,11
        SHL         EDX,16
        OR          EAX,EDX

        ADD         ESI,BYTE 2
        MOV         [EDI],EAX
        DEC         EBP
        LEA         EDI,[EDI+4]
        JNZ         .loop8To16B

        MOVD        EBP,xmm4
        AND         EBP,BYTE 1
        JZ          .errorEnd

        MOV         CL,BYTE [ESI]
        MOV         EAX,[EBX+ECX*4]
        SHR         AH,2
        ROR         EAX,3+11
        SHR         AX,3+2
        ROL         EAX,11
        MOV         [EDI],AX
.errorEnd:

        POP         EBX
        POP         EDI
        POP         ESI

    RETURN


; ///////////////////
; BLUR //////////////

; param ESI: source, EBX: source ResH
; use EAX,EDX,EDI
; return EAX AVG 4 point ESI,ESI+2, ESI+ResH*2,ESI+ResH*2+2
%macro  AVG_4   2  ; %0 bit pos, %1 number of bits to take
        MOVZX       EAX,WORD [ESI]
        MOVZX       EDX,WORD [ESI+2]
        MOVZX       EDI,WORD [ESI+EBX*2]
        %if %1>0
        SHR         EAX,%1
        SHR         EDX,%1
        SHR         EDI,%1
        %endif
        AND         EAX,BYTE (1<<%2)-1
        AND         EDX,BYTE (1<<%2)-1
        AND         EDI,BYTE (1<<%2)-1
        ADD         EAX,EDX
        ADD         EAX,EDI
        MOVZX       EDX,WORD [ESI+EBX*2+2]
        %if %1>0
        SHR         EDX,%1
        %endif
        AND         EDX,BYTE (1<<%2)-1
        ADD         EAX,EDX
        SHR         EAX,2 ; EAX~=EAX/4
%endmacro


; param ESI: source, EBX: source ResH
; use EAX,EDX,EDI
; return EAX AVG 6 points vertical
%macro  AVG_6V 2  ; %0 bit pos, %1 number of bits to take
        MOVZX       EDI,WORD [ESI+EBX*2]
        MOVZX       EAX,WORD [ESI]
        MOVZX       EDX,WORD [ESI+2]
        %if %1>0
        SHR         EDI,%1
        SHR         EAX,%1
        SHR         EDX,%1
        %endif
        AND         EDI,BYTE (1<<%2)-1
        AND         EAX,BYTE (1<<%2)-1
        AND         EDX,BYTE (1<<%2)-1
        LEA         EDI,[EDI*3]
        ADD         EAX,EDX
        ADD         EAX,EDI
        MOVZX       EDX,WORD [ESI+EBX*2+2]
        MOVZX       EDI,WORD [ESI+EBX*4]
        %if %1>0
        SHR         EDX,%1
        SHR         EDI,%1
        %endif
        AND         EDX,BYTE (1<<%2)-1
        AND         EDI,BYTE (1<<%2)-1
        ADD         EAX,EDX
        ADD         EAX,EDI
        MOVZX       EDX,WORD [ESI+EBX*4+2]
        %if %1>0
        SHR         EDX,%1
        %endif
        AND         EDX,BYTE (1<<%2)-1
        ADD         EAX,EDX
        SHR         EAX,3 ; EAX~=EAX/6
%endmacro

%macro  AVG_6VLast 2  ; %0 bit pos, %1 number of bits to take
        MOVZX       EDI,WORD [ESI+EBX*2+2]
        MOVZX       EAX,WORD [ESI]
        MOVZX       EDX,WORD [ESI+2]
        %if %1>0
        SHR         EDI,%1
        SHR         EAX,%1
        SHR         EDX,%1
        %endif
        AND         EDI,BYTE (1<<%2)-1
        AND         EAX,BYTE (1<<%2)-1
        AND         EDX,BYTE (1<<%2)-1
        LEA         EDI,[EDI*3]
        ADD         EAX,EDX
        ADD         EAX,EDI
        MOVZX       EDX,WORD [ESI+EBX*2]
        MOVZX       EDI,WORD [ESI+EBX*4]
        %if %1>0
        SHR         EDX,%1
        SHR         EDI,%1
        %endif
        AND         EDX,BYTE (1<<%2)-1
        AND         EDI,BYTE (1<<%2)-1
        ADD         EAX,EDX
        ADD         EAX,EDI
        MOVZX       EDX,WORD [ESI+EBX*4+2]
        %if %1>0
        SHR         EDX,%1
        %endif
        AND         EDX,BYTE (1<<%2)-1
        ADD         EAX,EDX
        SHR         EAX,3 ; EAX~=EAX/6
%endmacro

Blur16:
    ARG    PB16BuffImgDst, 4, PB16BuffImgSrc, 4, PB16ImgResHz, 4, PB16ImgResVt, 4, PB16StartLine, 4, PB16EndLine, 4

        PUSH        ESI
        PUSH        EDI
        PUSH        EBX

        ; valid params ?
        MOV         ECX,[EBP+PB16StartLine]
        MOV         EDX,[EBP+PB16EndLine]
        MOV         ESI,[EBP+PB16BuffImgSrc]
        MOV         EDI,[EBP+PB16BuffImgDst]
        MOV         EBX,[EBP+PB16ImgResHz]
        MOV         EBP,[EBP+PB16ImgResVt]
        ; full Blur Test1

        XOR         EAX,EAX
        CMP         ECX,EDX
        JGE         .errorEnd ; do not handle single line blur or reversed indexes
        OR          ECX,ECX
        LEA         EDX,[EDX+1]
        JZ          .TestFullEnd
        CMP         EDX,EBP
        JG          .errorEnd ; invalid EndLine index
        SUB         EDX,EBP
        DEC         ECX
        SUB         EBP,ECX
        IMUL        ECX,EBX
        MOV         AL,1 ; (AL == 1) ==> ignore/jump first line
        LEA         EDI,[EDI+ECX*2]
        LEA         ESI,[ESI+ECX*2]
        LEA         EDI,[EDI+EBX*2]
        OR          EDX,EDX
        JZ          .FullBlur
        LEA         EBP,[EBP+EDX+1]
        MOV         AH,1
        JMP         .FullBlur
.TestFullEnd:
        CMP         EDX,EBP
        JE          .FullBlur
        JG          .errorEnd ; invalid EndLine index
        MOV         AH,1 ; (AH == 1) ==> ignore/jump last line
        LEA         EBP,[EDX+1]
.FullBlur:
        PUSH        EAX

        MOVD        xmm3,EDI ; xmm3, EDI
        MOVD        xmm4,[DQAdd2] ; xmm4 EDI step +2

; BLUR first Horizontal Line ---------------------------------------------
; all params ok :)
        CMP         AL,1
        JE          .EndFirstLine
; first pixel line 1 -------------------------------------
        AVG_4       5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_4       0,5 ; red AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_4       11,5 ; blue comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        OR          EAX,EDX
        MOVD        EDI,xmm3
        MOV         [EDI],AX
        PADDD       xmm3,xmm4 ; EDI += 2
; first line loop ----------------------------------

        LEA         ECX,[EBX-2]
        PUSH        ESI ; save BuffImgSrc
.loopLine1:
        ; first pixel =============================
        MOVQ        xmm0,[ESI]
        MOVQ        xmm1,[ESI+EBX*2]

        MOVDQ2Q     mm0,xmm0
        MOVDQ2Q     mm3,xmm0
        MOVDQ2Q     mm1,xmm1
        MOVDQ2Q     mm4,xmm1

        PAND        xmm0,[QBlue16Mask]
        PAND        xmm1,[QBlue16Mask]
        PAND        mm0,[QGreen16Mask]
        PAND        mm1,[QGreen16Mask]
        PAND        mm3,[QRed16Mask]
        PAND        mm4,[QRed16Mask]
        PSRLW       mm3,3
        PSRLW       mm4,3
        MOVDQA      xmm2,xmm0 ; save first  B
        MOVQ        mm2,mm0   ; save first G
        MOVQ        mm5,mm3   ; save first R

        PMULLW      xmm2, [QMul3SecondW]
        PMULLW      mm2, [QMul3SecondW]
        PMULLW      mm5, [QMul3SecondW]

        PADDW       xmm2, xmm1 ; = SUM 2 lines B
        PADDW       mm2, mm1 ; = SUM 2 lines G
        PADDW       mm5, mm4; = SUM 2 lines R

        PSHUFLW     xmm6,xmm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm6,mm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm5,(0<<6) | (3<<4) | (2<<2) | (1)

        PADDW       xmm2, xmm6 ; = SUM 2 lines B
        PADDW       mm2, mm6 ; = SUM 2 lines G
        PADDW       mm5, mm7 ; = SUM 2 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm2, xmm6 ; = SUM 2 lines B
        PADDW       mm2, mm6 ; = SUM 2 lines G
        PADDW       mm5, mm7 ; = SUM 2 lines R
        PSRLW       xmm2,3
        PSRLW       mm2,3
        ;PSLLW       mm5,4
        ;AND        xmm2,[QBlue16Mask]
        PAND        mm5,[QRed16Mask]
        PAND        mm2,[QGreen16Mask]
        MOVD        EDX,xmm2
        POR         mm2,mm5
        MOVD        EAX,mm2

        MOVD        EDI,xmm3 ; restore dest EDI
        OR          EAX,EDX
        LEA         ESI,[ESI+2] ; increment source
        MOV         [EDI],AX
        DEC         ECX
        PADDD       xmm3,xmm4 ; EDI(dest) += 2
        JZ      .EndloopLine1

        ; second pixel ==================
        PMULLW      xmm0, [QMul3ThirdW]
        PMULLW      mm0, [QMul3ThirdW]
        PMULLW      mm3, [QMul3ThirdW]

        PADDW       xmm0, xmm1 ; = SUM 2 lines B
        PADDW       mm0, mm1 ; = SUM 2 lines G
        PADDW       mm3, mm4; = SUM 2 lines R

        PSHUFLW     xmm6,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm6,mm0,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm3,(0<<6) | (3<<4) | (2<<2) | (1)

        PADDW       xmm0, xmm6 ; = SUM 2 lines B
        PADDW       mm0, mm6 ; = SUM 2 lines G
        PADDW       mm3, mm7 ; = SUM 2 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm0, xmm6 ; = SUM 2 lines B
        PADDW       mm0, mm6 ; = SUM 2 lines G
        PADDW       mm3, mm7 ; = SUM 2 lines R
        PSRLW       xmm0,3
        PSRLW       mm0,3
        ;PSLLW       mm5,3
        ;PAND       xmm0,[QBlue16Mask]
        PSRLQ       xmm0,16
        PAND        mm3,[QRed16Mask]
        MOVDQ2Q     mm1,xmm0
        PAND        mm0,[QGreen16Mask]
        PSRLQ       mm3,16
        PSRLQ       mm0,16
        POR         mm1,mm3
        POR         mm1,mm0

        MOVD        EDI,xmm3 ; restore dest EDI
        MOVD        EAX,mm1
        LEA         ESI,[ESI+2] ; increment source
        MOV         [EDI],AX
        DEC         ECX
        PADDD       xmm3,xmm4 ; EDI(dest) += 2
        JNZ         .loopLine1
.EndloopLine1:

; last pixel line 1 --------------------------------------
        AVG_4       5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_4       0,5 ; red AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_4       11,5 ; blue comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        MOVD        EDI,xmm3
        OR          EAX,EDX
        MOV         [EDI],AX
        PADDD       xmm3,xmm4 ; EDI += 2 - jump to the next line
; END BLUR first Horizontal Line ------------------------------------------

        POP         ESI ; restore BuffImgSrc

.EndFirstLine:

; BLUR (ResVt-2) Middle Horizontal Lines -----------------------------------

        CMP         EBP,BYTE 2
        JLE         .LastLine
        SUB         EBP,2 ; EBP the counter for the middle lines
.MidLinesLoop:
; first pixel middle line
        AVG_6V      5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_6V      0,5 ; red AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_6V      11,5 ; blue comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        MOVD        EDI,xmm3
        OR          EAX,EDX

        LEA         ECX,[EBX-2]  ; resHz - 2
        MOV         [EDI],AX

        MOVQ        xmm3,[QBlue16Mask]
        LEA         EDI,[EDI+2]
        MOVQ        xmm4,[QMul8SecondW]
        MOVQ        xmm5,[QMul8ThirdW]

.loopMidLines:

        MOVQ        xmm0,[ESI]
        MOVQ        xmm1,[ESI+EBX*2]
        MOVQ        xmm2,[ESI+EBX*4]

        MOVDQ2Q     mm0,xmm0
        MOVDQ2Q     mm3,xmm0
        MOVDQ2Q     mm1,xmm1
        MOVDQ2Q     mm4,xmm1
        MOVDQ2Q     mm2,xmm2
        MOVDQ2Q     mm5,xmm2

        PAND        xmm0,xmm3 ; [QBlue16Mask]
        PAND        xmm1,xmm3 ; [QBlue16Mask]
        PAND        xmm2,xmm3 ; [QBlue16Mask]
        PAND        mm0,[QGreen16Mask]
        PAND        mm1,[QGreen16Mask]
        PAND        mm2,[QGreen16Mask]
        PAND        mm3,[QRed16Mask]
        PAND        mm4,[QRed16Mask]
        PAND        mm5,[QRed16Mask]
        PSRLW       mm3,4
        PSRLW       mm4,4
        PSRLW       mm5,4
        PADDW       xmm0,xmm2 ; B
        PADDW       mm0,mm2   ; G
        PADDW       mm3,mm5   ; R
        MOVDQA      xmm2,xmm1 ; save middle B
        MOVQ        mm2,mm1   ; save middle G
        MOVQ        mm5,mm4   ; save middle R
        PMULLW      xmm2, xmm4
        PMULLW      mm2, [QMul8SecondW]
        PMULLW      mm5, [QMul8SecondW]

        PADDW       xmm2, xmm0 ; = SUM 3 lines B
        PADDW       mm2, mm0 ; = SUM 3 lines G
        PSHUFLW     xmm6,xmm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PADDW       mm5, mm3 ; = SUM 3 lines R
        PSHUFW      mm6,mm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm5,(0<<6) | (3<<4) | (2<<2) | (1)
        PADDW       xmm2, xmm6 ; = SUM 3 lines B
        PADDW       mm2, mm6 ; = SUM 3 lines G
        PADDW       mm5, mm7 ; = SUM 3 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm2, xmm6 ; = SUM 3 lines B
        PADDW       mm2, mm6 ; = SUM 3 lines G
        PADDW       mm5, mm7 ; = SUM 3 lines R
        PSRLW       xmm2,4
        PSRLW       mm2,4  ;PSLLW       mm5,4  ;PAND        xmm2,[QBlue16Mask]
        PAND        mm5,[QRed16Mask]
        PAND        mm2,[QGreen16Mask]
        MOVD        EDX,xmm2
        POR         mm2,mm5
        MOVD        EAX,mm2

        LEA         ESI,[ESI+2] ; increment source
        OR          EAX,EDX
        DEC         ECX
        STOSW
        JZ          .endMidLines

        PMULLW      xmm1, xmm5
        PMULLW      mm1, [QMul8ThirdW]
        PMULLW      mm4, [QMul8ThirdW]
        PADDW       xmm1, xmm0 ; = SUM 3 lines B
        PADDW       mm1, mm0 ; = SUM 3 lines G

        PSHUFLW     xmm6,xmm1,(0<<6) | (3<<4) | (2<<2) | (1)
        PADDW       mm4, mm3 ; = SUM 3 lines R
        PSHUFW      mm6,mm1,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm4,(0<<6) | (3<<4) | (2<<2) | (1)
        PADDW       xmm1, xmm6 ; = SUM 3 lines B
        PADDW       mm1, mm6 ; = SUM 3 lines G
        PADDW       mm4, mm7 ; = SUM 3 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm1, xmm6 ; = SUM 3 lines B
        PADDW       mm1, mm6 ; = SUM 3 lines G
        PADDW       mm4, mm7 ; = SUM 3 lines R
        PSRLW       xmm1,4
        PSRLW       mm1,4     ;PSLLW       mm4,4    ;PAND       xmm1,[QBlue16Mask]
        PAND        mm4,[QRed16Mask]
        PSRLQ       xmm1,16
        PAND        mm1,[QGreen16Mask]
        MOVDQ2Q     mm0,xmm1
        PSRLQ       mm1,16
        PSRLQ       mm4,16

        POR         mm1,mm0
        POR         mm1,mm4

        LEA         ESI,[ESI+2] ; increment source
        MOVD        EAX,mm1
        DEC         ECX
        STOSW
        JNZ         .loopMidLines

        ;JMP        .loopMidLines
.endMidLines:

        MOVD        xmm3,EDI
        MOVD        xmm4,[DQAdd2] ; xmm4 EDI step +2

; last pixel middle line
        AVG_6VLast  5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_6VLast  0,5 ; red AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_6VLast  11,5 ; blue comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        LEA         ESI,[ESI+4] ; go to next hz line
        OR          EAX,EDX
        MOVD        EDI,xmm3
        DEC         EBP
        MOV         [EDI],AX
        PADDD       xmm3,xmm4 ; EDI += 2

        JNZ         .MidLinesLoop
; END BLUR (ResVt-2) Middle Horizontal Lines -------------------------------


; BLUR last line -----------------------------------------------------------
.LastLine:
        POP         EAX
        CMP         AH,1 ; ignore last line ?
        JE          .errorEnd
; first pixel last line 1 --------------------------

        AVG_4       5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_4       0,5 ; blue AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_4       11,5 ; red comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        OR          EAX,EDX
        MOVD        EDI,xmm3
        MOV         [EDI],AX
        PADDD       xmm3,xmm4 ; EDI += 2
; first line loop ----------------------------------
        LEA         ECX,[EBX-2]
.looplastLine:

        MOVQ        xmm0,[ESI+EBX*2]
        MOVQ        xmm1,[ESI]

        MOVDQ2Q     mm0,xmm0
        MOVDQ2Q     mm3,xmm0
        MOVDQ2Q     mm1,xmm1
        MOVDQ2Q     mm4,xmm1

        PAND        xmm0,[QBlue16Mask]
        PAND        xmm1,[QBlue16Mask]
        PAND        mm0,[QGreen16Mask]
        PAND        mm1,[QGreen16Mask]
        PAND        mm3,[QRed16Mask]
        PAND        mm4,[QRed16Mask]
        PSRLW       mm3,3
        PSRLW       mm4,3
        MOVDQA      xmm2,xmm0 ; save first  B
        MOVQ        mm2,mm0   ; save first G
        MOVQ        mm5,mm3   ; save first R

        PMULLW      xmm2, [QMul3SecondW]
        PMULLW      mm2, [QMul3SecondW]
        PMULLW      mm5, [QMul3SecondW]

        PADDW       xmm2, xmm1 ; = SUM 2 lines B
        PADDW       mm2, mm1 ; = SUM 2 lines G
        PADDW       mm5, mm4; = SUM 2 lines R

        PSHUFLW     xmm6,xmm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm6,mm2,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm5,(0<<6) | (3<<4) | (2<<2) | (1)

        PADDW       xmm2, xmm6 ; = SUM 2 lines B
        PADDW       mm2, mm6 ; = SUM 2 lines G
        PADDW       mm5, mm7 ; = SUM 2 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm2, xmm6 ; = SUM 2 lines B
        PADDW       mm2, mm6 ; = SUM 2 lines G
        PADDW       mm5, mm7 ; = SUM 2 lines R
        PSRLW       xmm2,3
        PSRLW       mm2,3
        ;PSLLW       mm5,4
        ;AND        xmm2,[QBlue16Mask]
        PAND        mm5,[QRed16Mask]
        PAND        mm2,[QGreen16Mask]
        MOVD        EDX,xmm2
        POR         mm2,mm5
        MOVD        EAX,mm2

        MOVD        EDI,xmm3 ; restore dest EDI
        OR          EAX,EDX
        LEA         ESI,[ESI+2] ; increment source
        MOV         [EDI],AX
        DEC         ECX
        PADDD       xmm3,xmm4 ; EDI(dest) += 2
        JZ          .EndlooplastLine

        PMULLW      xmm0, [QMul3ThirdW]
        PMULLW      mm0, [QMul3ThirdW]
        PMULLW      mm3, [QMul3ThirdW]

        PADDW       xmm0, xmm1 ; = SUM 2 lines B
        PADDW       mm0, mm1 ; = SUM 2 lines G
        PADDW       mm3, mm4; = SUM 2 lines R

        PSHUFLW     xmm6,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm6,mm0,(0<<6) | (3<<4) | (2<<2) | (1)
        PSHUFW      mm7,mm3,(0<<6) | (3<<4) | (2<<2) | (1)

        PADDW       xmm0, xmm6 ; = SUM 2 lines B
        PADDW       mm0, mm6 ; = SUM 2 lines G
        PADDW       mm3, mm7 ; = SUM 2 lines R
        PSRLQ       xmm6,16
        PSRLQ       mm6,16
        PSRLQ       mm7,16
        PADDW       xmm0, xmm6 ; = SUM 2 lines B
        PADDW       mm0, mm6 ; = SUM 2 lines G
        PADDW       mm3, mm7 ; = SUM 2 lines R
        PSRLW       xmm0,3
        PSRLW       mm0,3
        ;PSLLW       mm5,3
        ;PAND       xmm0,[QBlue16Mask]
        PSRLQ       xmm0,16
        PAND        mm3,[QRed16Mask]
        MOVDQ2Q     mm1,xmm0
        PAND        mm0,[QGreen16Mask]
        PSRLQ       mm3,16
        PSRLQ       mm0,16
        POR         mm1,mm3
        POR         mm1,mm0

        MOVD        EDI,xmm3 ; restore dest EDI
        MOVD        EAX,mm1
        LEA         ESI,[ESI+2] ; increment source
        MOV         [EDI],AX
        DEC         ECX
        PADDD       xmm3,xmm4 ; EDI(dest) += 2
        JNZ         .looplastLine
.EndlooplastLine:

; last pixel last line -------------------------------------
        AVG_4       5,6 ; green comp
        MOVD        xmm7,EAX
        AVG_4       0,5 ; red AVG
        PSLLQ       xmm7,5
        MOVD        xmm6,EAX
        AVG_4       11,5 ; blue comp
        POR         xmm6,xmm7
        SHL         EAX,11
        MOVD        EDX,xmm6
        OR          EAX,EDX
        MOVD        EDI,xmm3
        MOV         [EDI],AX

; END BLUR last Horizontal Line -------------------------------------------

.errorEnd:
        EMMS
        POP     EBX
        POP     EDI
        POP     ESI

    RETURN


SECTION .data   ALIGN=32
QMul8SecondW    DW  1,8,1,1,1,1,1,1
QMul8ThirdW     DW  1,1,8,1,1,1,1,1
QMul3SecondW    DW  1,3,1,1,1,1,1,1
QMul3ThirdW     DW  1,1,3,1,1,1,1,1
DQAdd2          DD  2,0,0,0

