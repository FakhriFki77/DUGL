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


%macro  @FILLRET    0
    JMP Poly16.PasDrawPoly
%endmacro
; ****** DUMMY
dummyFill16:
      @FILLRET

;******* POLYTYPE = SOLID
InFillSOLID16:
        MOV         EBX,[DebYPoly]  ; -
        LEA         ESI,[EBX*4] ; -
        PSHUFLW     xmm0,[clr], 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
        SUB         EBX,[FinYPoly]  ; -
        MOVD        EAX,xmm0 ; assign the 16bpp color to the low
        NEG         EBX     ; -
        PUNPCKLQDQ  xmm0,xmm0
        XOR         ECX,ECX ; ECX = 0, SolidHLineSSE16 requirement
;ALIGN 4
.BcFillSolid16:
      MOV           EDI,[TPolyAdDeb+ESI+EBX*4]
        MOV         EDX,[TPolyAdFin+ESI+EBX*4]
        CMP         EDX,EDI
        JG          SHORT .PasSwapAd
        XCHG        EDI,EDX
.PasSwapAd:
        SUB         EDX,EDI
        SHR         EDX,1
        INC         EDX
        @SolidHLineSSE16
        DEC         EBX
        JNS         .BcFillSolid16
    @FILLRET

ALIGN 32
ClipFillSOLID16:
        MOV         EBP,[FinYPoly]
        MOV         EBX,[DebYPoly]
        SUB         EBP,[OrgY]
        IMUL        EBP,[NegScanLine]
        LEA         ESI,[EBX*4]
        PSHUFLW     xmm0,[clr], 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
        SUB         EBX,[FinYPoly]
        PUNPCKLQDQ  xmm0,xmm0 ; xmm0 = clr16 | clr16 | clr16 | clr16
        NEG         EBX
        MOVD        EAX,xmm0 ; assign the 16bpp color to the low
        ADD         EBP,[vlfb]
        XOR         ECX,ECX
;ALIGN 4
.BcFillSolid:
        MOV         EDI,[TPolyAdDeb+ESI+EBX*4]
        MOV         EDX,[TPolyAdFin+ESI+EBX*4]
        CMP         EDX,EDI
        JG          .PasSwapAd
        XCHG        EDI,EDX
.PasSwapAd:
        CMP         EDX,[MinX]     ; [XP2] < [MinX]
        JL          .PasDrwClSD
        CMP         EDI,[MaxX]     ; [XP1] > [MaxX]
        JG          .PasDrwClSD

        CMP         EDX,[MaxX]
        JLE         SHORT .NoClipMaxX
        MOV         EDX,[MaxX]
.NoClipMaxX:
        CMP         EDI,[MinX]
        JGE         SHORT .NoClipMinX
        MOV         EDI,[MinX]
.NoClipMinX:
        SUB         EDX,EDI
        INC         EDX
        LEA         EDI,[EBP+EDI*2] ; += xDeb *2 as 16bpp
        @SolidHLineSSE16
.PasDrwClSD:
        ADD         EBP,[ScanLine]
        DEC         EBX
        JNS         .BcFillSolid
.FinClipSOLID:
    @FILLRET

;******* POLYTYPE = TEXT

ALIGN 32
InFillTEXT16:
        @InCalcTextCnt
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EBX,[DebYPoly] ; -
        MOV         EDI,SrcSurf
        LEA         EDX,[EBX*4]    ; -
        CopySurfDA  ; copy the source texture surface
        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        NEG         EBX        ; -  EBX = FinYPoly-DebYPoly
        LEA         EDX,[EDX+EBX*4]
ALIGN 4
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX]
        MOVD        xmm1,[TexXFin+EDX]
        MOV         EDI,[TPolyAdDeb+EDX]
        MOV         ECX,[TPolyAdFin+EDX]
        MOVD        xmm6,EDX
        MOVD        xmm7,EBX
        CMP         ECX,EDI
        PINSRD      xmm0,[TexYDeb+EDX],1
        PINSRD      xmm1,[TexYFin+EDX],1

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InTextHLine16
        MOVD        EDX,xmm6
        MOVD        EBX,xmm7
        SUB         EDX,BYTE 4
        DEC         EBX
        JNS         InFillTEXT16.BcFillText
    @FILLRET

ALIGN 32
ClipFillTEXT16:
        @ClipCalcTextCnt
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf

        MOV         EBP,[FinYPoly]
        CopySurfDA  ; copy the source texture surface
        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        NEG         EBX        ; -
        MOVD        xmm3,EBP
        MOVD        xmm4,[ScanLine]
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        MOVD        xmm7,EBX
        MOVD        xmm6,EDX
        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,xmm3
        SUB         ECX,EDI
        MOV         [Plus],EAX
        ;SHL        EDI,1 ; 16bpp : xdeb*2
        INC         ECX
        ;ADD        EDI,ESI
        LEA         EDI,[ESI+EDI*2]
        @ClipTextHLine16
.PasDrwClTx:
        MOVD        EBX,xmm7
        MOVD        EDX,xmm6
        DEC         EBX
        PADDD       xmm3,xmm4
        JNS         .BcFillText
.FinClipText:
    @FILLRET


        ;******* POLYTYPE = MASK_TEXT
ALIGN 32
InFillMASK_TEXT16:

        @InCalcTextCnt
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EBX,[DebYPoly] ; -
        MOV         EDI,SrcSurf
        CopySurfDA  ; copy the source texture surface
        LEA         EDX,[EBX*4]    ; -
        PSHUFLW     xmm7,[SMask], 0 ; xmm0 = SMask | SMask | SMask | SMask
        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        PUNPCKLQDQ  xmm7,xmm7
        NEG         EBX        ; -  EBX = FinYPoly-DebYPoly
        ;MOVDQA      [DQ16Mask],xmm7
ALIGN 4
.BcFillMaskText:
        MOVD        xmm6,EBX
        PINSRD      xmm6,EDX,1
        LEA         EBX,[EDX+EBX*4]
        MOV         EDI,[TPolyAdDeb+EBX]
        MOV         ECX,[TPolyAdFin+EBX]
        MOVD        xmm0,[TexXDeb+EBX]
        MOVD        xmm1,[TexXFin+EBX]
        CMP         ECX,EDI
        PINSRD      xmm0,[TexYDeb+EBX],1
        PINSRD      xmm1,[TexYFin+EBX],1

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InMaskTextHLine16
        MOVD        EBX,xmm6
        PEXTRD      EDX,xmm6,1
        DEC         EBX
        JNS     .BcFillMaskText

    @FILLRET

ALIGN 32
ClipFillMASK_TEXT16:
        @ClipCalcTextCnt
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf

        MOV         EBP,[FinYPoly]
        CopySurfDA  ; copy the source texture surface
        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        PSHUFLW     xmm7,[SMask], 0 ; xmm4 = SMask | SMask | SMask | SMask
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        PUNPCKLQDQ  xmm7,xmm7
        NEG         EBX         ; -
        ;MOVDQA     [DQ16Mask],xmm7
        MOVD        xmm3,EBP
        ;MOVD       xmm4,[ScanLine]
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        MOVD        xmm6,EBX
        PINSRD      xmm6,EDX,1
        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,xmm3
        SUB         ECX,EDI
        MOV         [Plus],EAX
        INC         ECX
        LEA         EDI,[ESI+EDI*2]
        @ClipMaskTextHLine16
.PasDrwClTx:
        MOVD        EBX,xmm6
        PEXTRD      EDX,xmm6,1
        DEC         EBX
        PADDD       xmm3,[ScanLine]
        JNS         .BcFillText
.FinClipText:
    @FILLRET


; POLY TYPE : RGB16

ALIGN 32
InFillRGB16:
        @InCalcRGB_Cnt16

        MOV         EBX,[DebYPoly]  ; -
        LEA         EDX,[EBX*4] ; -
        SUB         EBX,[FinYPoly]  ; -
        NEG         EBX     ; -
;ALIGN 4
.BcFillRGB16:
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]
        MOV         ESI,[TPolyAdFin+EDX+EBX*4]
        MOV         EBP,[PColDeb+EDX+EBX*4] ; col1
        MOV         EAX,[PColFin+EDX+EBX*4] ; col2
        CMP         ESI,EDI
        JG          .PasSwapAd
        XCHG        EDI,ESI
.PasSwapAd:
        SUB         ESI,EDI
        PUSH        EDX
        SHR         ESI,1
        PUSH        EBX
        INC         ESI

        @InRGBHLine16

        POP         EBX
        POP         EDX
        DEC         EBX
        JNS     .BcFillRGB16

    @FILLRET


ALIGN 32
ClipFillRGB16:
        @ClipCalcRGB_Cnt16

        MOV     EBP,[FinYPoly]
        SUB     EBP,[OrgY]
        MOV     EBX,[DebYPoly] ; -
        IMUL    EBP,[NegScanLine]
        LEA     EDX,[EBX*4]    ; -
        SUB     EBX,[FinYPoly] ; -
        ADD     EBP,[vlfb]
        NEG     EBX        ; -
        MOV     ESI,EBP
.BcFillRGB16:
        MOV     ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        MOV     EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV     EBP,[PColDeb+EDX+EBX*4]
        MOV     EAX,[PColFin+EDX+EBX*4]
        MOV     [Col1],EBP
        MOV     [Col2],EAX

        CMP     ECX,EDI
        JG      .PasSwapAd
        XCHG    EDI,ECX
.PasSwapAd:
        PUSH    EDX
        PUSH    EBX
        MOV     EBX,[MinX]
        MOV     EDX,[MaxX]
        CMP     ECX,EBX     ; [XP2] < [MinX]
        JL      .PasDrwClTx
        CMP     EDI,EDX     ; [XP1] > [MaxX]
        JG      .PasDrwClTx
        SUB     ECX,EDI
        MOV     [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR     EAX,EAX
        ADD     ECX,EDI
        CMP     ECX,EDX     ; [XP2] > [MaxX]
        JLE     .PasAJX2
        MOV     ECX,EDX
.PasAJX2:
        CMP     EDI,EBX     ; [XP1] < [MinX]
        JGE     .PasAJX1
        MOV     EAX,EBX
        SUB     EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV     EDI,EBX
.PasAJX1:
        SUB     ECX,EDI ; XFin-xDeb
        MOV     [Plus],EAX
        ;SHL    EDI,1 ; xDeb*2 as 16bpp
        INC     ECX
        ;ADD    EDI,ESI
        LEA     EDI,[ESI+EDI*2]
        MOV     EBP,[Col1]
        MOV     EAX,[Col2]
        PUSH    ESI
        @ClipRGBHLine16
        POP     ESI
.PasDrwClTx:
        POP     EBX
        POP     EDX
        ADD     ESI,[ScanLine]
        DEC     EBX
        JNS     .BcFillRGB16
.FinClipDEG:

    @FILLRET



;******* POLYTYPE = SOLID_BLND
ALIGN 32
InFillSOLID_BLND16:
; prepare blending
        MOV         EAX,[clr] ;
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;
        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        JZ          .EndInBlend ; nothing 0 is the source
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        MOV         EBP,EAX
        XOR         AL,BlendMask ; 31-blendsrc
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm5,xmm5,0
        MOV         EBX,[DebYPoly]   ; -
        LEA         EDX,[EBX*4]  ; -
        MOVD        xmm7,EBP
        SUB         EBX,[FinYPoly]   ; -
        PSHUFLW     xmm7,xmm7,0
        NEG         EBX      ; -
        PUNPCKLQDQ  xmm3,xmm3
        PUNPCKLQDQ  xmm4,xmm4
        PUNPCKLQDQ  xmm5,xmm5
        PUNPCKLQDQ  xmm7,xmm7
        XOR         ECX,ECX
;ALIGN 4
.BcFillSolid16:
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]
        MOV         ESI,[TPolyAdFin+EDX+EBX*4]
        CMP         ESI,EDI
        JG          .PasSwapAd
        XCHG        EDI,ESI
.PasSwapAd:
        SUB         ESI,EDI
        SHR         ESI,1
        INC         ESI
        @SolidBlndHLine16
        DEC         EBX
        JNS         .BcFillSolid16
.EndInBlend:
    @FILLRET


ALIGN 32
ClipFillSOLID_BLND16:
        MOV         EAX,[clr] ;
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;
        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        JZ          .FinClipSOLID ; nothing 0 is the source
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        MOV         EBP,EAX
        XOR         AL,BlendMask ; 31-blendsrc
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        MOVD        xmm7,EBP
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm5,xmm5,0
        PSHUFLW     xmm7,xmm7,0

        MOV         EBP,[FinYPoly]
        MOV         EBX,[DebYPoly]
        SUB         EBP,[OrgY]
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]
        PUNPCKLQDQ  xmm3,xmm3
        SUB         EBX,[FinYPoly]
        PUNPCKLQDQ  xmm4,xmm4
        NEG         EBX
        PUNPCKLQDQ  xmm5,xmm5
        ADD         EBP,[vlfb]
        PUNPCKLQDQ  xmm7,xmm7
        XOR         ECX,ECX
;ALIGN 4
.BcFillSolid:
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]
        MOV         ESI,[TPolyAdFin+EDX+EBX*4]
        CMP         ESI,EDI
        JG          .PasSwapAd
        XCHG        EDI,ESI
.PasSwapAd:
        CMP         ESI,[MinX]     ; [XP2] < [MinX]
        JL          .PasDrwClSD
        CMP         EDI,[MaxX]     ; [XP1] > [MaxX]
        JG          .PasDrwClSD

        CMP         ESI,[MaxX]
        CMOVG       ESI,[MaxX]
        CMP         EDI,[MinX]
        CMOVL       EDI,[MinX]
        SUB         ESI,EDI
        INC         ESI
        LEA         EDI,[EBP+EDI*2] ; += xDeb *2 as 16bpp
        @SolidBlndHLine16
.PasDrwClSD:
        ADD         EBP,[ScanLine]
        DEC         EBX
        JNS        .BcFillSolid
.FinClipSOLID:
    @FILLRET


;******* POLYTYPE = TEXT_BLND
ALIGN 32
InFillTEXT_BLND16:
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf
        CopySurfDA  ; copy the source texture surface

        @InCalcTextCnt
; prepare blending
        MOV         EAX,[clr] ;
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;
        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        ;JZ     InFillTEXT16
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        MOV         EBP,EAX
        XOR         AL,BlendMask ; 31-blendsrc
        ;JZ     InFillSOLID16 ; 31 mean no blend flat color
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOV         [WBGR16Blend],BX
        MOV         [WBGR16Blend+2],CX
        MOV         [WBGR16Blend+4],DX
        MOVD        xmm7,EBP
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm5,xmm5,0
        PUNPCKLQDQ  xmm3,xmm3
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm4,xmm4
        PUNPCKLQDQ  xmm5,xmm5

        ;MOVDQA     [QMulSrcBlend],xmm7

; end prepare blend
        MOV         EBX,[DebYPoly] ; -
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        NEG         EBX       ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:
        MOVD        xmm6,EDX
        PINSRD      xmm6,EBX,1
        LEA         EBX,[EDX+EBX*4]
        MOV         EDI,[TPolyAdDeb+EBX]
        MOV         ECX,[TPolyAdFin+EBX]
        MOVD        xmm0,[TexXDeb+EBX]
        MOVD        xmm1,[TexXFin+EBX]
        CMP         ECX,EDI
        PINSRD      xmm0,[TexYDeb+EBX],1
        PINSRD      xmm1,[TexYFin+EBX],1

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InTextBlndHLine16
        PEXTRD      EBX,xmm6,1
        MOVD        EDX,xmm6
        DEC         EBX
        JNS         InFillTEXT_BLND16.BcFillText
    @FILLRET

ALIGN 32
ClipFillTEXT_BLND16:
        @ClipCalcTextCnt

        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf
        CopySurfDA  ; copy the source texture surface

; prepare blending
        MOV         EAX,[clr] ;
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;
        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        MOV         EBP,EAX
        XOR         AL,BlendMask ; 31-blendsrc
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOV         [WBGR16Blend],BX
        MOV         [WBGR16Blend+2],CX
        MOV         [WBGR16Blend+4],DX
        MOVD        xmm7,EBP
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm5,xmm5,0
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm3,xmm3
        PUNPCKLQDQ  xmm4,xmm4
        PUNPCKLQDQ  xmm5,xmm5

        MOVDQA      [QMulSrcBlend],xmm7
        MOVDQA      [QBlue16Blend],xmm3
        MOVDQA      [QGreen16Blend],xmm4
        MOVDQA      [QRed16Blend],xmm5

; end prepare blend

        MOV         EBP,[FinYPoly]
        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        NEG         EBX         ; -
        MOVD        xmm6,EBP
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        MOVD        xmm7,EBX
        PINSRD      xmm7,EDX,1

        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,xmm6
        SUB         ECX,EDI
        MOV         [Plus],EAX
        ;SHL        EDI,1 ; 16bpp : xdeb*2
        INC         ECX
        ;ADD        EDI,ESI
        LEA         EDI,[ESI+EDI*2]
        @ClipTextBlndHLine16
.PasDrwClTx:
        MOVD        EBX,xmm7
        PEXTRD      EDX,xmm7,1
        DEC         EBX
        PADDD       xmm6,[ScanLine]
        JNS         .BcFillText
.FinClipText:

    @FILLRET


        ;******* POLYTYPE = MASK_TEXT_BLND
ALIGN 32
InFillMASK_TEXT_BLND16:
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf
        CopySurfDA  ; copy the source texture surface

        @InCalcTextCnt
; prepare blending
        MOV         EAX,[clr] ;
        PSHUFLW     xmm7,[SMask],0
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;

        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        PUNPCKLQDQ  xmm7,xmm7
        ;JZ     InFillTEXT16
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        ;MOVDQA     [DQ16Mask],xmm7
        MOV         EBP,EAX
        XOR         AL,BlendMask ; 31-blendsrc
        ;JZ     InFillSOLID16 ; 31 mean no blend flat color
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOV         [WBGR16Blend],BX
        MOV         [WBGR16Blend+2],CX
        MOV         [WBGR16Blend+4],DX
        MOVD        xmm6,EBP
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm6,xmm6,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm5,xmm5,0
        PUNPCKLQDQ  xmm6,xmm6
        PUNPCKLQDQ  xmm3,xmm3
        PUNPCKLQDQ  xmm4,xmm4
        PUNPCKLQDQ  xmm5,xmm5
        MOVDQA      [QMulSrcBlend],xmm6
        MOVDQA      [QBlue16Blend],xmm3
        MOVDQA      [QGreen16Blend],xmm4
        MOVDQA      [QRed16Blend],xmm5

; end prepare blend
        MOV         EBX,[DebYPoly] ; -
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        NEG         EBX        ; -  EBX = FinYPoly-DebYPoly
;ALIGN 4
.BcFillText:
        MOVD        xmm6,EDX
        PINSRD      xmm6,EBX,1
        LEA         EBX,[EDX+EBX*4]
        MOV         EDI,[TPolyAdDeb+EBX]
        MOV         ECX,[TPolyAdFin+EBX]
        MOVD        xmm0,[TexXDeb+EBX]
        MOVD        xmm1,[TexXFin+EBX]
        CMP         ECX,EDI
        PINSRD      xmm0,[TexYDeb+EBX],1
        PINSRD      xmm1,[TexYFin+EBX],1

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InMaskTextBlndHLine16
        PEXTRD      EBX,xmm6,1
        MOVD        EDX,xmm6
        DEC         EBX
        JNS         .BcFillText

    @FILLRET

ALIGN 32
ClipFillMASK_TEXT_BLND16:

        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        MOV         EDI,SrcSurf
        CopySurfDA  ; copy the source texture surface

; prepare blending
        MOV         EAX,[clr] ;
        MOV         EBX,EAX ;
        MOV         ECX,EAX ;
        MOV         EDX,EAX ;
        AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
        SHR         EAX,24
        AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
        AND         AL,BlendMask ; remove any ineeded bits
        AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
        XOR         AL,BlendMask ; 31-blendsrc
        MOV         BP,AX
        XOR         AL,BlendMask ; 31-blendsrc
        INC         AL
        SHR         DX,5 ; right shift red 5bits
        IMUL        BX,AX
        IMUL        CX,AX
        IMUL        DX,AX
        MOV         [WBGR16Blend],BX
        MOV         [WBGR16Blend+2],CX
        MOV         [WBGR16Blend+4],DX
        MOVD        xmm1,EBP
        MOVD        xmm3,EBX
        MOVD        xmm4,ECX
        MOVD        xmm5,EDX
        PSHUFLW     xmm3,xmm3,0
        PSHUFLW     xmm1,xmm1,0
        PSHUFLW     xmm4,xmm4,0
        PSHUFLW     xmm5,xmm5,0
        PUNPCKLQDQ  xmm1,xmm1
        PUNPCKLQDQ  xmm3,xmm3
        PUNPCKLQDQ  xmm4,xmm4
        PUNPCKLQDQ  xmm5,xmm5

        MOVDQA      [QMulSrcBlend],xmm1
        MOVDQA      [QBlue16Blend],xmm3
        MOVDQA      [QGreen16Blend],xmm4
        MOVDQA      [QRed16Blend],xmm5
; end prepare blend
        @ClipCalcTextCnt

        PSHUFLW     xmm7,[SMask],0
        MOV         EBP,[FinYPoly]
        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        IMUL        EBP,[NegScanLine]
        PUNPCKLQDQ  xmm7,xmm7
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        NEG         EBX        ; -
        ;MOVDQA      [DQ16Mask],xmm7
        MOVD        xmm6,EBP
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        PUSH        EBX
        PUSH        EDX
        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,xmm6
        SUB         ECX,EDI
        MOV         [Plus],EAX
        INC         ECX
        LEA         EDI,[ESI+EDI*2]
        @ClipMaskTextBlndHLine16
.PasDrwClTx:
        POP         EDX
        POP         EBX
        DEC         EBX
        PADDD       xmm6,[ScanLine]
        JNS         .BcFillText
.FinClipText:

    @FILLRET


;******* POLYTYPE = TEXT_TRANS

ALIGN 32
InFillTEXT_TRANS16:
        @InCalcTextCnt
        MOV         ESI,[SSSurf] ; save pointer to source surf
        MOV         EBX,[DebYPoly] ; -
        MOV         EAX,[clr] ;
        MOV         EDI,SrcSurf ; destination
        LEA         EDX,[EBX*4]    ; -
        AND         EAX,BYTE BlendMask
        JZ          .End ; zero transparency no need to draw any thing
        CopySurfDA  ; copy the source texture surface

        MOV         ECX,EAX ;
        INC         EAX

        XOR         CL,BlendMask ; 31-blendsrc
        MOVD        xmm7,EAX
        MOVD        xmm6,ECX
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm6,xmm6,0
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm6,xmm6

        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        NEG         EBX        ; -  EBX = FinYPoly-DebYPoly
        LEA         EDX,[EDX+EBX*4]
ALIGN 4
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX]
        MOVD        xmm1,[TexXFin+EDX]
        MOV         EDI,[TPolyAdDeb+EDX]
        MOV         ECX,[TPolyAdFin+EDX]
        MOVD        mm6,EDX
        MOVD        mm7,EBX
        CMP         ECX,EDI
        PINSRD      xmm0,[TexYDeb+EDX],1
        PINSRD      xmm1,[TexYFin+EDX],1

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InTransTextHLine16
        MOVD        EDX,mm6
        MOVD        EBX,mm7
        SUB         EDX,BYTE 4
        DEC         EBX
        JNS         .BcFillText
        EMMS
.End:
    @FILLRET

ALIGN 32
ClipFillTEXT_TRANS16:
        @ClipCalcTextCnt
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source

        MOV         EAX,[clr] ;
        MOV         EDI,SrcSurf ; destination
        AND         EAX,BYTE BlendMask
        MOV         EBP,[FinYPoly]
        JZ          .End ; zero transparency no need to draw any thing

        CopySurfDA  ; copy the source texture surface
        MOV         ECX,EAX ;
        INC         EAX
        XOR         CL,BlendMask ; 31-blendsrc
        MOVD        xmm7,EAX
        MOVD        xmm6,ECX
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm6,xmm6,0
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm6,xmm6

        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        NEG         EBX        ; -
        MOVD        mm3,EBP
        MOVD        mm4,[ScanLine]
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        MOVD        mm7,EBX
        MOVD        mm6,EDX
        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,mm3
        SUB         ECX,EDI
        MOV         [Plus],EAX
        INC         ECX
        LEA         EDI,[ESI+EDI*2]
        @ClipTransTextHLine16
.PasDrwClTx:
        MOVD        EBX,mm7
        MOVD        EDX,mm6
        DEC         EBX
        PADDD       mm3,mm4
        JNS     .BcFillText
        EMMS
.End:
    @FILLRET

;******* POLYTYPE = MASK_TEXT_TRANS
ALIGN 32
InFillMASK_TEXT_TRANS16:

        @InCalcTextCnt
        MOV         ESI,[SSSurf] ; save pointer to source surf
        MOV         EBX,[DebYPoly] ; -
        MOV         EAX,[clr] ;
        MOV         EDI,SrcSurf ; destination
        AND         EAX,BYTE BlendMask
        LEA         EDX,[EBX*4]    ; -
        JZ          .End ; zero transparency no need to draw any thing
        CopySurfDA  ; copy the source texture surface

        MOV         ECX,EAX ;
        PSHUFLW     xmm0,[SMask],0
        INC         EAX

        XOR         CL,BlendMask ; 31-blendsrc
        MOVD        xmm7,EAX
        MOVD        xmm6,ECX
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm6,xmm6,0
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm6,xmm6
        PUNPCKLQDQ  xmm0,xmm0
        MOVDQA      [QMulSrcBlend],xmm7
        MOVDQA      [DQ16Mask],xmm0

        SUB         EBX,[FinYPoly] ; -  EBX = DebYPoly-FinYPoly
        NEG         EBX        ; -  EBX = FinYPoly-DebYPoly
        LEA         EDX,[EDX+EBX*4]
ALIGN 4
.BcFillMaskText:
        MOVD        xmm0,[TexXDeb+EDX]
        MOVD        xmm1,[TexXFin+EDX]
        MOV         EDI,[TPolyAdDeb+EDX]
        MOV         ECX,[TPolyAdFin+EDX]
        MOVD        mm6,EDX
        MOVD        mm7,EBX
        PINSRD      xmm0,[TexYDeb+EDX],1
        PINSRD      xmm1,[TexYFin+EDX],1

        CMP         ECX,EDI
        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        SUB         ECX,EDI
        SHR         ECX,1
        @InMaskTransTextHLine16
        MOVD        EDX,mm6
        MOVD        EBX,mm7
        SUB         EDX,BYTE 4
        DEC         EBX
        JNS         .BcFillMaskText
        EMMS
.End:
    @FILLRET


ALIGN 32
ClipFillMASK_TEXT_TRANS16:
        @ClipCalcTextCnt
        MOV         EAX,[clr] ;
        MOV         ESI,[SSSurf] ; sauvegarde la surf Source
        AND         EAX,BYTE BlendMask
        MOV         EDI,SrcSurf
        JZ          .End ; zero transparency no need to draw any thing

        MOV         EBP,[FinYPoly]
        CopySurfDA  ; copy the source texture surface

        MOV         ECX,EAX ;
        INC         EAX

        XOR         CL,BlendMask ; 31-blendsrc
        MOVD        xmm7,EAX
        MOVD        xmm6,ECX
        PSHUFLW     xmm7,xmm7,0
        PSHUFLW     xmm6,xmm6,0
        PUNPCKLQDQ  xmm7,xmm7
        PUNPCKLQDQ  xmm6,xmm6


        SUB         EBP,[OrgY]
        MOV         EBX,[DebYPoly] ; -
        PSHUFLW     xmm0,[SMask], 0 ; xmm0 = SMask | SMask | SMask | SMask
        IMUL        EBP,[NegScanLine]
        LEA         EDX,[EBX*4]    ; -
        SUB         EBX,[FinYPoly] ; -
        ADD         EBP,[vlfb]
        PUNPCKLQDQ  xmm0,xmm0
        NEG         EBX        ; -
        MOVDQA      [QMulSrcBlend],xmm7
        MOVDQA      [DQ16Mask],xmm0
        MOVD        mm3,EBP
        MOVD        mm4,[ScanLine]
.BcFillText:
        MOVD        xmm0,[TexXDeb+EDX+EBX*4]   ; XT1
        MOVD        xmm1,[TexXFin+EDX+EBX*4]   ; XT2
        MOV         EDI,[TPolyAdDeb+EDX+EBX*4]  ; X1
        MOV         ECX,[TPolyAdFin+EDX+EBX*4]  ; X2
        PINSRD      xmm0,[TexYDeb+EDX+EBX*4],1 ; YT1
        PINSRD      xmm1,[TexYFin+EDX+EBX*4],1 ; YT2
        CMP         ECX,EDI
        MOVQ        [XT1],xmm0 ; XT1 | YT1
        MOVQ        [XT2],xmm1 ; XT2 | YT2

        JG          .PasSwapAd
        XCHG        EDI,ECX
.PasSwapAd:
        MOVD        mm6,EBX
        MOVD        mm7,EDX
        MOV         EBX,[MinX]
        MOV         EDX,[MaxX]
        CMP         ECX,EBX     ; [XP2] < [MinX]
        JL          .PasDrwClTx
        CMP         EDI,EDX     ; [XP1] > [MaxX]
        JG          .PasDrwClTx
        SUB         ECX,EDI
        MOV         [Plus2],ECX ; Plus2 = DltX sans ajust
        XOR         EAX,EAX
        ADD         ECX,EDI
        CMP         ECX,EDX     ; [XP2] > [MaxX]
        CMOVG       ECX,EDX
        CMP         EDI,EBX     ; [XP1] < [MinX]
        JGE         .PasAJX1
        MOV         EAX,EBX
        SUB         EAX,EDI         ; EAX = [MinX] - [XP1]
        MOV         EDI,EBX
.PasAJX1:
        MOVD        ESI,mm3
        SUB         ECX,EDI
        MOV         [Plus],EAX
        INC         ECX
        LEA         EDI,[ESI+EDI*2]
        @ClipMaskTransTextHLine16
.PasDrwClTx:
        MOVD        EBX,mm6
        MOVD        EDX,mm7
        DEC         EBX
        PADDD       mm3,mm4
        JNS         .BcFillText
        EMMS
.End:
    @FILLRET
