; Dust Ultimate Game Library (DUGL)
;   Copyright (C) 2025  Fakhri Feki
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

ALIGN 32
PutSurf16:
    ARG SSN16, 4, XPSN16, 4, YPSN16, 4, PSType16, 4
            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         ESI,[EBP+SSN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

            MOV         EAX,[EBP+XPSN16]
            MOV         EBX,[EBP+YPSN16]
            MOV         ESI,[EBP+PSType16]
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ          .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOV         [PutSurfMaxX],EAX ;-
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX ;-
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX ;-
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX ;-
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+XPSN16]
            MOV         EBX,[EBP+YPSN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------

            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip

; PutSurf non Clipper *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SNegScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            ADD         ESI,EAX
            ADD         EAX,EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX ; = [SResH] or clipped width
            TEST        EDI,2     ; dword aligned ?
            JZ          SHORT .FPasStBAv
            DEC         EBX
            MOVSW
            JZ          SHORT .FinSHLine
.FPasStBAv:
            TEST        EDI,4     ; qword aligned ?
            JZ          SHORT .PasStDAv
            CMP         EBX,2
            JL          SHORT .StBAp
            MOVSD
            SUB         EBX,BYTE 2
.PasStDAv:
            ;--
            TEST        EDI, 8
            JZ          SHORT .PasStQAv
            CMP         EBX,BYTE 4
            JL          SHORT .StDAp
            MOVQ        xmm0,[ESI]
            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3  ECX should be equal to zero
            JECXZ       .StQAp

.StoSSE:    MOVDQU      xmm0,[ESI]
            DEC         ECX
            MOVDQA      [EDI],xmm0
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         SHORT .StoSSE
            AND         EBX,BYTE 7
            JZ          SHORT .FinSHLine
.StQAp:     TEST        BL,4
            JZ          SHORT .StDAp
            MOVQ        xmm0,[ESI]
            MOVQ        [EDI], xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
;-----
.StDAp:     TEST        BL,BYTE 2
            JZ          SHORT .StBAp
            MOVSD
.StBAp:     TEST        BL,1
            JZ          SHORT .PasStBAp
            MOVSW
.PasStBAp:
.FinSHLine: ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX
            MOV         EDX,[SResH]
.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST        EDI,2
            JZ          SHORT .IFPasStBAv
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            DEC         EBX
            STOSW
            JZ          .IFinSHLine
.IFPasStBAv:
            TEST        EDI,4
            JZ          SHORT .IPasStDAv
            CMP         EBX,BYTE 1
            JLE         .IStBAp
            SUB         ESI,BYTE 4
            MOV         EAX,[ESI]
            ROR         EAX,16 ; reverse word order
            STOSD
            SUB         EBX,BYTE 2
.IPasStDAv:
            TEST        EDI, 8
            JZ          SHORT .IPasStQAv
            CMP         EBX,BYTE 4
            JL          SHORT .IStDAp
            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm0
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3  ECX should be equal to zero
            ;MOV    ECX,EBX
            ;SHR    ECX,3
            JECXZ       .IStQAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16

            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            DEC         ECX
            PUNPCKLQDQ  xmm1, xmm0

            MOVDQA      [EDI],xmm1
            LEA         EDI,[EDI+16]
            JNZ         SHORT .IStoSSE

            AND         BL,BYTE 7
            JZ          SHORT .IFinSHLine
.IStQAp:
            TEST        BL,4
            JZ          SHORT .IStDAp
            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        [EDI],xmm0
            LEA         EDI,[EDI+8]
.IStDAp:
            TEST        BL,2
            JZ          SHORT .IStBAp
            SUB         ESI,BYTE 4
            MOV         EAX,[ESI]
            ROR         EAX,16
            STOSD
.IStBAp:
            TEST        BL,1
            JZ          SHORT .IPasStBAp
.IBcStBAp:
            SUB         ESI,BYTE 2
            MOV         AX,[ESI]
            STOSW
.IPasStBAp:
.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipper **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST         BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV        [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV        [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST         BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipped and inversed horizontally

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:
            POP         EBX
            POP         EDI
            POP         ESI
    RETURN


; PUT masked Surf
;*****************

ALIGN 32
PutMaskSurf16:
    ARG MSSN16, 4, MXPSN16, 4, MYPSN16, 4, MPSType16, 4

            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         ESI,[EBP+MSSN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

            MOV         EAX,[EBP+MXPSN16]
            MOV         EBX,[EBP+MYPSN16]
            MOV         ESI,[EBP+MPSType16]
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ          .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            PSHUFLW     xmm0,[SMask],0
            PUNPCKLQDQ  xmm0,xmm0
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOVDQA      [DQ16Mask],xmm0
            MOV         [PutSurfMaxX],EAX
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+MXPSN16]
            MOV         EBX,[EBP+MYPSN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------
            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip
; PutSurf not Clipped *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SNegScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            ADD         ESI,EAX
            ADD         EAX,EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX
.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            LEA         ESI,[ESI+2]
            JZ          .PasStBAv
            STOSW
            DEC         EBX
            JZ          .FinSHLine
            JMP         .BcStBAv

.PasStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
;--------
            TEST        EDI, 8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm0,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            SUB         EBX, BYTE 4
            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm2,[ESI]
            MOVDQA      xmm4,[EDI]
            MOVDQA      xmm1,xmm2
            MOVDQA      xmm0,xmm2

            PCMPEQW     xmm1,[DQ16Mask]
            PCMPEQW     xmm2,[DQ16Mask]
            PAND         xmm4,xmm1
            PANDN       xmm2,xmm0
            POR         xmm2,xmm4
            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         BL,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm0,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          SHORT .FinSHLine

.BcStBAp:
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            LEA         ESI,[ESI+2]
            JZ          .BPasStBAp
            DEC         BL
            STOSW
            JNZ         .BcStBAp
            JMP         SHORT .FinSHLine
.BPasStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX
            MOV         EDX,[SResH]
.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST        EDI,6
            JZ          .IFPasStBAv
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JZ          .IBPasStBAv

            DEC         EBX
            STOSW
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IBPasStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IFPasStBAv:
            TEST        EDI, 8
            JZ          .IPasStQAv
            CMP         EBX,BYTE 4
            JL          .IPasStQAp

            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            MOVQ        xmm2,xmm0
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,[EDI]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 : ECX should be zero
            JZ          .IStBAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16
            MOVDQA      xmm3,[EDI]
            MOVQ        xmm2,[ESI] ; get again the reversed source
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVDQA      xmm4,[EDI]
            PUNPCKLQDQ  xmm1,xmm2
            MOVDQA      xmm0,xmm1
            PCMPEQW     xmm1,[DQ16Mask]
            MOVDQA      xmm2,xmm1

            PAND        xmm4,xmm1
            PANDN       xmm2,xmm0
            POR         xmm2,xmm4

            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         EDI,[EDI+16]
            JNZ         .IStoSSE
.IStBAp:
            AND         BL,7
            JZ          .IFinSHLine
            TEST        BL,4
            JZ          .IPasStQAp
            SUB         ESI,BYTE 8
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm0,xmm2
            MOVQ        xmm4,[EDI]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
.IPasStQAp:
            AND         BL,3
            JZ          .IFinSHLine
.IBcStBAp:
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JZ          .IBPasStBAp
            DEC         BL
            STOSW
            JNZ         .IBcStBAp
            JMP         SHORT .IFinSHLine
.IBPasStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp

.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipper **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST        BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV            [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV        [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST        BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipper et inverser horizontalement

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:
            POP         EBX
            POP         EDI
            POP         ESI

    RETURN



; -------------------------------
; Put a Surf blended with a color
; -------------------------------
ALIGN 32
PutSurfBlnd16:
  ARG SSBN16, 4, XPSBN16, 4, YPSBN16, 4, PSBType16, 4, PSBCol16, 4
            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         ESI,[EBP+SSBN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

; prepare col blending
            MOV         EAX,[EBP+PSBCol16] ;
            MOV         EBX,EAX ;
            MOV         ECX,EAX ;
            MOV         EDX,EAX ;
            AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
            SHR         EAX,24
            AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
            AND         AL,BlendMask ; remove any ineeded bits
            AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
            XOR         AL,BlendMask ; 31-blendsrc
            MOV         EDI,EAX
            XOR         AL,BlendMask ; 31-blendsrc
            INC         AL
            SHR         DX,5 ; right shift red 5bits
            IMUL        BX,AX
            IMUL        CX,AX
            IMUL        DX,AX
            MOVD        xmm3,EBX
            MOVD        xmm4,ECX
            MOVD        xmm5,EDX
            MOVD        xmm7,EDI
            PSHUFLW     xmm3,xmm3,0
            PSHUFLW     xmm4,xmm4,0
            PSHUFLW     xmm5,xmm5,0
            PSHUFLW     xmm7,xmm7,0
            PUNPCKLQDQ  xmm3,xmm3
            PUNPCKLQDQ  xmm4,xmm4
            PUNPCKLQDQ  xmm5,xmm5
            PUNPCKLQDQ  xmm7,xmm7

            MOV         EAX,[EBP+XPSBN16]
            MOV         EBX,[EBP+YPSBN16]
            MOV         ESI,[EBP+PSBType16]
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ          .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOV         [PutSurfMaxX],EAX ;-
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX ;-
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX ;-
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX ;-
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+XPSBN16]
            MOV         EBX,[EBP+YPSBN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------

            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip
; PutSurf non Clipper *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            SUB         ESI,EAX
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX ; = [SResH]
.BcStBAv:
            TEST        EDI,6     ; dword aligned ?
            JZ          .FPasStBAv
            PINSRW      xmm0,[ESI],0
            DEC         EBX
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            LEA         ESI,[ESI+2]
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
            TEST        EDI, 8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            SUB         EBX, BYTE 4
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
            SHLD        ECX,EBX,29 ; ECX = (EBX >> 2) : ECX should be zero
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            DEC         ECX
            MOVDQA      [EDI],xmm0
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         BL,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          SHORT .FinSHLine
.BcStBAp:
            PINSRW      xmm0,[ESI],0
            DEC         BL
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            LEA         ESI,[ESI+2]
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX
            MOV         EDX,[SResH]

.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST        EDI,6
            JZ          .IFPasStBAv
            SUB         ESI, BYTE 2
            PINSRW      xmm0,[ESI],0
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            DEC         EBX
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IFPasStBAv:
            TEST        EDI, 8
            JZ          .IPasStQAv
            CMP         EBX,BYTE 4
            JL          .IPasStQAp

            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            SUB         EBX,BYTE 4
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        [EDI],xmm0
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 : ECX should be zero
            JZ          .IStBAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PUNPCKLQDQ  xmm1,xmm0
            DEC         ECX
            MOVDQA      xmm0,xmm1
            MOVDQA      xmm2,xmm1
            @SolidBlndQ
            MOVDQA      [EDI],xmm0
            LEA         EDI,[EDI+16]
            JNZ         .IStoSSE
.IStBAp:
            AND         BL,BYTE 7
            JZ          .IFinSHLine
            TEST        BL,4
            JZ          .IPasStQAp
            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        [EDI],xmm0
            LEA         EDI,[EDI+8]
.IPasStQAp:
            AND         BL,3
            JZ          .IFinSHLine
.IBcStBAp:
            SUB         ESI, BYTE 2
            PINSRW      xmm0,[ESI],0
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            DEC         BL
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp
.IPasStBAp:
.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipped **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST        BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV        [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV        [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST        BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipped and inversed horizontally

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:

            POP         EBX
            POP         EDI
            POP         ESI

    RETURN


; =======================================
; Put a MASKED Surf blended with a color
; =======================================
ALIGN 32
PutMaskSurfBlnd16:
  ARG MSSBN16, 4, MXPSBN16, 4, MYPSBN16, 4, MPSBType16, 4, MPSBCol16, 4
            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         ESI,[EBP+MSSBN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

            ; prepare col blending
            MOV         EAX,[EBP+MPSBCol16] ;
            MOV         EBX,EAX ;
            MOV         ECX,EAX ;
            MOV         EDX,EAX ;
            AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
            SHR         EAX,24
            AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
            AND         AL,BlendMask ; remove any ineeded bits
            AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
            XOR         AL,BlendMask ; 31-blendsrc
            MOV         EDI,EAX
            XOR         AL,BlendMask ; 31-blendsrc
            INC         AL
            SHR         DX,5 ; right shift red 5bits
            IMUL        BX,AX
            IMUL        CX,AX
            IMUL        DX,AX
            PSHUFLW     xmm0,[SMask],0
            MOVD        xmm3,EBX
            MOVD        xmm4,ECX
            MOVD        xmm5,EDX
            MOVD        xmm7,EDI
            PSHUFLW     xmm3,xmm3,0
            PSHUFLW     xmm4,xmm4,0
            PSHUFLW     xmm5,xmm5,0
            PSHUFLW     xmm7,xmm7,0

            PUNPCKLQDQ  xmm0,xmm0
            PUNPCKLQDQ  xmm3,xmm3
            PUNPCKLQDQ  xmm4,xmm4
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm5,xmm5

            MOVDQA      [DQ16Mask],xmm0

            MOV         EAX,[EBP+MXPSBN16]
            MOV         EBX,[EBP+MYPSBN16]
            MOV         ESI,[EBP+MPSBType16]
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ          .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOV         [PutSurfMaxX],EAX
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+MXPSBN16]
            MOV         EBX,[EBP+MYPSBN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------

            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip
; PutSurf non Clipper *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            SUB         ESI,EAX
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX
.BcStBAv:
            TEST        EDI,6     ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JE          .MaskBAv
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.MaskBAv:
            DEC         EBX
            LEA         ESI,[ESI+2]
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
            TEST        EDI,8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3, ECX should be zero
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            MOVDQU      xmm2,[ESI]
            MOVDQA      xmm6,[EDI]
            MOVDQA      xmm1,xmm2

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         EBX,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,[ESI]
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          .FinSHLine
.BcStBAp:
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JE          .MaskBAp
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.MaskBAp:
            DEC         BL
            LEA         ESI,[ESI+2]
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX

.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST        EDI,6
            JZ          .IFPasStBAv
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[SMask]
            JE          .IMaskStBAv
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.IMaskStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IFPasStBAv:
            TEST        EDI, 8
            JZ          .IPasStQAv
            CMP         EBX,BYTE 4
            JL          .IStBAp
            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            @SolidBlndQ

            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1
            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 : ECX should be zero
            JZ          .IStBAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PUNPCKLQDQ  xmm1,xmm0
            MOVDQA      xmm2,xmm1
            MOVDQA      xmm0,xmm1
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PUNPCKLQDQ  xmm1,xmm2
            MOVDQA      xmm6,[EDI]
            MOVDQA      xmm2,xmm1

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1
            MOVDQA      [EDI],xmm2
            DEC         ECX
            LEA         EDI,[EDI+16]
            JNZ         .IStoSSE
.IStBAp:
            AND         BL,BYTE 7
            JZ          .IFinSHLine
            TEST        BL,4
            JZ          .IPasStQAp
            SUB         ESI,BYTE 8
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,[ESI]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
.IPasStQAp:
            AND         BL,3
            JZ          .IFinSHLine
.IBcStBAp:
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JE          .IMaskStBAp
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.IMaskStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp
.IPasStBAp:
.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipper **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST        BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV        [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV    [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST        BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipped & inversed horizontally

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:
            POP         ESI
            POP         EDI
            POP         EBX
    RETURN

ALIGN 32
SurfMaskCopyBlnd16:
    ARG PDstSrfMB, 4, PSrcSrfMB, 4, SCMBCol, 4
            PUSH        EDI
            PUSH        ESI
            PUSH        EBX

; prepare col blending
            MOV         EAX,[EBP+SCMBCol] ;
            MOV         EBX,EAX ;
            MOV         ECX,EAX ;
            MOV         EDX,EAX ;
            AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
            SHR         EAX,24
            AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
            AND         AL,BlendMask ; remove any ineeded bits
            AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
            XOR         AL,BlendMask ; 31-blendsrc
            MOV         EDI,EAX
            XOR         AL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EDI
            MOV         ESI,[EBP+PSrcSrfMB]
            MOV         EDI,[EBP+PDstSrfMB]
            INC         AL
            SHR         DX,5 ; right shift red 5bits
            IMUL        BX,AX
            IMUL        CX,AX
            IMUL        DX,AX
            MOVD        xmm3,EBX
            MOVD        xmm4,ECX
            MOVD        xmm5,EDX
            PSHUFLW     xmm0,[ESI+DuglSurf.Mask],0
            PSHUFLW     xmm3,xmm3,0
            PSHUFLW     xmm4,xmm4,0
            PSHUFLW     xmm5,xmm5,0
            PSHUFLW     xmm7,xmm7,0

            PUNPCKLQDQ  xmm0,xmm0
            PUNPCKLQDQ  xmm3,xmm3
            PUNPCKLQDQ  xmm4,xmm4
            PUNPCKLQDQ  xmm5,xmm5
            PUNPCKLQDQ  xmm7,xmm7
            MOVDQA      [DQ16Mask],xmm0

            MOV         EBX,[ESI+DuglSurf.SizeSurf]
            MOVD        EBP,xmm0

            MOV         EDI,[EDI+DuglSurf.rlfb]
            SHR         EBX,1
            MOV         ESI,[ESI+DuglSurf.rlfb]
            XOR         ECX,ECX

.BcStBAv:
            TEST        EDI,6     ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,BP
            JE          .MaskBAv
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.MaskBAv:
            DEC         EBX
            LEA         ESI,[ESI+2]
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
            TEST        EDI,8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3, ECX should be zero
            JZ      .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            @SolidBlndQ
            MOVDQU      xmm2,[ESI]
            MOVDQA      xmm6,[EDI]
            MOVDQA      xmm1,xmm2

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         EBX,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @SolidBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,[ESI]
            MOVQ        xmm6,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm1,xmm6
            POR         xmm2,xmm1

            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          .FinSHLine
.BcStBAp:
            MOV         AX,[ESI]
            CMP         AX,BP
            JE          .MaskBAp
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
.MaskBAp:
            DEC         BL
            LEA         ESI,[ESI+2]
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
.FinSurfCopy:
            POP   EBX
            POP   ESI
            POP   EDI
    RETURN

; -------------------------------
; Put a Transparent Surf
; -------------------------------

ALIGN 32
PutSurfTrans16:
    ARG SSTN16, 4, XPSTN16, 4, YPSTN16, 4, PSTType16, 4, PSTrans16, 4
            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         ESI,[EBP+SSTN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

; prepare col blending
            MOV         EAX,[EBP+PSTrans16] ;
            AND         EAX,BYTE BlendMask
            JZ          .PasPutSurf
            MOV         EDX,EAX ;
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm6,xmm6

            MOV         EAX,[EBP+XPSTN16]
            MOV         EBX,[EBP+YPSTN16]
            MOV         ESI,[EBP+PSTType16]
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ          .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOV         [PutSurfMaxX],EAX ;-
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX ;-
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX ;-
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX ;-
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+XPSTN16]
            MOV         EBX,[EBP+YPSTN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------

            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip
; PutSurf non Clipper *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SNegScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            ADD         ESI,EAX
            ADD         EAX,EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX
.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            PINSRW      xmm0,[ESI],0
            DEC         EBX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            LEA         ESI,[ESI+2]
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
;--------
            TEST        EDI, 8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            SUB         EBX, BYTE 4
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm3,[EDI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm4,xmm3
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm5,xmm3
            @TransBlndQ
            DEC         ECX
            MOVDQA      [EDI],xmm0
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         BL,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            AND         BL,BYTE 3
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
            JZ          .FinSHLine
.PasStQAp:

.BcStBAp:
            PINSRW      xmm0,[ESI],0
            DEC         BL
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            LEA         ESI,[ESI+2]
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX
            MOV         EDX,[SResH]
.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST         EDI,6
            JZ          .IFPasStBAv
            PINSRW      xmm3,[EDI],0
            SUB         ESI, BYTE 2
            PINSRW      xmm0,[ESI],0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            DEC         EBX
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IFPasStBAv:
            TEST        EDI, 8
            JZ          .IPasStQAv
            CMP         EBX,BYTE 4
            JL          .IStBAp

            SUB         ESI,BYTE 8
            MOVQ        xmm3,[EDI]
            MOVQ        xmm0,[ESI]
            SUB         EBX,BYTE 4
            MOVQ        xmm4,xmm3
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            MOVQ        [EDI],xmm0
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 : ECX should be zero
            JZ          .IStBAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16
            MOVDQA      xmm3,[EDI]
            MOVQ        xmm1,[ESI]
            MOVQ        xmm0,[ESI+8]
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVDQA      xmm4,xmm3
            PUNPCKLQDQ  xmm0,xmm1
            MOVDQA      xmm5,xmm3

            DEC         ECX
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm1,xmm0
            @TransBlndQ
            MOVDQA      [EDI],xmm0
            LEA         EDI,[EDI+16]
            JNZ         .IStoSSE
.IStBAp:
            AND         BL,7
            JZ          .IFinSHLine
            TEST        BL,4
            JZ          .IPasStQAp
            SUB         ESI,BYTE 8
            MOVQ        xmm3,[EDI]
            MOVQ        xmm0,[ESI]
            MOVQ        xmm4,xmm3
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            MOVQ        [EDI],xmm0
            AND         BL,3
            LEA         EDI,[EDI+8]
            JZ          .IFinSHLine
.IPasStQAp:
.IBcStBAp:
            SUB         ESI, BYTE 2
            PINSRW      xmm3,[EDI],0
            PINSRW      xmm0,[ESI],0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            DEC         BL
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp
.IPasStBAp:
.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipper **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST        BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV        [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV    [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST        BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipped and inversed horizontally

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:
            POP         ESI
            POP         EDI
            POP         EBX
    RETURN



; -------------------------------
; Put a Masked Transparent Surf
; -------------------------------

ALIGN 32

PutMaskSurfTrans16:
    ARG SMSTN16, 4, XPMSTN16, 4, YPMSTN16, 4, PMSTType16, 4, PMSTrans16, 4
            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         ESI,[EBP+SMSTN16]
            MOV         EDI,SrcSurf

            CopySurfDA  ; copy surf

; prepare col blending
            MOV         EAX,[EBP+PMSTrans16] ;
            AND         EAX,BYTE BlendMask
            JZ          .PasPutSurf
            MOV         EDX,EAX ;
            PSHUFLW     xmm0,[SMask],0
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm0,xmm0
            PUNPCKLQDQ  xmm6,xmm6

            MOV         EAX,[EBP+XPMSTN16]
            MOV         EBX,[EBP+YPMSTN16]
            MOV         ESI,[EBP+PMSTType16]
            MOVDQA      [DQ16Mask],xmm0
            MOV         ECX,EAX
            MOV         EDX,EBX

; --- compute Put coordinates of the View inside the Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            TEST        ESI,1
            JZ          .NormHzPut
            SUB         EAX,[SMinX]
            SUB         ECX,[SMaxX]
            JMP         SHORT .InvHzPut
.NormHzPut:
            ADD         EAX,[SMaxX] ; EAX = PutMaxX
            ADD         ECX,[SMinX] ; ECX = PutMinX
.InvHzPut:
            TEST        ESI,2
            JZ         .NormVtPut
            SUB         EBX,[SMinY]
            SUB         EDX,[SMaxY]
            JMP         SHORT .InvVtPut
.NormVtPut:
            ADD         EBX,[SMaxY] ; EBX = PutMaxY
            ADD         EDX,[SMinY] ; EDX = PutMinY
.InvVtPut:
; InView inside (MinX, MinY, MaxX, MaxY)
            CMP         EAX,[MinX]
            JL          .PasPutSurf
            CMP         EBX,[MinY]
            JL          .PasPutSurf
            CMP         ECX,[MaxX]
            JG          .PasPutSurf
            CMP         EDX,[MaxY]
            JG          .PasPutSurf

            CMP         EAX,[MaxX]
            CMOVG       EAX,[MaxX]
            CMP         EBX,[MaxY]
            MOV         [PutSurfMaxX],EAX
            CMOVG       EBX,[MaxY]
            CMP         ECX,[MinX]
            MOV         [PutSurfMaxY],EBX
            CMOVL       ECX,[MinX]
            CMP         EDX,[MinY]
            MOV         [PutSurfMinX],ECX
            CMOVL       EDX,[MinY]
            MOV         [PutSurfMinY],EDX
; --- compute Put coordinates of the entire Surf
; EAX: MaxX, EBX; MaxY, ECX: MinX, EDX: MnY
            MOV         EAX,[EBP+XPMSTN16]
            MOV         EBX,[EBP+YPMSTN16]
            MOV         ECX,EAX
            MOV         EDX,EBX
            TEST        ESI,1
            MOV         EDI,[SOrgX]
            JZ          SHORT .FNormHzPut
            SUB         ECX,[SResH]
            ADD         EAX,EDI
            LEA         ECX,[ECX+EDI+1]
            JMP         SHORT .FInvHzPut
.FNormHzPut:
            ADD         EAX,[SResH]
            SUB         ECX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EAX,EDI
            DEC         EAX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvHzPut:
            TEST        ESI,2
            MOV         EDI,[SOrgY]
            JZ          .FNormVtPut
            SUB         EDX,[SResV]
            ADD         EBX,EDI
            LEA         EDX,[EDX+EDI+1]
            JMP         SHORT .FInvVtPut
.FNormVtPut:
            ADD         EBX,[SResV]
            SUB         EDX,EDI ; MinX = ECX = posXPut - SOrgX
            SUB         EBX,EDI
            DEC         EBX         ; MaxX = EAX = posXPut + (SResH -1) - SOrgX
.FInvVtPut:
;-----------------------------------------------

            CMP         EAX,[PutSurfMaxX]
            JG          .PutSurfClip
            CMP         EBX,[PutSurfMaxY]
            JG          .PutSurfClip
            CMP         ECX,[PutSurfMinX]
            JL          .PutSurfClip
            CMP         EDX,[PutSurfMinY]
            JL          .PutSurfClip
; PutSurf non Clipper *****************************
            MOV         [PType],ESI
            MOV         EBP,[SResV]
            TEST        ESI,2 ; vertically reversed ?
            JZ          .NormAdSPut
            MOV         ESI,[Srlfb]
            MOV         EAX,[SNegScanLine]
            ADD         ESI,[SSizeSurf] ; ESI start of the last line in the surf
            ADD         ESI,EAX
            ADD         EAX,EAX
            JMP         SHORT .InvAdSPut
.NormAdSPut:
            XOR         EAX,EAX
            MOV         ESI,[Srlfb] ; ESI : start copy adress
.InvAdSPut:
            MOV         EDI,EBX ; PutMaxY or the top left corner
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; += PutMinX*2 top left croner
            MOV         EDX,[ScanLine]
            ADD         EDI,[vlfb]
            SUB         EDX,[SScanLine] ; EDX : dest adress plus
            MOV         [Plus2],EDX

            TEST        BYTE [PType],1
            MOV         EDX,[SResH]
            JNZ         .InvHzPSurf
            MOV         [Plus],EAX
.PutSurf:
            XOR         ECX,ECX
.BcPutSurf:
            MOV         EBX,EDX
.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            LEA         ESI,[ESI+2]
            JZ          .PasStBAv
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         EBX
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.PasStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
;--------
            TEST        EDI, 8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            SUB         EBX, BYTE 4
            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm3,[EDI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm4,xmm3
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm5,xmm3
            @TransBlndQ
            MOVDQU      xmm2,[ESI]
            MOVDQA      xmm4,[EDI]
            PCMPEQW     xmm2,[DQ16Mask]
            MOVDQA      xmm1,xmm2

            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         BL,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          .FinSHLine
.BcStBAp:
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            LEA         ESI,[ESI+2]
            JZ          .BPasStBAp
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         BL
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
            JMP         SHORT .FinSHLine
.BPasStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .BcPutSurf

            JMP         .PasPutSurf

; Put surf unclipped reversed horizontally *************
.InvHzPSurf:
            LEA         EAX,[EAX+EDX*4] ; +=SScanLine*2
            LEA         ESI,[ESI+EDX*2] ; +=SScanLine
            MOV         [Plus],EAX
            MOV         EDX,[SResH]
.IPutSurf:
            XOR         ECX,ECX
.IBcPutSurf:
            MOV         EBX,EDX
.IBcStBAv:
            TEST        EDI,6
            JZ          .IFPasStBAv
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JZ          .IBPasStBAv
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         EBX
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IBPasStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .IFinSHLine
            JMP         .IBcStBAv
.IFPasStBAv:
            TEST        EDI, 8
            JZ          .IPasStQAv
            CMP         EBX,BYTE 4
            JL          .IStBAp

            SUB         ESI,BYTE 8
            MOVQ        xmm3,[EDI]
            MOVQ        xmm0,[ESI]
            MOVQ        xmm4,xmm3
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            SUB         EBX,BYTE 4
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
.IPasStQAv:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 : ECX should be zero
            JZ          .IStBAp
;ALIGN 4
.IStoSSE:
            SUB         ESI,BYTE 16
            MOVDQA      xmm3,[EDI]
            ;v2
            MOVQ        xmm1,[ESI]
            MOVQ        xmm0,[ESI+8]
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVDQA      xmm4,xmm3
            PUNPCKLQDQ  xmm0,xmm1
            MOVDQA      xmm5,xmm3

            DEC         ECX
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm1,xmm0
            @TransBlndQ
            MOVQ        xmm2,[ESI] ; get again the reversed source
            MOVQ        xmm1,[ESI+8]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVDQA      xmm4,[EDI]
            PUNPCKLQDQ  xmm1,xmm2
            PCMPEQW     xmm1,[DQ16Mask]
            MOVDQA      xmm2,xmm1

            PAND        xmm4,xmm1
            PANDN       xmm2,xmm0
            POR         xmm2,xmm4
            MOVDQA      [EDI],xmm2
            LEA         EDI,[EDI+16]
            JNZ         .IStoSSE
.IStBAp:
            AND         BL,7
            JZ          .IFinSHLine
            TEST        BL,4
            JZ          .IPasStQAp
            SUB         ESI,BYTE 8
            MOVQ        xmm3,[EDI]
            MOVQ        xmm0,[ESI]
            MOVQ        xmm4,xmm3
            PSHUFLW     xmm0,xmm0,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            MOVQ        xmm5,xmm3
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]
            PSHUFLW     xmm2,xmm2,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PSHUFLW     xmm1,xmm1,(0<<6) | (1<<4) | (2<<2) | (3) ; reverse order 11 10 01 00
            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            AND         BL,3
            MOVQ        [EDI],xmm2
            LEA         EDI,[EDI+8]
            JZ          .IFinSHLine
.IPasStQAp:
.IBcStBAp:
            SUB         ESI, BYTE 2
            MOV         AX,[ESI]
            CMP         AX,[DQ16Mask]
            JZ          .IBPasStBAp
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         BL
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp
            JMP         SHORT .IFinSHLine
.IBPasStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .IBcStBAp

.IFinSHLine:
            ADD         EDI,[Plus2]
            ADD         ESI,[Plus]
            DEC         EBP
            JNZ         .IBcPutSurf

            JMP         .PasPutSurf

.PutSurfClip:
; PutSurf Clipper **********************************************
            MOV         [PType],ESI ; sauvegarde le type
            XOR         EDI,EDI   ; Y Fin Source
            XOR         ESI,ESI   ; X deb Source

            MOV         EBP,[PutSurfMinX]
            CMP         ECX,EBP ; CMP minx, MinX
            JGE         .PsInfMinX   ; XP1<MinX
            TEST        BYTE [PType],1 ; INV HZ
            JNZ         .InvHzCalcDX
            MOV         ESI,EBP
            ;MOV        [XP1],EBP    ; XP1 = MinX
            SUB         ESI,ECX ; ESI = MinX - XP2
.InvHzCalcDX:
            MOV         ECX,EBP
.PsInfMinX:
            MOV         EBP,[PutSurfMaxY]
            CMP         EBX,EBP ; cmp maxy, MaxY
            JLE         .PsSupMaxY   ; YP2>MaxY
            MOV         EDI,EBP
            NEG         EDI
            ;MOV        [YP2],EBP
            ADD         EDI,EBX
            MOV         EBX,EBP
.PsSupMaxY:
            MOV         EBP,[PutSurfMinY]
            CMP         EDX,EBP      ; YP1<MinY
            JGE         .PsInfMinY
            MOV         EDX,EBP
.PsInfMinY:
            MOV         EBP,[PutSurfMaxX]
            CMP         EAX,EBP      ; XP2>MaxX
            JLE         .PsSupMaxX
            TEST        BYTE [PType],1
            JZ          .PsInvHzCalcDX
            MOV         ESI,EAX
            SUB         ESI,EBP ; ESI = XP2 - MaxX
.PsInvHzCalcDX:
            MOV         EAX,EBP
.PsSupMaxX:
            SUB         EAX,ECX      ; XP2 - XP1
            MOV         EBP,[SScanLine]
            LEA         EAX,[EAX*2+2]
            SUB         EBP,EAX  ; EBP = SResH-DeltaX, PlusSSurf
            MOV         [Plus],EBP
            MOV         EBP,EBX
            SUB         EBP,EDX      ; YP2 - YP1
            INC         EBP   ; EBP = DeltaY
            MOV         EDX,[ScanLine]
            MOVD        xmm0,EAX ; = DeltaX
            SUB         EDX,EAX ; EDX = ResH-DeltaX, PlusDSurfS
            TEST        BYTE [PType],2 ; inv VT ?
            MOV         [Plus2],EDX
            JZ          .CNormAdSPut
            MOV         EAX,[Srlfb] ; Si inverse vertical
            ADD         EAX,[SSizeSurf] ; go to the last buffer
            SUB         EAX,[SScanLine] ; jump to the first of the last line
            LEA         EAX,[EAX+ESI*2] ; +X1InSSurf*2 clipping
            IMUL        EDI,[SScanLine] ; Y1InSSurf*ScanLine
            SUB         EAX,EDI
            MOV         ESI,EAX

            MOV         EAX,[SScanLine]
            ADD         EAX,EAX
            NEG         EAX
            JMP         SHORT .CInvAdSPut
.CNormAdSPut:
            IMUL        EDI,[SScanLine]
            XOR         EAX,EAX
            LEA         EDI,[EDI+ESI*2]
            ADD         EDI,[Srlfb]
            MOV         ESI,EDI
.CInvAdSPut:
            MOV         EDI,EBX ; putSurf MaxY
            IMUL        EDI,[NegScanLine]
            LEA         EDI,[EDI+ECX*2] ; + XP1*2 as 16bpp
            PSRLD       xmm0,1 ; (deltaX*2) / 2
            ADD         EDI,[vlfb]

            MOVD        EDX,xmm0  ; DeltaX
            TEST        BYTE [PType],1
            JNZ         .CInvHzPSurf
            ADD         [Plus],EAX
            JMP         .PutSurf

.CInvHzPSurf:   ; clipper et inverser horizontalement

            ADD         EAX,[SScanLine]
            LEA         EAX,[EAX+EDX*2] ; add to jump to the end
            LEA         ESI,[ESI+EDX*2] ; jump to the end
            MOV         [Plus],EAX
            JMP         .IPutSurf

.PasPutSurf:
            POP         EBX
            POP         EDI
            POP         ESI
    RETURN



ALIGN 32
SurfMaskCopyTrans16:
    ARG PDstSrfMT, 4, PSrcSrfMT, 4, SCMTrans, 4
            PUSH        EDI
            PUSH        ESI
            PUSH        EBX

; prepare col blending
            MOV         EAX,[EBP+SCMTrans] ;
            AND         EAX,BYTE BlendMask
            JZ          .FinSurfCopy
            MOV         EDX,EAX ;
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            MOV         ESI,[EBP+PSrcSrfMT]
            MOV         EDI,[EBP+PDstSrfMT]
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PSHUFLW     xmm0,[ESI+DuglSurf.Mask],0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm6,xmm6
            PUNPCKLQDQ  xmm0,xmm0

            MOV         EBX,[ESI+DuglSurf.SizeSurf]
            MOVD        EBP,xmm0
            MOVDQA      [DQ16Mask],xmm0

            MOV         EDI,[EDI+DuglSurf.rlfb]
            SHR         EBX,1
            MOV         ESI,[ESI+DuglSurf.rlfb]
            XOR         ECX,ECX
.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,BP
            LEA         ESI,[ESI+2]
            JZ          .PasStBAv
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         EBX
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.PasStBAv:
            DEC         EBX
            LEA         EDI,[EDI+2]
            JZ          .FinSHLine
            JMP         .BcStBAv
.FPasStBAv:
;--------
            TEST        EDI, 8
            JZ          .PasStQAv
            CMP         EBX,BYTE 4
            JL          .StBAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            SUB         EBX, BYTE 4
            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAv:
;-------
            SHLD        ECX,EBX,29
            JZ          .StBAp
;ALIGN 4
.StoSSE:
            MOVDQU      xmm0,[ESI]
            MOVDQA      xmm3,[EDI]
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm4,xmm3
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm5,xmm3
            @TransBlndQ
            MOVDQU      xmm2,[ESI]
            MOVDQA      xmm4,[EDI]
            PCMPEQW     xmm2,[DQ16Mask]
            MOVDQA      xmm1,xmm2

            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4
            DEC         ECX
            MOVDQA      [EDI],xmm2
            LEA         ESI,[ESI+16]
            LEA         EDI,[EDI+16]
            JNZ         .StoSSE
.StBAp:
            AND         BL,BYTE 7
            JZ          .FinSHLine
.StQAp:
            TEST        BL,4
            JZ          .PasStQAp
            MOVQ        xmm0,[ESI]
            MOVQ        xmm3,[EDI]
            MOVQ        xmm1,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm2,xmm0
            MOVQ        xmm5,xmm3
            @TransBlndQ
            MOVQ        xmm2,[ESI]
            MOVQ        xmm1,xmm2
            MOVQ        xmm4,[EDI]

            PCMPEQW     xmm2,[DQ16Mask]
            PCMPEQW     xmm1,[DQ16Mask]
            PANDN       xmm2,xmm0
            PAND        xmm4,xmm1
            POR         xmm2,xmm4

            MOVQ        [EDI],xmm2
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          .FinSHLine
.BcStBAp:
            MOV         AX,[ESI]
            CMP         AX,BP
            LEA         ESI,[ESI+2]
            JZ          .BPasStBAp
            MOVD        xmm0,EAX
            PINSRW      xmm3,[EDI],0
            MOVQ        xmm1,xmm0
            MOVQ        xmm2,xmm0
            MOVQ        xmm4,xmm3
            MOVQ        xmm5,xmm3
            @TransBlndQ
            DEC         BL
            PEXTRW      [EDI],xmm0,0
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
            JMP         SHORT .FinSHLine
.BPasStBAp:
            DEC         BL
            LEA         EDI,[EDI+2]
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
.FinSurfCopy:
            POP         EBX
            POP         ESI
            POP         EDI

    RETURN

