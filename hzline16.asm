;   Dust Ultimate Game Library (DUGL)
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


;***** SOLID
;***************************************************************************
; IN : (mm0, EAX) col, ESI long, EDI Dest,
; change : ECX
;***************************************************************************
;%macro @SolidHLine16   0
;            TEST   EDI, 2
;            JZ     SHORT %%FPasStBAv
;            DEC        ESI
;            MOV        [EDI],AX
;            JZ     SHORT %%FinSHLine
;            LEA        EDI,[EDI+2]
;%%FPasStBAv:
;            TEST   EDI, 4
;            JZ     SHORT %%PasStDAv
;            CMP        ESI,BYTE 2
;            JL     SHORT %%StBAp
;            MOV        [EDI],EAX
;            SUB        ESI,BYTE 2
;            LEA        EDI,[EDI+4]
;%%PasStDAv:
;            MOV        ECX,ESI
;            SHR        ECX,2
;            ;OR        ECX,ECX
;            JECXZ   %%StDAp;JZ     SHORT %%StDAp
;ALIGN 4
;%%StoMMX:  MOVQ    [EDI],xmm0
;            DEC        ECX
;            LEA        EDI,[EDI+8]
;            JNZ        SHORT %%StoMMX
;            AND        ESI,BYTE 3
;            JZ     SHORT %%FinSHLine
;%%StDAp:   CMP     ESI,BYTE 2
;            JL     SHORT %%StBAp
;            STOSD
;%%StBAp:   AND     ESI,BYTE 1
;            JZ     SHORT %%PasStBAp
;            MOV        [EDI],AX
;%%PasStBAp:
;%%FinSHLine:
;%endmacro

;***************************************************************************
; IN : (xmm0, EAX) col, EDX long, EDI Dest, ECX = 0
; change : EDI, EDX
;***************************************************************************
%macro  @SolidHLineSSE16    0
            TEST    EDI, 2
            JZ      SHORT %%FPasStBAv
            DEC     EDX
            MOV     [EDI],AX
            JZ      SHORT %%FinSHLine
            LEA     EDI,[EDI+2]
%%FPasStBAv:
            TEST    EDI, 4
            JZ      SHORT %%PasStDAv
            CMP     EDX,BYTE 2
            JL      SHORT %%StBAp
            MOV     [EDI],EAX
            SUB     EDX,BYTE 2
            LEA     EDI,[EDI+4]
%%PasStDAv:
            TEST    EDI, 8
            JZ      SHORT %%PasStQAv
            CMP     EDX,BYTE 4
            JL      SHORT %%StDAp
            MOVQ    [EDI],xmm0
            SUB     EDX,BYTE 4
            LEA     EDI,[EDI+8]
%%PasStQAv:
            SHLD    ECX,EDX,29 ; ECX = EDX >> 3  ECX should be equal to zero
            JZ      SHORT %%StQAp
ALIGN 4
%%StoSSE:   MOVDQA  [EDI],xmm0
            DEC     ECX
            LEA     EDI,[EDI+16]
            JNZ     SHORT %%StoSSE
            AND     DL,7
            JZ      SHORT %%FinSHLine
%%StQAp:    TEST    DL,4
            JZ      SHORT %%StDAp
            MOVQ    [EDI], xmm0
            LEA     EDI,[EDI+8]
%%StDAp:    TEST    DL,2
            JZ      SHORT %%StBAp
            STOSD
%%StBAp:    TEST    DL,1
            JZ      SHORT %%PasStBAp
            MOV     [EDI],AX
%%PasStBAp:
%%FinSHLine:
%endmacro

;****** TEXT
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7
; utilise xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
;***************************************************************************

; EAX : DYT, EBP : DXT

%macro  @InTextHLineNorm16 0
        IMUL        ESI,[SNegScanLine]    ; - 2
        JECXZ       %%PDivPntPXPY
        SAL         EAX,Prec
        SAL         EBP,Prec
        CDQ
        IDIV        ECX
        XCHG        EBP,EAX
        CDQ
        IDIV        ECX
        NEG         EBP
        MOVD        xmm1,EAX
        PINSRD      xmm1,EBP,1
        LEA         ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ        [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP         SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD         ESI,[Svlfb]
        CMP         CL,CL ; set FLAG ZERO
        MOV         AX,[ESI+EBX*2]
        JMP         %%LastB
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EBX,EBX
        OR          EAX,EAX
        SETS        BL
        PEXTRD      EAX,xmm1,1 ;[PntPlusY]
        MOV         EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X

        OR          EAX,EAX
        LEA         ECX,[ECX+1]
        SETS        BL
        ADD         ESI,[Svlfb]    ; - 5
        MOV         EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW        xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
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
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        DEC         CL
%%LastB:
        STOSW
        JNZ     %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdNormB16 0
        MOV         EBX,EBP
        MOV         EAX,EDX
        SAR         EBX,Prec
        SAR         EAX,Prec
        IMUL        EBX,[SScanLine]
        ADD         EBP,[PntPlusY]
        LEA         EBX,[EBX+EAX*2] ; xt *2 as 16bpp
        ADD         EDX,[PntPlusX]
%endmacro
%macro  @AjAdNormQ16 0
        MOV         EBX,EBP
        MOV         EAX,EDX
        SAR         EBX,Prec
        SAR         EAX,Prec
        IMUL        EBX,[SScanLine]
        ADD         EBP,[PntPlusY]
        LEA         EBX,[EBX+EAX*2]
        ADD         EDX,[PntPlusX]
%endmacro

;********************************************************

%macro  @InTextHLineDXZ16  0
        IMUL        ESI,[SNegScanLine]  ; - 2
        SAL         EAX,Prec
        JECXZ       %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb]  ; - 5
        CMP         CL,CL ; set FLAG ZERO
        MOV         AX,[ESI+EBX*2]
        JMP         %%LastB
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]      ; - 3
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb]  ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX ; [PntPlusY]
        SETG        DL
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y
        INC         ECX

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 pixels
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        [EDI],xmm0 ; write the 4 pixels
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
        DEC         CL
%%LastB:
        STOSW
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @AjAdDXZ16  0
        MOV         EBX,EDX
        SAR         EBX,Prec
        SUB         EDX,EBP ;-[PntPlusY]
        IMUL        EBX,[SScanLine]
%endmacro


%macro  @InTextHLineDYZ16 0
        MOV         EAX,EBP
        IMUL        ESI,[SNegScanLine] ; - 2
        SAL         EAX,Prec
        JECXZ       %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb] ; - 5
        CMP         CL,CL ; set FLAG ZERO
        MOV         AX,[ESI+EBX*2]
        JMP         %%LastB
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        OR          EAX,EAX         ; SAR
        LEA         ECX,[ECX+1]
        SETL        DL
        MOV         EBP,EAX  ;[PntPlusX]
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
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
        MOVDQU      [EDI],xmm0
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

%macro  @AjAdDYZ16  0
        MOV         EBX,EDX
        SAR         EBX,Prec
        ADD         EDX,EBP ;+[PntPlusX]
%endmacro

%macro  @InTextHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT

        OR          EAX,EAX   ; EAX = DYT
        JZ          %%CasDYZ

        OR          EBP,EBP   ; EBP = DXT
        JZ          %%CasDXZ
%%CasNorm:
        @InTextHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @InTextHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @InTextHLineDYZ16
%%FinInTextHLg:
%endmacro


;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7 & xmm3 & xmm4
;***************************************************************************
%macro  @ClipTextHLine16  0
        MOV         EAX,[YT2]
        MOV         EBP,[XT2]
        SUB         EAX,[YT1]   ; EAX = DY
        JZ          %%CasDYZ
        SUB         EBP,[XT1]   ; EBP = DX
        JZ          %%CasDXZ
%%CasNorm:
        @ClipTextHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @ClipTextHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @ClipTextHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro  @ClipTextHLineNorm16 0
        SAL         EAX,Prec
        MOV         ESI,[YT1]      ; - 1'
        CMP         DWORD [Plus2],BYTE 0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]    ; - 2'
        NEG         EAX
        LEA         ESI,[ESI+EBX*2] ; - 4' +2*XT1 : 16bpp
        MOV         [PntPlusY],EAX  ;[PntPlusY]
        MOV         EAX,EBP
        ADD         ESI,[Svlfb]    ; - 5'
        SAL         EAX,Prec
        CMP         DWORD [Plus2],BYTE 0
        JZ          %%PDivPPlusX
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR         EAX,EAX
%%DivPPlusX:
        MOV         EBP,[PntPlusY] ; - 1
        MOV         EBX,[Plus]
        MOV         [PntPlusX],EAX
        MOV         EDX,EAX ;  [PntPlusX]- 2
        IMUL        EBP,EBX        ; - 3
        IMUL        EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EAX,EAX
        CMP         DWORD [PntPlusY], BYTE 0
        SETS        AL
        ADD         EBP,[PntInitCPTDbrd+EAX*4]
        CMP         DWORD [PntPlusX], BYTE 0
        SETS        AL
        ADD         EDX,[PntInitCPTDbrd+EAX*4]

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
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
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        DEC         CL
        STOSW
        JNZ     %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro  @ClipTextHLineDXZ16  0
        MOV         ESI,[YT1]   ; - 1
        SAL         EAX,Prec
        IMUL        ESI,[SNegScanLine] ; - 2
        CMP         DWORD [Plus2],0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        MOV         EBP,EAX ; [PntPlusY]
        LEA         ESI,[ESI+EBX*2]   ; - 4(2) 16bpp
        MOV         EDX,[Plus]
        ADD         ESI,[Svlfb] ; - 5
        NEG         EDX
        IMUL        EDX,EBP ;-[PntPlusY] axe Y montant
        OR          EAX,EAX
        JLE         SHORT %%PosPntPlusY
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
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
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
        DEC         CL
        STOSW
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro  @ClipTextHLineDYZ16 0
        MOV         EBX,[XT1]
        MOV         ESI,[YT1]
        SUB         EBP,EBX
        IMUL        ESI,[SNegScanLine]
        MOV         EAX,EBP
        SHL         EAX,Prec
        CMP         DWORD [Plus2],0
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        MOV         EBP,EAX  ;[PntPlusX]
        LEA         ESI,[ESI+EBX*2] ; 16bpp
        MOV         EDX,[Plus]
        ADD         ESI,[Svlfb]
        IMUL        EDX,EBP ;+[PntPlusX]
        OR          EAX,EAX
        JGE         SHORT %%PosPntPlusX
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:

        TEST        CX,0xFFFC
        JZ          %%StBAp
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
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
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
        STOSW
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;****** MASKTEXT
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7
; utilise xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
;***************************************************************************
%macro  @InMaskTextHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT

        OR          EAX,EAX   ; EAX = DYT
        JZ          %%CasDYZ

        OR          EBP,EBP   ; EBP = DXT
        JZ          %%CasDXZ
%%CasNorm:
        @InMaskTextHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @InMaskTextHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @InMaskTextHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro  @InMaskTextHLineNorm16 0
        IMUL        ESI,[SNegScanLine]    ; - 2
;----------
        JECXZ       %%PDivPntPXPY
        SAL         EAX,Prec
        SAL         EBP,Prec
        CDQ
        IDIV        ECX
        XCHG        EBP,EAX
        CDQ
        IDIV        ECX
        NEG         EBP
        MOVD        xmm1,EAX
        PINSRD      xmm1,EBP,1
        LEA         ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ        [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP         SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD         ESI,[Svlfb]    ; - 5
        MOV         CL,1
        MOV         AX,[ESI+EBX*2]      ; - 4(2) as 16bpp
        JMP         %%LastB
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EBX,EBX
        OR          EAX,EAX
        SETL        BL
        PEXTRD      EAX,xmm1,1 ; EAX = [PntPlusY]
        ADD         ESI,[Svlfb]    ; - 5
        MOV         EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
        OR          EAX,EAX
        SETL        BL
        INC         ECX
        MOV         EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3 ; write the 8 bytes
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
        @AjAdNormB16
        MOV         AX,[EBX+ESI]
%%LastB:
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

%macro  @InMaskTextHLineDXZ16  0
        SAL         EAX,Prec
        IMUL        ESI,[SNegScanLine]  ; - 2
        CDQ
        JECXZ       %%PDivPntPX;JZ      %%PDivPntPX
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb]  ; - 5
        MOV         CL,1
        MOV         AX,[ESI+EBX*2]       ; ; - 4 (+XT1*2) as 16bpp
        JMP         %%LastB
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX  ;[PntPlusX]
        SETG        DL
        INC         ECX
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3 ; write the 8 bytes
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
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
%%LastB:
        CMP         AX,[SMask]
        JZ          SHORT %%NoPutBAp
        MOV         [EDI],AX
%%NoPutBAp:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;********************************************************

%macro  @InMaskTextHLineDYZ16 0
        MOV         EAX,EBP
        IMUL        ESI,[SNegScanLine] ; - 2
        SHL         EAX,Prec
        ;OR         ECX,ECX
        JECXZ       %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb]  ; - 5
        MOV         CL,1
        MOV         AX,[ESI+EBX*2]       ; ; - 4 (+XT1*2) as 16bpp
        JMP         %%LastB
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX  ;[PntPlusX]
        SETL        DL
        INC         ECX
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
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

        MOVDQU      xmm5,[EDI]
        MOVDQA      xmm3,xmm0
        MOVDQA      xmm4,xmm0

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3 ; write the 8 bytes
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
%%LastB:
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

;**Clip*MaskTEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7 & xmm3 & xmm4
;***************************************************************************
%macro  @ClipMaskTextHLine16  0
        MOV         EAX,[YT2]
        MOV         EBP,[XT2]
        SUB         EAX,[YT1]   ; EAX = DY
        JZ          %%CasDYZ
        SUB         EBP,[XT1]   ; EBP = DX
        JZ          %%CasDXZ
%%CasNorm:
        @ClipMaskTextHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @ClipMaskTextHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @ClipMaskTextHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro  @ClipMaskTextHLineNorm16 0
        SHL         EAX,Prec
        MOV         ESI,[YT1]      ; - 1'
        CMP         DWORD [Plus2],BYTE 0
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]    ; - 2'
        NEG         EAX
        MOV         EBX,[XT1]
        MOV         [PntPlusY],EAX  ;[PntPlusY]
        LEA         ESI,[ESI+EBX*2] ; - 4' +2*XT1 : 16bpp
        MOV         EAX,EBP
        ADD         ESI,[Svlfb]    ; - 5'
        SHL         EAX,Prec
        CMP         DWORD [Plus2],BYTE 0
        JZ          %%PDivPPlusX
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR         EAX,EAX
%%DivPPlusX:
        MOV         EBP,[PntPlusY] ; - 1
        MOV         EBX,[Plus]
        MOV         [PntPlusX],EAX
        MOV         EDX,EAX ; [PntPlusX] ; - 2
        IMUL        EBP,EBX        ; - 3
        IMUL        EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EAX,EAX
        CMP         DWORD [PntPlusY], BYTE 0
        SETS        AL
        ADD         EBP,[PntInitCPTDbrd+EAX*4]
        CMP         DWORD [PntPlusX], BYTE 0
        SETS        AL
        ADD         EDX,[PntInitCPTDbrd+EAX*4]
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
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
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm5,xmm7 ; [DQ16Mask]
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm1 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm5,xmm7 ; [DQ16Mask]
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        MOVQ        [EDI],xmm1 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          SHORT %%FinSHLine
%%BcStBAp:
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          SHORT %%NoPutBAp
        MOV         [EDI],AX
%%NoPutBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         SHORT %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;*******************************************************************
%macro  @ClipMaskTextHLineDXZ16  0
        MOV         ESI,[YT1]   ; - 1
        SAL         EAX,Prec
        IMUL        ESI,[SNegScanLine] ; - 2
        CMP         DWORD [Plus2],0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:       XOR     EAX,EAX
%%DivPPlusY:
        MOV         EBP,EAX ; [PntPlusY]
        LEA         ESI,[ESI+EBX*2]   ; - 4(2) 16bpp
        MOV         EDX,[Plus]
        ADD         ESI,[Svlfb] ; - 5
        NEG         EDX
        IMUL        EDX,EBP ;-[PntPlusY] axe Y montant
        OR          EAX,EAX
        JLE         SHORT %%PosPntPlusY
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
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
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm5,xmm7 ;[DQ16Mask]
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm1 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm5,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        MOVQ        [EDI],xmm1 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          SHORT %%NoPutBAp
        MOV         [EDI],AX
%%NoPutBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         SHORT %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro


;********************************************************

%macro  @ClipMaskTextHLineDYZ16 0
        MOV         EBX,[XT1]
        MOV         ESI,[YT1]
        SUB         EBP,EBX
        MOV         EAX,EBP
        SHL         EAX,Prec
        CMP         DWORD [Plus2],0
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]
        MOV         EBP,EAX  ;[PntPlusX]
        LEA         ESI,[ESI+EBX*2] ; 16bpp
        MOV         EDX,[Plus]
        ADD         ESI,[Svlfb]
        IMUL        EDX,EBP ;+[PntPlusX]
        OR          EAX,EAX
        JGE         SHORT %%PosPntPlusX
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
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

        MOVDQU      xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm5,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm1
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        MOVQ        xmm2,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm5,xmm0

        PCMPEQW     xmm1,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm5,xmm7 ; [DQ16Mask]
        PANDN       xmm1,xmm0
        PAND        xmm2,xmm5
        POR         xmm1,xmm2

        MOVQ        [EDI],xmm1
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
        JNZ         SHORT %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

;***** RGB
;***************************************************************************
; IN : ESI long, EDI Dest, EBP col1, EAX col2
;***************************************************************************


%macro  @InRGBHLine16   0
        MOVD        xmm2,EAX
        MOVD        xmm4,EBP ; *
        MOVD        xmm3,EAX
        MOVD        xmm5,EBP ; *
        PUNPCKLDQ   xmm2,xmm2
        PUNPCKLDQ   xmm4,xmm4
        PAND        xmm2,[MaskB_RGB16] ; xmm2 : Blue | green
        PAND        xmm4,[MaskB_RGB16] ; * xmm4 : Blue | green
        PAND        xmm3,[MaskR_RGB16] ; xmm3 : red | 0
        PAND        xmm5,[MaskR_RGB16] ; * xmm5 : red | 0

        PSUBD       xmm2,xmm4 ; xmm2 : DeltaBlue | DeltaGreen
        PSUBD       xmm3,xmm5 ; xmm3 : DeltaRed
        PSLLD       xmm2,Prec ; xmm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
        PSLLD       xmm4,Prec ; xmm4 : Col1_B<<Prec | Col1_G<<Prec
        MOVD        EAX,xmm2
        PSLLD       xmm5,Prec ; xmm5 : Col1_R<<Prec | -
        PSLLD       xmm3,Prec ; xmm3 : DeltaRed<<Prec

        XOR     EBX,EBX
        CDQ
        XOR     ECX,ECX
        IDIV        ESI
        PSRLQ       xmm2,32
        OR      EAX,EAX
        MOVD        xmm6,EAX ; xmm6 = PntBlue | -
        SETL        BL

        MOVD        EAX,xmm3
        OR      ECX,EBX
        CDQ
        IDIV        ESI
        OR      EAX,EAX
        MOVD        xmm7,EAX ; xmm7 = PntRed | -
        SETL        BL

        MOVD        EAX,xmm2
        LEA     ECX,[ECX+EBX*4]
        CDQ
        IDIV        ESI
        OR      EAX,EAX
        MOVD        xmm3,EAX ; xmm3 = PntGReen | -
        SETL        BL
        PUNPCKLDQ   xmm6,xmm6 ; xmm6 = PntBlue | PntBlue
        LEA     ECX,[ECX+EBX*2]
        PUNPCKLDQ   xmm3,xmm3 ; xmm3 = PntGreen | PntGReen
        SHL     ECX,4

        ; xmm6, xmm7 : pnt     B | B , R | -
        ; xmm3      : pnt     G | G
        ; xmm4, xmm5 : init shift  Col1B,Col1G,Col1R
        ; Free : EAX,EBX,ECX,EDX,EBP
        PADDD       xmm4,[RGBDebMask_GGG+ECX]   ; xmm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
        PADDD       xmm5,[RGBDebMask_GGG+ECX+8] ; xmm5 = cptDbrd R | - ;; += Col1R | -  Shifted
        MOVQ        xmm2,xmm4 ; xmm2 = cptDbrd B | cptDbrd G
        PUNPCKLDQ   xmm7,xmm7 ; xmm7 = PntR | PntR
        PUNPCKHDQ   xmm2,xmm2 ; xmm4 = cptDbrd G | cptDbrd G
        ; xmm4, xmm5 : cptDbrd B | B , cptDbrd R | R
        ; xmm2      : cptDbrd G | G
        ; xmm3, xmm6 : pnt G | G , pnt B | B
        ; xmm7      : pnt R | R

; start drawing the rgb16 hline

%%BcStBAv:  TEST        EDI,2
        JZ      %%FPasStBAv
        @HLnRGB16GEtP
        MOVD        EAX,xmm1
        DEC     ESI
        STOSW
        ;MOV        [EDI],AX
        ;LEA        EDI,[EDI+2]
        JZ      %%FinSHLine
%%FPasStBAv:
        CMP     ESI,BYTE 1
        JLE     %%StBAp
%%PasStDAv:
        MOVQ        xmm1,xmm4 ; = Cpt dbrd B| -
        MOVQ        xmm0,xmm5 ; = Cpt dbrd R| -
        MOV     ECX,ESI
        PADDD       xmm1,xmm6 ; += Pnt B | B
        PADDD       xmm0,xmm7 ; += Pnt R | R
        PUNPCKLDQ   xmm4,xmm1 ; xmm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
        PUNPCKLDQ   xmm5,xmm0 ; xmm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
        MOVQ        xmm1,xmm2 ; = cpt Dbrd G|G
        ;PSLLD      xmm6,1
        PADDD       xmm6,xmm6
        ;PSLLD      xmm7,1
        PADDD       xmm7,xmm7
        PADDD       xmm1,xmm3
        SHR     ECX,1
        PUNPCKLDQ   xmm2,xmm1 ; xmm2 = cpt dbrd G | (cpt dbrd G + Pnt G)
        ;PSLLD      xmm3,1
        PADDD       xmm3,xmm3
;ALIGN 4
%%StoMMX:   @HLnRGB16GEtP        ; word 0|1
        POR     xmm0,xmm1
        PSRLQ       xmm1,32
        PUNPCKLWD   xmm0,xmm1
        MOVD        [EDI],xmm0 ; write the 2 words
        DEC     ECX
        LEA     EDI,[EDI+4]
        JNZ     %%StoMMX
        PSRLD       xmm3,1
        PSRLD       xmm6,1
        PSRLD       xmm7,1

%%StBAp:    AND     ESI,BYTE 1
        JZ      %%PasStBAp
        @HLnRGB16GEtP
        MOVD        EAX,xmm1
        MOV     [EDI],AX
%%PasStBAp:

%%FinSHLine:

%endmacro


; get next pixel of a hlineRGB16
%macro  @HLnRGB16GEtP   0
        MOVQ        xmm0,xmm2 ; xmm0 = cptDbrd G|G
        MOVQ        xmm1,xmm5 ; xmm1 = cptDbrd R,R
        PSRLD       xmm0,Prec
        PSRLD       xmm1,Prec
        PAND        xmm0,[Mask2G_RGB16]
        PAND        xmm1,[Mask2R_RGB16]
        POR     xmm1,xmm0
        PADDD       xmm5,xmm7 ; = cptDbrd R|R + Pnt R|R
        MOVQ        xmm0,xmm4 ; xmm0 = cptDbrd B,B
        PADDD       xmm2,xmm3 ; = cptDbrd G|G + Pnt G|G
        PADDD       xmm4,xmm6 ; = cptDbrd B|B + Pnt B|B
        PSRLD       xmm0,Prec
        ;PAND       xmm0,[Mask2B_RGB16]
        POR     xmm1,xmm0
%endmacro




;***************************************************************************
; Clip RGBHLine : ECX long, EDI Dest, EBP col1, EAX col2, plus2 GlobDeltaX
; plus : number of pixel to jump before starting
;***************************************************************************

%macro  @ClipRGBHLine16 0
        MOVD        xmm2,EAX
        MOVD        xmm4,EBP ; *
        MOVD        xmm3,EAX
        MOVD        xmm5,EBP ; *
        PUNPCKLDQ   xmm2,xmm2
        PUNPCKLDQ   xmm4,xmm4
        PAND        xmm2,[MaskB_RGB16] ; xmm2 : Blue | green
        PAND        xmm4,[MaskB_RGB16] ; * xmm4 : Blue | green
        PAND        xmm3,[MaskR_RGB16] ; xmm3 : red | 0
        PAND        xmm5,[MaskR_RGB16] ; * xmm5 : red | 0

        PSUBD       xmm2,xmm4 ; xmm2 : DeltaBlue | DeltaGreen
        PSUBD       xmm3,xmm5 ; xmm3 : DeltaRed
        PSLLD       xmm4,Prec ; xmm4 : Col1_B<<Prec | Col1_G<<Prec
        PSLLD       xmm5,Prec ; xmm5 : Col1_R<<Prec | -
        PSLLD       xmm2,Prec ; xmm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
        PSLLD       xmm3,Prec ; xmm3 : DeltaRed<<Prec

        MOV     ESI,[Plus2]
        XOR     EBP,EBP
        OR      ESI,ESI
        JZ      %%Plus2Zero

        MOVD        EAX,xmm2
        XOR     EBX,EBX
        CDQ
        IDIV        ESI
        PSRLQ       xmm2,32
        OR      EAX,EAX
        MOVD        xmm6,EAX ; xmm6 = PntBlue | -
        SETL        BL

        MOVD        EAX,xmm3
        OR      EBP,EBX
        CDQ
        IDIV        ESI
        OR      EAX,EAX
        MOVD        xmm7,EAX ; xmm7 = PntRed | -
        SETL        BL

        MOVD        EAX,xmm2
        LEA     EBP,[EBP+EBX*4];
        CDQ
        IDIV        ESI
        OR      EAX,EAX
        MOVD        xmm3,EAX ; xmm3 = PntGReen | -
        SETL        BL
        PUNPCKLDQ   xmm6,xmm6 ; xmm6 = PntB | PntB
        LEA     EBP,[EBP+EBX*2]
        PUNPCKLDQ   xmm3,xmm3 ; xmm6 = PntG | PntG
        SHL     EBP,4
        JMP     SHORT %%Plus2SupZero
%%Plus2Zero:    XOR     EAX,EAX ; PntGReen
        PXOR        xmm6,xmm6 ; xmm6 : PntBlue=0 | PntB=0
        PXOR        xmm3,xmm3 ; xmm3 : PntG=0 | PntG=0
        PXOR        xmm7,xmm7 ; xmm7 : PntRed=0
%%Plus2SupZero:
        ; xmm6, xmm7 : pnt     B | B , R | -
        ; xmm3      : pnt     G | G
        ; xmm4, xmm5 : init shift  Col1B,Col1G,Col1R
        PADDD       xmm4,[RGBDebMask_GGG+EBP]   ; xmm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
        PADDD       xmm5,[RGBDebMask_GGG+EBP+8] ; xmm5 = cptDbrd R | - ;; += Col1R | -  Shifted
        MOVQ        xmm2,xmm4 ; xmm2 = cptDbrd B | cptDbrd G
        MOV     EBX,[Plus]
        PUNPCKLDQ   xmm7,xmm7 ; xmm7 = PntR | PntR
        OR      EBX,EBX
        PUNPCKHDQ   xmm2,xmm2 ; xmm4 = cptDbrd G | cptDbrd G
; Adjust CptDbrd if [Plus]>0
        JZ      %%PasAjPlus
        IMUL        EAX,EBX ; PntGReen*DeltaX
        MOVD        ESI,xmm6        ; EDI = Pnt Blue
        MOVD        xmm0,EAX
        MOVD        EDX,xmm7        ; EDX = Pnt Red
        IMUL        ESI,EBX ; PntBlue*DeltaX
        PADDD       xmm2,xmm0 ; cpt dbrd G + deltaG | -
        IMUL        EDX,EBX ; PntREd*DeltaY
        MOVD        xmm1,ESI
        MOVD        xmm0,EDX
        PADDD       xmm4,xmm1 ; cpt dbrd B + deltaB | -
        PADDD       xmm5,xmm0 ; cpt dbrd R + deltaR | -
%%PasAjPlus:
        ; xmm2, xmm3 : cptDbrd B,G,R
        ; xmm6, xmm7 : pnt     B,G,R
        ; xmm4, xmm5 : pnt     Col1B,Col1G,Col1R

; start drawing the rgb16 hline

%%BcStBAv:  TEST        EDI,2
        JZ      %%FPasStBAv
        @HLnRGB16GEtP
        MOVD        EAX,xmm1
        DEC     ECX
        STOSW
        JZ      %%FinSHLine
%%FPasStBAv:
        CMP     ECX,BYTE 1
        JLE     %%StBAp
%%PasStDAv:
        MOVQ        xmm1,xmm4 ; = Cpt dbrd B| -
        MOVQ        xmm0,xmm5 ; = Cpt dbrd R| -
        MOV     ESI,ECX
        PADDD       xmm1,xmm6 ; += Pnt B | B
        PADDD       xmm0,xmm7 ; += Pnt R | R
        PUNPCKLDQ   xmm4,xmm1 ; xmm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
        PUNPCKLDQ   xmm5,xmm0 ; xmm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
        MOVQ        xmm1,xmm2 ; = cpt Dbrd G|G
        ;PSLLD      xmm6,1
        PADDD       xmm6,xmm6
        ;PSLLD      xmm7,1
        PADDD       xmm7,xmm7
        PADDD       xmm1,xmm3
        SHR     ESI,1
        PUNPCKLDQ   xmm2,xmm1 ; xmm2 = cpt dbrd G | (cpt dbrd G + Pnt G)
        ;PSLLD      xmm3,1
        PADDD       xmm3,xmm3
;ALIGN 4
%%StoMMX:   @HLnRGB16GEtP        ; word 0
        POR     xmm0,xmm1
        PSRLQ       xmm1,32
        PUNPCKLWD   xmm0,xmm1
        MOVD        [EDI],xmm0 ; write the 2 words
        DEC     ESI
        LEA     EDI,[EDI+4]
        JNZ     %%StoMMX
        PSRLD       xmm3,1
        PSRLD       xmm6,1
        PSRLD       xmm7,1
%%StBAp:    AND     ECX,BYTE 1
        JZ      %%PasStBAp
        @HLnRGB16GEtP
        MOVD        EAX,xmm1
        MOV     [EDI],AX
%%PasStBAp:

%%FinSHLine:

;%%BcHlineRGB:
;       @HLnRGB16GEtP
;       MOVD        EAX,xmm1
;       DEC     ESI
;       MOV     [EDI],AX
;       LEA     EDI,[EDI+2]
;       JNZ     %%BcHlineRGB
%endmacro


;***** SOLID_BLND
;***************************************************************************
; IN : ESI long, EDI Dest, (xmm3, xmm4, xmm5) mul B G R dst, xmm7 mul src
;***************************************************************************

%macro  @SolidBlndHLine16   0
        TEST            EDI,2
        JZ              %%FPasStBAv
        MOV             AX,[EDI]
        MOVD            xmm0,EAX ; B
        MOVD            xmm1,EAX ; G
        ;MOVQ       mm2,mm0   ; R
        MOVD            xmm2,EAX      ; R
        @SolidBlndQ
        MOVD            EAX,xmm0
        DEC             ESI
        STOSW
        JZ              %%FinSHLine
%%FPasStBAv:
        TEST            EDI,4
        JZ              SHORT %%PasStDAv
        CMP             ESI,2
        JL              %%StBAp
        MOV             EAX,[EDI]
        MOVD            xmm0,EAX ; B
        MOVD            xmm1,EAX   ; G
        MOVD            xmm2,EAX      ; R
        @SolidBlndQ
        MOVD            [EDI],xmm0
        SUB             ESI,BYTE 2
        LEA             EDI,[EDI+4]
%%PasStDAv:
        SHLD            ECX,ESI,30 ; ECX = ESI >> 2, ECX should be zero
        JZ              %%StDAp
%%StoDQ:
        CMP             CX,BYTE 2
        JL              %%StoLastQ
        MOVDQU          xmm0,[EDI]
        SUB             CX,BYTE 2
        MOVDQA          xmm1,xmm0
        MOVDQA          xmm2,xmm0
        @SolidBlndQ
        MOVDQU          [EDI],xmm0
        LEA             EDI,[EDI+16]
        JZ              SHORT %%Ap
        JMP             SHORT %%StoDQ
%%StoLastQ:
        MOVQ            xmm0,[EDI]
        MOVDQA          xmm1,xmm0
        MOVDQA          xmm2,xmm0
        @SolidBlndQ
        XOR             ECX,ECX
        MOVQ            [EDI],xmm0
        LEA             EDI,[EDI+8]
%%Ap:
        AND             ESI,BYTE 3
        JZ              %%FinSHLine
%%StDAp:
        TEST            ESI,2
        JZ              SHORT %%StBAp
        MOV             EAX,[EDI] ; B
        MOVD            xmm0,EAX ; B
        MOVD            xmm1,EAX ; G
        MOVD            xmm2,EAX  ; R
        @SolidBlndQ
        MOVD            [EDI],xmm0
        SUB             ESI,BYTE 2
        LEA             EDI,[EDI+4]
%%StBAp:
        TEST            ESI,1
        JZ              SHORT %%PasStBAp
        MOV             AX,[EDI]
        MOVD            xmm0,EAX ; B
        MOVD            xmm1,EAX ; G
        MOVD            xmm2,EAX ; R
        @SolidBlndQ
        MOVD            EAX,xmm0
        STOSW
%%PasStBAp:
%%FinSHLine:

%endmacro

%macro  @SolidBlndQ 0
        PAND            xmm0,[QBlue16Mask]
        PAND            xmm1,[QGreen16Mask]
        PAND            xmm2,[QRed16Mask]
        PMULLW          xmm0,xmm7 ; [blend_src]
        PSRLW           xmm2,5
        PMULLW          xmm1,xmm7 ; [blend_src]
        PMULLW          xmm2,xmm7 ; [blend_src]
        PADDW           xmm0,xmm3
        PADDW           xmm1,xmm4
        PADDW           xmm2,xmm5
        PSRLW           xmm0,5
        PSRLW           xmm1,5
        PAND            xmm2,[QRed16Mask]
        ;PAND       mm0,[QBlue16Mask]
        PAND            xmm1,[QGreen16Mask]
        POR             xmm0,xmm2
        POR             xmm0,xmm1
%endmacro

%macro  @TransBlndQ 0
            PAND        xmm0,[QBlue16Mask]
            PAND        xmm3,[QBlue16Mask]
            PAND        xmm1,[QGreen16Mask]
            PAND        xmm4,[QGreen16Mask]
            PAND        xmm2,[QRed16Mask]
            PAND        xmm5,[QRed16Mask]
            PMULLW      xmm0,xmm7 ; [blend_src]
            PMULLW      xmm3,xmm6 ; [blend_dst]
            PSRLW       xmm2,5
            PSRLW       xmm5,5
            PMULLW      xmm4,xmm6 ; [blend_dst]
            PMULLW      xmm1,xmm7 ; [blend_src]
            PMULLW      xmm5,xmm6 ; [blend_dst]
            PMULLW      xmm2,xmm7 ; [blend_src]

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


;****** TEXT BLEND
;**IN*TEXTure BLEND Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, xmm0 = (XT1, YT1) xmm1 = (XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro  @InTextBlndHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT
        OR          EAX,EAX   ; EAX = DYT
        JZ          %%CasDYZ
        OR          EBP,EBP   ; EBP = DXT
        JZ          %%CasDXZ
%%CasNorm:
        @InTextBlndHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @InTextBlndHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @InTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro  @InTextBlndHLineNorm16 0
        IMUL        ESI,[SNegScanLine]    ; - 2
        ;JMP         %%FinSHLine
;----------
        JECXZ       %%PDivPntPXPY
        SAL         EAX,Prec
        SAL         EBP,Prec
        CDQ
        IDIV        ECX
        XCHG        EBP,EAX
        CDQ
        IDIV        ECX
        NEG         EBP
        MOVD        xmm1,EAX
        PINSRD      xmm1,EBP,1
        LEA         ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ        [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP         SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD         ESI,[Svlfb]    ; - 5
        MOV         CL,1
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%DoLast3W
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        ADD         ESI,[Svlfb]    ; - 5
        XOR         EBX,EBX
        OR          EAX,EAX
        SETL        BL
        PEXTRD      EAX,xmm1,1 ; EAX = [PntPlusY]
        MOV         EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
        OR          EAX,EAX
        SETL        BL
        INC         ECX
        MOV         EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        @InSolidTextBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @InSolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        CMP         CL,2
        @InSolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro

%macro  @InSolidTextBlndQ 0
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

%macro  @InSolidTextBlndW 0
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


%macro  @SolidTextBlndQ 0
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        PAND        xmm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        PAND        xmm2,[QRed16Mask]
        PMULLW      xmm0,[QMulSrcBlend]
        PSRLW       xmm2,5
        PMULLW      xmm1,[QMulSrcBlend]
        PMULLW      xmm2,[QMulSrcBlend]
        PADDW       xmm0,[QBlue16Blend]
        PADDW       xmm1,[QGreen16Blend]
        PADDW       xmm2,[QRed16Blend]
        PSRLW       xmm0,5
        PSRLW       xmm1,5
        PAND        xmm2,[QRed16Mask]
        ;PAND       mm0,[QBlue16Mask]
        PAND        xmm1,[QGreen16Mask]
        POR         xmm0,xmm2
        POR         xmm0,xmm1
%endmacro

%macro  @SolidTextBlndW 0
        MOVD        xmm0,EAX
        MOVD        xmm2,EAX ; R
        PUNPCKLWD   xmm0,xmm0 ; G | B
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]
        PSRLW       xmm2,5
        PMULLW      xmm0,[QMulSrcBlend]
        PMULLW      xmm2,[QMulSrcBlend]
        PADDW       xmm0,[WBGR16Blend]
        PADDW       xmm2,[QRed16Blend]
        PSRLW       xmm0,5
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]

        PSHUFLW     xmm1,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        POR         xmm2,xmm0
        POR         xmm2,xmm1
        ;MOVD        EAX,xmm2
%endmacro

%macro  @SolidTextBlndW_xmm0 0
        MOVDQA      xmm2,xmm0 ; R
        PUNPCKLWD   xmm0,xmm0 ; G | B
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]
        PSRLW       xmm2,5
        PMULLW      xmm0,[QMulSrcBlend]
        PMULLW      xmm2,[QMulSrcBlend]
        PADDW       xmm0,[WBGR16Blend]
        PADDW       xmm2,[QRed16Blend]
        PSRLW       xmm0,5
        PAND        xmm2,[QRed16Mask]
        PAND        xmm0,[WBGR16Mask]

        PSHUFLW     xmm1,xmm0,(0<<6) | (3<<4) | (2<<2) | (1)
        POR         xmm2,xmm0
        POR         xmm2,xmm1
        ;MOVD        EAX,xmm2
%endmacro

;********************************************************

%macro  @InTextBlndHLineDXZ16  0
        SAL         EAX,Prec
        IMUL        ESI,[SNegScanLine]  ; - 2
        JECXZ       %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb]  ; - 5
        MOV         CL,1
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%FinSHLine
        JMP         %%DoLast3W
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX  ;[PntPlusX]
        SETG        DL
        INC         ECX
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y

        TEST            CX,0xFFFC
        JZ              %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        @AjAdDXZ16
        SUB         CX,BYTE 4
        PINSRW      xmm0,[ESI+EBX], 3
        TEST        CX,0xFFFC
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        @InSolidTextBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @InSolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        CMP         CL,2
        @InSolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro

;********************************************************

%macro  @InTextBlndHLineDYZ16 0
        MOV         EAX,EBP
        IMUL        ESI,[SNegScanLine] ; - 2
        SHL         EAX,Prec
        JECXZ       %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb] ; - 5
        MOV         CL,1
        PINSRW      xmm0,[ESI+EBX*2],0 ; - 4 + (XT1*2) as 16bpp
        JMP         %%DoLast3W
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX  ;[PntPlusX]
        SETL        DL
        INC         ECX
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp
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

        @InSolidTextBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @InSolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],2
%%DoLast3W:
        CMP         CL,2
        @InSolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2
%%FinSHLine:
%endmacro

;%macro  @AjAdDYZ16  0
;       MOV     EBX,EDX
;       SAR     EBX,Prec
;       ADD     EDX,EBP ;+[PntPlusX]
;%endmacro

;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro  @ClipTextBlndHLine16  0
        MOV     EAX,[YT2]
        MOV     EBP,[XT2]
        SUB     EAX,[YT1]   ; EAX = DY
        JZ      %%CasDYZ
        SUB     EBP,[XT1]   ; EBP = DX
        JZ      %%CasDXZ
%%CasNorm:  @ClipTextBlndHLineNorm16
        JMP     %%FinInTextHLg
%%CasDXZ:   @ClipTextBlndHLineDXZ16
        JMP     %%FinInTextHLg
%%CasDYZ:   @ClipTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro  @ClipTextBlndHLineNorm16 0
        SHL     EAX,Prec
        MOV     ESI,[YT1]      ; - 1'
        CMP     DWORD [Plus2],0
        MOV     EBX,[XT1]
        JZ      %%PDivPPlusY
        CDQ
        IDIV    DWORD [Plus2]
        JMP     SHORT %%DivPPlusY
%%PDivPPlusY:   XOR     EAX,EAX
%%DivPPlusY:
        IMUL    ESI,[SNegScanLine]    ; - 2'
        NEG     EAX
        MOV     [PntPlusY],EAX  ;[PntPlusY]

        MOV     EAX,EBP
        LEA     ESI,[ESI+EBX*2]      ; - 4' +2*XT : 16bpp
        SHL     EAX,Prec
        ADD     ESI,[Svlfb]    ; - 5'
        CMP     DWORD [Plus2],0
        JZ      %%PDivPPlusX
        CDQ
        IDIV    DWORD [Plus2]
        JMP     SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR     EAX,EAX
%%DivPPlusX:
        MOV     EBP,[PntPlusY] ; - 1
        MOV     EBX,[Plus]
        MOV     [PntPlusX],EAX
        MOV     EDX,EAX ; [PntPlusX] ; - 2
        IMUL    EBP,EBX        ; - 3
        IMUL    EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR     EAX,EAX
        CMP     DWORD [PntPlusY], BYTE 0
        SETS    AL
        ADD     EBP,[PntInitCPTDbrd+EAX*4]
        CMP     DWORD [PntPlusX], BYTE 0
        SETS    AL
        ADD     EDX,[PntInitCPTDbrd+EAX*4]

        TEST    CX,0xFFFC
        JZ      %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7
        @SolidTextBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @SolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        CMP         CL,2
        @SolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro

;*******************************************************************
%macro  @ClipTextBlndHLineDXZ16  0
        MOV     ESI,[YT1]   ; - 1
        SAL     EAX,Prec
        IMUL    ESI,[SNegScanLine] ; - 2
        CMP     DWORD [Plus2],0
        MOV     EBX,[XT1]
        JZ      %%PDivPPlusY
        CDQ
        IDIV    DWORD [Plus2]
        JMP     SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR     EAX,EAX
%%DivPPlusY:
        MOV     EBP,EAX ; [PntPlusY]
        LEA     ESI,[ESI+EBX*2]   ; - 4(2) 16bpp
        MOV     EDX,[Plus]
        ADD     ESI,[Svlfb] ; - 5
        NEG     EDX
        IMUL    EDX,EBP ;-[PntPlusY] axe Y montant
        OR      EAX,EAX
        JLE     SHORT %%PosPntPlusY
        LEA     EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:

        TEST    CX,0xFFFC
        JZ      %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        @SolidTextBlndQ

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @SolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        CMP         CL,2
        @SolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro


;********************************************************

%macro  @ClipTextBlndHLineDYZ16 0
        MOV     EBX,[XT1]
        MOV     ESI,[YT1]
        SUB     EBP,EBX
        IMUL    ESI,[SNegScanLine]
        MOV     EAX,EBP
        SHL     EAX,Prec
        CMP     DWORD [Plus2],0
        JZ      %%PDivPPlusY
        CDQ
        IDIV    DWORD [Plus2]
        JMP     SHORT %%DivPPlusY
%%PDivPPlusY:   XOR     EAX,EAX
%%DivPPlusY:
        MOV     EBP,EAX  ;[PntPlusX]
        MOV     EDX,[Plus]
        LEA     ESI,[ESI+EBX*2] ; 16bpp
        IMUL    EDX,EBP ;+[PntPlusX]
        ADD     ESI,[Svlfb]
        OR      EAX,EAX
        JGE     SHORT %%PosPntPlusX
        LEA     EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:

        TEST    CX,0xFFFC
        JZ      %%StBAp
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
        @SolidTextBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 8 bytes
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         SHORT %%StBAp
%%StoLastQ:
        @SolidTextBlndQ
        MOVQ        [EDI],xmm0 ; write the 8 bytes
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],2
%%DoLast3W:
        CMP         CL,2
        @SolidTextBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro


;****** MASKTEXT BLEND
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7
; utilise mm5,mm4,mm3,mm2,mm1,mm0
;***************************************************************************
%macro  @InMaskTextBlndHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT
        OR          EAX,EAX   ; EAX = DYT
        JZ          %%CasDYZ
        OR          EBP,EBP   ; EBP = DXT
        JZ          %%CasDXZ
%%CasNorm:
        @InMaskTextBlndHLineNorm16
        JMP         %%FinInTextHLg
%%CasDXZ:
        @InMaskTextBlndHLineDXZ16
        JMP         %%FinInTextHLg
%%CasDYZ:
        @InMaskTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

; AX : DYT, EBP : DXT

%macro  @InMaskTextBlndHLineNorm16 0
        IMUL            ESI,[SNegScanLine]    ; - 2
;----------
        JECXZ           %%PDivPntPXPY
        SAL             EAX,Prec
        SAL             EBP,Prec
        CDQ
        IDIV            ECX
        XCHG            EBP,EAX
        CDQ
        IDIV            ECX
        NEG             EBP
        MOVD            xmm1,EAX
        PINSRD          xmm1,EBP,1
        LEA             ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ            [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP             SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD             ESI,[Svlfb]    ; - 5
        MOV             CL,1
        MOV             AX,[ESI+EBX*2]      ; - 4(2) as 16bpp
        JMP             %%LastB
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR             EBX,EBX
        OR              EAX,EAX
        SETL            BL
        PEXTRD          EAX,xmm1,1 ; EAX = [PntPlusY]
        ADD             ESI,[Svlfb]    ; - 5
        MOV             EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X
        OR              EAX,EAX
        SETL            BL
        INC             ECX
        MOV             EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST            CX,0xFFFC
        JZ              %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 2
        @AjAdNormQ16
        SUB             CX,BYTE 4
        PINSRW          xmm0,[ESI+EBX], 3
        TEST            CX,0xFFFC
        JZ              %%StoLastQ

        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW          xmm0,[ESI+EBX], 7

        MOVDQA          xmm4,xmm0
        @SolidTextBlndQ

        MOVDQU      xmm5,[EDI]
        MOVDQA      xmm3,xmm4

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3
        TEST        CX,0xFFFC
        LEA        EDI,[EDI+16]
        JNZ        %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVQ        xmm5,[EDI]
        MOVDQA      xmm3,xmm4

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm5,xmm4
        POR         xmm3,xmm5

        MOVQ        [EDI],xmm3
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdNormB16
        MOV         AX,[EBX+ESI]
%%LastB:
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro

;********************************************************

%macro  @InMaskTextBlndHLineDXZ16  0
        SAL             EAX,Prec
        IMUL            ESI,[SNegScanLine]  ; - 2
        CDQ
        JECXZ           %%PDivPntPX;JZ      %%PDivPntPX
        IDIV            ECX
        JMP             SHORT %%DivPntPX
%%PDivPntPX:
        ADD             ESI,[Svlfb]  ; - 5
        MOV             CL,1
        MOV             AX,[ESI+EBX*2]       ; ; - 4 (+XT1*2) as 16bpp
        JMP             %%LastB
%%DivPntPX:
        LEA             ESI,[ESI+EBX*2]      ; ; - 4 (+XT1*2) as 16bpp
        MOV             EBP,EAX ; [PntPlusY]
        XOR             EBX,EBX      ; Cpt Dbrd Y
        ADD             ESI,[Svlfb]  ; - 5
        OR              EAX,EAX
        SETG            BL
        INC             ECX
        MOV             EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST            CX,0xFFFC
        JZ              %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
      PINSRW        xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQU      xmm1,[EDI]
        MOVDQA      xmm3,xmm4

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm1,xmm4
        POR         xmm3,xmm1

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ        %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVQ        xmm1,[EDI]
        MOVDQA      xmm3,xmm4

        PCMPEQW     xmm3,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm3,xmm0
        PAND        xmm1,xmm4
        POR         xmm3,xmm1
        MOVQ            [EDI],xmm3
        LEA        EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
%%LastB:
        CMP         AX,[SMask]
        JZ              %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro

;%macro  @AjAdDXZ16  0
;       MOV     EBX,EDX
;       SAR     EBX,Prec
;       SUB     EDX,EBP ;-[PntPlusY]
;       IMUL        EBX,[SScanLine]
;%endmacro
;********************************************************

%macro  @InMaskTextBlndHLineDYZ16 0
        MOV     EAX,EBP
        IMUL    ESI,[SNegScanLine] ; - 2
        SHL     EAX,Prec
        ;OR     ECX,ECX
        JECXZ   %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV    ECX
        JMP     SHORT %%DivPntPX
%%PDivPntPX:
        ADD     ESI,[Svlfb]  ; - 5
        MOV     CL,1
        MOV     AX,[ESI+EBX*2]       ; ; - 4 (+XT1*2) as 16bpp
        JMP     %%LastB
%%DivPntPX:
        LEA     ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        ADD     ESI,[Svlfb] ; - 5
        XOR     EBX,EBX      ; Cpt Dbrd Y
        OR      EAX,EAX         ; SAR
        MOV     EBP,EAX  ;[PntPlusX]
        SETL    BL
        INC     ECX
        MOV     EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST    CX,0xFFFC
        JZ      %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        @AjAdDYZ16
        SUB         CX, BYTE 4
        PINSRW      xmm0,[ESI+EBX*2], 3
        TEST        CX,0xFFFC
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7

        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQU      xmm1,[EDI]
        MOVDQA      xmm3,xmm4

        PCMPEQW     xmm3,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm3,xmm0
        PAND        xmm1,xmm4
        POR         xmm3,xmm1

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm3
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVQ        xmm4,xmm0
        @SolidTextBlndQ
        MOVQ        xmm1,[EDI]
        MOVQ        xmm3,xmm4

        PCMPEQW     xmm3,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm3,xmm0
        PAND        xmm1,xmm4
        POR         xmm3,xmm1
        MOVQ        [EDI],xmm3
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
%%LastB:
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro

;%macro  @AjAdDYZ16  0
;       MOV     EBX,EDX
;       SAR     EBX,Prec
;       ADD     EDX,EBP ;+[PntPlusX]
;%endmacro

;**Clip*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser mm6 & mm7 & mm3 & mm4
;***************************************************************************
%macro  @ClipMaskTextBlndHLine16  0
        MOV     EAX,[YT2]
        MOV     EBP,[XT2]
        SUB     EAX,[YT1]   ; EAX = DY
        JZ      %%CasDYZ
        SUB     EBP,[XT1]   ; EBP = DX
        JZ      %%CasDXZ
%%CasNorm:  @ClipMaskTextBlndHLineNorm16
        JMP     %%FinInTextHLg
%%CasDXZ:   @ClipMaskTextBlndHLineDXZ16
        JMP     %%FinInTextHLg
%%CasDYZ:   @ClipMaskTextBlndHLineDYZ16
%%FinInTextHLg:
%endmacro

%macro  @ClipMaskTextBlndHLineNorm16 0
        SHL         EAX,Prec
        MOV         ESI,[YT1]      ; - 1'
        CMP         DWORD [Plus2],0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]    ; - 2'
        NEG         EAX
        LEA         ESI,[ESI+EBX*2] ; - 4' +2*XT : 16bpp
        MOV         [PntPlusY],EAX  ;[PntPlusY]
        MOV         EAX,EBP
        ADD         ESI,[Svlfb]    ; - 5'
        SHL         EAX,Prec
        CMP         DWORD [Plus2],0
        JZ          %%PDivPPlusX
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR         EAX,EAX
%%DivPPlusX:
        MOV         EBP,[PntPlusY] ; - 1
        MOV         EBX,[Plus]
        MOV         [PntPlusX],EAX
        MOV         EDX,EAX ; [PntPlusX] - 2
        IMUL        EBP,EBX        ; - 3
        IMUL        EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EAX,EAX
        CMP         DWORD [PntPlusY], BYTE 0
        SETS        AL
        ADD         EBP,[PntInitCPTDbrd+EAX*4]
        CMP         DWORD [PntPlusX], BYTE 0
        SETS        AL
        ADD         EDX,[PntInitCPTDbrd+EAX*4]
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          %%NoDWAv
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine
        JMP         %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQA      xmm1,xmm4
        MOVDQU      xmm5,[EDI]

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm1
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQA      xmm1,xmm4
        MOVQ        xmm5,[EDI]

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5
        MOVQ        [EDI],xmm1
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro

;*******************************************************************
%macro  @ClipMaskTextBlndHLineDXZ16  0
        MOV         ESI,[YT1]   ; - 1
        SAL         EAX,Prec
        IMUL        ESI,[SNegScanLine] ; - 2
        CMP         DWORD [Plus2],0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        MOV         EBP,EAX ; [PntPlusY]
        LEA         ESI,[ESI+EBX*2]   ; - 4(2) 16bpp
        MOV         EDX,[Plus]
        ADD         ESI,[Svlfb] ; - 5
        NEG         EDX

        IMUL        EDX,EBP ;-[PntPlusY] axe Y montant
        OR          EAX,EAX
        JLE         SHORT %%PosPntPlusY
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusY:
%%BcStBAv:
        TEST        EDI,3
        JZ          %%FPasStBAv
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          %%NoDWAv
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine

        JMP         %%BcStBAv
%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdDXZ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdDXZ16
        PINSRW      xmm0,[ESI+EBX], 7
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQA      xmm1,xmm4
        MOVDQU      xmm5,[EDI]

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm1
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ
        MOVDQA      xmm1,xmm4
        MOVQ        xmm5,[EDI]

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5

        MOVQ        [EDI],xmm1
        LEA         EDI,[EDI+8]

%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDXZ16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%FinSHLine:
%endmacro


;********************************************************

%macro  @ClipMaskTextBlndHLineDYZ16 0

        MOV         EBX,[XT1]
        MOV         ESI,[YT1]
        SUB         EBP,EBX
        MOV         EAX,EBP
        SHL         EAX,Prec
        CMP         DWORD [Plus2],0
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        MOV         EBP,EAX  ;[PntPlusX]
        IMUL        ESI,[SNegScanLine]
        MOV         EDX,[Plus]
        LEA         ESI,[ESI+EBX*2] ; + XT1 * 2 as 16bpp
        IMUL        EDX,EBP ;+[PntPlusX]
        ADD         ESI,[Svlfb]
        OR          EAX,EAX
        JGE         SHORT %%PosPntPlusX
        LEA         EDX,[EDX+((1<<Prec)-1)] ; EDX += 2**N-1
%%PosPntPlusX:
%%BcStBAv:
        TEST        EDI,6
        JZ          %%FPasStBAv
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JZ          %%NoDWAv
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAv:
        DEC         ECX
        LEA         EDI,[EDI+2]
        JZ          %%FinSHLine
        JMP         %%BcStBAv

%%FPasStBAv:
        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        @AjAdDYZ16
        SUB         CX, BYTE 4
        PINSRW      xmm0,[ESI+EBX*2], 3
        TEST        CX,0xFFFC
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7
        MOVDQA      xmm4,xmm0
        @SolidTextBlndQ

        MOVDQA      xmm1,xmm4
        MOVDQU      xmm5,[EDI]

        PCMPEQW     xmm1,xmm7
        PCMPEQW     xmm4,xmm7
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5

        SUB         CX, BYTE 4
        MOVDQU      [EDI],xmm1
        TEST        CX,0xFFFC
        LEA         EDI,[EDI+16]
        JNZ         %%StoMMX
        JMP         %%StBAp
%%StoLastQ:
        MOVQ        xmm4,xmm0
        @SolidTextBlndQ

        MOVQ        xmm1,xmm4
        MOVQ        xmm5,[EDI]

        PCMPEQW     xmm1,xmm7 ; [DQ16Mask]
        PCMPEQW     xmm4,xmm7 ; [DQ16Mask]
        PANDN       xmm1,xmm0
        PAND        xmm5,xmm4
        POR         xmm1,xmm5

        MOVQ        [EDI],xmm1
        LEA         EDI,[EDI+8]
%%StBAp:
        AND         CL,3
        JZ          %%FinSHLine
%%BcStBAp:
        @AjAdDYZ16
        MOV         AX,[ESI+EBX*2]
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        @SolidTextBlndW
        PEXTRW      [EDI],xmm2,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro


;****** TEXT_TRANS
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7
; utilise xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
;***************************************************************************

; AX : DYT, EBP : DXT

%macro  @InTextTransHLineNorm16 0
        IMUL        ESI,[SNegScanLine]    ; - 2
        JECXZ       %%PDivPntPXPY
        SAL         EAX,Prec
        SAL         EBP,Prec
        CDQ
        IDIV        ECX
        XCHG        EBP,EAX
        CDQ
        IDIV        ECX
        NEG         EBP
        MOVD        xmm1,EAX
        PINSRD      xmm1,EBP,1
        LEA         ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ        [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP         SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD         ESI,[Svlfb]
        MOV         CL,1 ; set FLAG ZERO
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%DoLast3W
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EBX,EBX
        OR          EAX,EAX
        SETL        BL
        PEXTRD      EAX,xmm1,1 ;[PntPlusY]
        MOV         EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X

        OR          EAX,EAX
        LEA         ECX,[ECX+1]
        SETL        BL
        ADD         ESI,[Svlfb]    ; - 5
        MOV         EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y

        TEST        CX,0xFFFC
        JZ          %%StBAp

;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 16 bytes

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

        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdNormB16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdNormB16
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdNormB16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        CMP         CL,2
        @TransBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2

%%FinSHLine:
%endmacro

%macro  @InTextTransHLineDYZ16 0
        MOV         EAX,EBP
        IMUL        ESI,[SNegScanLine] ; - 2
        SHL         EAX,Prec
        JECXZ       %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV        ECX
        JMP         SHORT %%DivPntPX
%%PDivPntPX:
        ADD         ESI,[Svlfb] ; - 5
        MOV         CL,1
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX*2],0 ; - 4 + (XT1*2) as 16bpp
        JMP         %%DoLast3W
%%DivPntPX:
        LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        XOR         EDX,EDX      ; Cpt Dbrd Y
        ADD         ESI,[Svlfb] ; - 5
        CMP         EAX,EDX
        MOV         EBP,EAX  ;[PntPlusX]
        SETL        DL
        INC         ECX
        MOV         EDX,[PntInitCPTDbrd+EDX*4] ; Cpt Dbr Y
        TEST        CX,0xFFFC
        JZ          %%StBAp
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

        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 16 bytes

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
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdDYZ16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX*2],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdDYZ16
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX*2],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdDYZ16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX*2],0
        @AjAdDYZ16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX*2],1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2],2
%%DoLast3W:
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        CMP         CL,2
        @TransBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2
%%FinSHLine:
%endmacro


%macro  @InTransTextHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT
        OR          EAX,EAX
        JZ          %%DYZ
        @InTextTransHLineNorm16
        JMP         %%endHLine
%%DYZ:
        @InTextTransHLineDYZ16
%%endHLine:
%endmacro

%macro  @ClipTransTextHLine16  0
        MOV         EAX,[YT2]
        MOV         EBP,[XT2]
        SUB         EAX,[YT1]   ; EAX = DY
        SUB         EBP,[XT1]   ; EBP = DX
        @ClipTransTextHLineNorm16
%endmacro

%macro  @ClipTransTextHLineNorm16 0
        SHL         EAX,Prec
        MOV         ESI,[YT1]      ; - 1'
        CMP         DWORD [Plus2],BYTE 0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]    ; - 2'
        NEG         EAX
        LEA         ESI,[ESI+EBX*2] ; - 4' +2*XT1 : 16bpp
        MOV         [PntPlusY],EAX  ;[PntPlusY]
        MOV         EAX,EBP
        ADD         ESI,[Svlfb]    ; - 5'
        SHL         EAX,Prec
        CMP         DWORD [Plus2],BYTE 0
        JZ          %%PDivPPlusX
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR         EAX,EAX
%%DivPPlusX:
        MOV         EBP,[PntPlusY] ; - 1
        MOV         EBX,[Plus]
        MOV         [PntPlusX],EAX
        MOV         EDX,EAX ;  [PntPlusX]- 2
        IMUL        EBP,EBX        ; - 3
        IMUL        EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EAX,EAX
        CMP         DWORD [PntPlusY], BYTE 0
        SETS        AL
        ADD         EBP,[PntInitCPTDbrd+EAX*4]
        CMP         DWORD [PntPlusX], BYTE 0
        SETS        AL
        ADD         EDX,[PntInitCPTDbrd+EAX*4]
        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7
        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ
        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm0 ; write the 16 bytes

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
        CMP         CL,2
        JG          %%DoLastPre3W
        JL          %%DoLastPre1W
%%DoLastPre2W:
        @AjAdNormB16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX],1
        JMP         %%DoLast3W
%%DoLastPre1W:
        @AjAdNormB16
        PINSRW      xmm3,[EDI],0
        PINSRW      xmm0,[ESI+EBX],0
        JMP         %%DoLast3W
%%DoLastPre3W:
        @AjAdNormB16
        MOVD        xmm3,[EDI]
        PINSRW      xmm0,[ESI+EBX],0
        @AjAdNormB16
        PINSRW      xmm3,[EDI+4],2
        PINSRW      xmm0,[ESI+EBX],1
        @AjAdNormB16
        PINSRW      xmm0,[ESI+EBX],2
%%DoLast3W:
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        CMP         CL,2
        @TransBlndQ
        JG          SHORT %%DoLastPost3W
        JL          SHORT %%DoLastPost1W
%%DoLastPost2W:
        MOVD        [EDI],xmm0
        JMP         SHORT %%FinSHLine
%%DoLastPost1W:
        PEXTRW      [EDI],xmm0,0
        JMP         SHORT %%FinSHLine
%%DoLastPost3W:
        MOVD        [EDI],xmm0
        PEXTRW      [EDI+4],xmm0,2
%%FinSHLine:
%endmacro

;****** MASK_TEXT_TRANS
;**IN*TEXTure Horizontal Line***********************************************
; IN : EDI Dest, ECX Long, (XT1, YT1, XT2, YT2)
; a ne pas utiliser xmm6 & xmm7
; utilise xmm5,xmm4,xmm3,xmm2,xmm1,xmm0
;***************************************************************************

; AX : DYT, EBP : DXT

%macro  @InMaskTextTransHLineNorm16 0
        IMUL        ESI,[SNegScanLine]    ; - 2
        JECXZ       %%PDivPntPXPY
        SAL         EAX,Prec
        SAL         EBP,Prec
        CDQ
        IDIV        ECX
        XCHG        EBP,EAX
        CDQ
        IDIV        ECX
        NEG         EBP
        MOVD        xmm1,EAX
        PINSRD      xmm1,EBP,1
        LEA         ESI,[ESI+EBX*2]      ; - 4(2) as 16bpp
        MOVQ        [PntPlusX],xmm1 ; [PntPlusX]|[PntPlusY]

        JMP         SHORT %%DivPntPXPY
%%PDivPntPXPY:
        ADD         ESI,[Svlfb]
        MOV         CL,1
        MOV         AX,[ESI+EBX*2]
        JMP         %%LastB
%%DivPntPXPY:
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EBX,EBX
        OR          EAX,EAX
        SETL        BL
        PEXTRD      EAX,xmm1,1 ;[PntPlusY]
        MOV         EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr X

        OR          EAX,EAX
        LEA         ECX,[ECX+1]
        SETL        BL
        ADD         ESI,[Svlfb]    ; - 5
        MOV         EBP,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
        TEST        CX,0xFFFC
        JZ          %%StBAp

;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7

        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm7,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        SUB         CX,BYTE 4
        MOVDQA      xmm1,xmm7
        MOVDQU      xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4
        MOVDQU      [EDI],xmm7 ; write the Masked 16 bytes

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
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
%%LastB:
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

%macro  @InMaskTransTextHLineDYZ16 0
        MOV     EAX,EBP
        IMUL    ESI,[SNegScanLine] ; - 2
        SHL     EAX,Prec
        ;OR     ECX,ECX
        JECXZ   %%PDivPntPX ;JZ     %%PDivPntPX
        CDQ
        IDIV    ECX
        JMP     SHORT %%DivPntPX
%%PDivPntPX:
        ADD     ESI,[Svlfb]  ; - 5
        MOV     CL,1
        MOV     AX,[ESI+EBX*2]       ; ; - 4 (+XT1*2) as 16bpp
        JMP     %%LastB
%%DivPntPX:
        LEA     ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
        ADD     ESI,[Svlfb] ; - 5
        XOR     EBX,EBX      ; Cpt Dbrd Y
        OR      EAX,EAX         ; SAR
        MOV     EBP,EAX  ;[PntPlusX]
        SETL    BL
        INC     ECX
        MOV     EDX,[PntInitCPTDbrd+EBX*4] ; Cpt Dbr Y
        TEST    CX,0xFFFC
        JZ      %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 0
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 1
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 2
        @AjAdDYZ16
        SUB         CX, BYTE 4
        PINSRW      xmm0,[ESI+EBX*2], 3
        TEST        CX,0xFFFC
        JZ          %%StoLastQ

        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 4
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 5
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 6
        @AjAdDYZ16
        PINSRW      xmm0,[ESI+EBX*2], 7

        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm7,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        MOVDQA      xmm1,xmm7
        MOVDQU      xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4

        SUB         CX,BYTE 4
        MOVDQU      [EDI],xmm7 ; write the Masked 16 bytes
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
%%LastB:
        CMP         AX,[SMask]
        JZ          %%NoDWAp
        PINSRW      xmm3,[EDI],0
        MOVD        xmm0,EAX
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ_QMulSrcBlend
        PEXTRW      [EDI],xmm0,0
%%NoDWAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp

%%FinSHLine:
%endmacro


%macro  @InMaskTransTextHLine16  0
        PSUBD       xmm1,xmm0 ; DXT | DYT
        PEXTRD      ESI,xmm0, 1 ; = [YT1]
        MOVD        EBX,xmm0 ; = [XT1]
        PEXTRD      EAX,xmm1, 1 ; DYT
        MOVD        EBP,xmm1 ; DXT
        OR          EAX,EAX
        JZ          %%DYZ
        @InMaskTextTransHLineNorm16
        JMP         %%EndHLine
%%DYZ:
        @InMaskTransTextHLineDYZ16
%%EndHLine:
%endmacro

%macro  @ClipMaskTransTextHLineNorm16 0
        SHL         EAX,Prec
        MOV         ESI,[YT1]      ; - 1'
        CMP         DWORD [Plus2],BYTE 0
        MOV         EBX,[XT1]
        JZ          %%PDivPPlusY
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusY
%%PDivPPlusY:
        XOR         EAX,EAX
%%DivPPlusY:
        IMUL        ESI,[SNegScanLine]    ; - 2'
        NEG         EAX
        LEA         ESI,[ESI+EBX*2] ; - 4' +2*XT1 : 16bpp
        MOV         [PntPlusY],EAX  ;[PntPlusY]
        MOV         EAX,EBP
        ADD         ESI,[Svlfb]    ; - 5'
        SHL         EAX,Prec
        CMP         DWORD [Plus2],BYTE 0
        JZ          %%PDivPPlusX
        CDQ
        IDIV        DWORD [Plus2]
        JMP         SHORT %%DivPPlusX
%%PDivPPlusX:
        XOR         EAX,EAX
%%DivPPlusX:
        MOV         EBP,[PntPlusY] ; - 1
        MOV         EBX,[Plus]
        MOV         [PntPlusX],EAX
        MOV         EDX,EAX ;  [PntPlusX]- 2
        IMUL        EBP,EBX        ; - 3
        IMUL        EDX,EBX        ; - 4
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        XOR         EAX,EAX
        CMP         DWORD [PntPlusY], BYTE 0
        SETS        AL
        ADD         EBP,[PntInitCPTDbrd+EAX*4]
        CMP         DWORD [PntPlusX], BYTE 0
        SETS        AL
        ADD         EDX,[PntInitCPTDbrd+EAX*4]
        TEST        CX,0xFFFC
        JZ          %%StBAp
;ALIGN 4
%%StoMMX:
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 0
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 1
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 2
        SUB         CX,BYTE 4
        @AjAdNormQ16
        TEST        CX,0xFFFC
        PINSRW      xmm0,[ESI+EBX], 3
        JZ          %%StoLastQ

        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 4
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 5
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 6
        @AjAdNormQ16
        PINSRW      xmm0,[ESI+EBX], 7
        MOVDQU      xmm3,[EDI]
        MOVDQA      xmm1,xmm0
        MOVDQA      xmm2,xmm0
        MOVDQA      xmm7,xmm0
        MOVDQA      xmm4,xmm3
        MOVDQA      xmm5,xmm3
        @TransBlndQ_QMulSrcBlend
        SUB         CX,BYTE 4
        MOVDQA      xmm1,xmm7
        MOVDQU      xmm4,[EDI]

        PCMPEQW     xmm7,[DQ16Mask]
        PCMPEQW     xmm1,[DQ16Mask]
        PANDN       xmm7,xmm0
        PAND        xmm4,xmm1
        POR         xmm7,xmm4
        MOVDQU      [EDI],xmm7 ; write the 8 bytes

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
        @AjAdNormB16
        MOV         AX,[ESI+EBX]
        CMP         AX,[SMask]
        JE          %%NoStBAp
        PINSRW      xmm3,[EDI],0
        MOVD        xmm0,EAX
        MOVQ        xmm4,xmm3
        MOVQ        xmm5,xmm3
        MOVQ        xmm1,xmm0
        MOVQ        xmm2,xmm0
        @TransBlndQ_QMulSrcBlend
        PEXTRW      [EDI],xmm0,0
%%NoStBAp:
        DEC         CL
        LEA         EDI,[EDI+2]
        JNZ         %%BcStBAp
%%PasStBAp:
%%FinSHLine:
%endmacro

%macro  @ClipMaskTransTextHLine16  0
        MOV         EAX,[YT2]
        MOV         EBP,[XT2]
        SUB         EAX,[YT1]   ; EAX = DY
        SUB         EBP,[XT1]   ; EBP = DX
        @ClipMaskTransTextHLineNorm16
%endmacro
