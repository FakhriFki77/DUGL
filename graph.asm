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


%include "PARAM.asm"
%include "DGUTILS.asm"

; enable windows/linux win32/elf32 building
%pragma elf32 gprefix
%pragma win32 gprefix   _

; GLOBAL Functions
GLOBAL  DgSetCurSurf, DgSetSrcSurf, DgGetCurSurf
GLOBAL  DgClear16, ClearSurf16, InBar16, DgPutPixel16, DgCPutPixel16, DgGetPixel16, DgCGetPixel16

GLOBAL  line16, Line16, linemap16, LineMap16, lineblnd16, LineBlnd16, linemapblnd16, LineMapBlnd16
GLOBAL  Poly16, RePoly16, PutSurf16, PutMaskSurf16, PutSurfBlnd16, PutMaskSurfBlnd16, PutSurfTrans16, PutMaskSurfTrans16
GLOBAL  ResizeViewSurf16, MaskResizeViewSurf16, TransResizeViewSurf16, MaskTransResizeViewSurf16, BlndResizeViewSurf16, MaskBlndResizeViewSurf16
GLOBAL  SurfMaskCopyBlnd16, SurfMaskCopyTrans16

; GLOBAL Variables
GLOBAL  CurSurf, SrcSurf
GLOBAL  TPolyAdDeb, TPolyAdFin, TexXDeb, TexXFin, TexYDeb, TexYFin, PColDeb, PColFin

GLOBAL  vlfb,rlfb,ResH,ResV, MaxX, MaxY, MinX, MinY, OrgY, OrgX, SizeSurf,OffVMem
GLOBAL  BitsPixel, ScanLine,Mask,NegScanLine

; EXTERN GLOBAL VARS
EXTERN  QBlue16Mask, QGreen16Mask, QRed16Mask, WBGR16Mask
EXTERN  PntInitCPTDbrd
EXTERN  MaskB_RGB16, MaskG_RGB16, MaskR_RGB16, RGB16_PntNeg, Mask2B_RGB16, Mask2G_RGB16, Mask2R_RGB16
EXTERN  RGBDebMask_GGG, RGBDebMask_IGG, RGBDebMask_GIG, RGBDebMask_IIG, RGBDebMask_GGI, RGBDebMask_IGI, RGBDebMask_GII, RGBDebMask_III
EXTERN  RGBFinMask_GGG, RGBFinMask_IGG, RGBFinMask_GIG, RGBFinMask_IIG, RGBFinMask_GGI, RGBFinMask_IGI, RGBFinMask_GII, RGBFinMask_III

; GLOBAL Constants
MaxDblSidePolyPts     EQU 128
MaxDeltaDim           EQU 1<< (31-Prec)

BITS 32

SECTION .text  ALIGN=32

%include "Poly.asm"
%include "poly16.asm"
%include "fasthzline16.asm"
%include "hzline16.asm"
%include "pts16.asm"
%include "line16.asm"
%include "fill16.asm"

ALIGN 32
DgSetCurSurf:
    ARG S1, 4


            MOV         ECX,[EBP+S1]
            JECXZ       .NotSet
            CMP         DWORD [ECX+DuglSurf.ResV], MaxResV
            JG          .NotSet
            MOV         EAX,CurSurf
            MOVDQA      xmm0,[ECX]
            MOVDQA      xmm1,[ECX+32]
            MOVDQA      xmm2,[ECX+16]
            MOVDQA      xmm3,[ECX+48]

            MOVDQA      [EAX],xmm0
            MOVDQA      [EAX+32],xmm1
            MOVDQA      [EAX+16],xmm2
            MOVDQA      [EAX+48],xmm3
.NotSet:

    RETURN

ALIGN 32
DgSetSrcSurf:
    ARG SrcS, 4

            MOV         ECX,[EBP+SrcS]
            JECXZ       .NotSet
            MOV         EAX,SrcSurf
            MOVDQA      xmm0,[ECX]
            MOVDQA      xmm1,[ECX+32]
            MOVDQA      xmm2,[ECX+16]
            MOVDQA      xmm3,[ECX+48]

            MOVDQA      [EAX],xmm0
            MOVDQA      [EAX+32],xmm1
            MOVDQA      [EAX+16],xmm2
            MOVDQA      [EAX+48],xmm3
.NotSet:

    RETURN

ALIGN 32
DgGetCurSurf:
  ARG SGet, 4

            PUSH        EDI
            PUSH        ESI

            MOV         ESI,CurSurf
            MOV         EDI,[EBP+SGet]
            CopySurfSA

            POP         ESI
            POP         EDI

    RETURN


DgClear16:
    ARG clrcol16, 4

            PUSH        EDI

            MOVD        xmm0,[EBP+clrcol16]
            MOV         EDX,[SizeSurf]
            MOV         EDI,[rlfb]
            PSHUFLW     xmm0,xmm0,0
            XOR         ECX,ECX
            PUNPCKLQDQ  xmm0,xmm0
            SHR         EDX,1
            MOVD        EAX,xmm0

            @SolidHLineSSE16

            POP     EDI
    RETURN

DgPutPixel16:
    ARG PPX, 4, PPY, 4, PPCOL16, 4

            MOV         EDX,[NegScanLine]
            MOV         ECX,[EBP+PPX]
            IMUL        EDX,[EBP+PPY]
            MOV         EAX,[EBP+PPCOL16]
            ADD         EDX,[vlfb]
            MOV         [EDX+ECX*2],AX

    RETURN

DgCPutPixel16:
    ARG CPPX, 4, CPPY, 4, CPPCOL16, 4

            MOV         EDX,[EBP+CPPY]
            MOV         ECX,[EBP+CPPX]
            CMP         EDX,[MaxY]
            JG          SHORT .Clip
            CMP         ECX,[MaxX]
            JG          SHORT .Clip
            CMP         EDX,[MinY]
            JL          SHORT .Clip
            CMP         ECX,[MinX]
            JL          SHORT .Clip

            IMUL        EDX,[NegScanLine]
            MOV         EAX,[EBP+CPPCOL16]
            ADD         EDX,[vlfb]
            MOV         [EDX+ECX*2],AX
.Clip:

    RETURN

DgGetPixel16:
    ARG GPPX, 4, GPPY, 4

            MOV         EDX,[NegScanLine]
            MOV         ECX,[EBP+GPPX]
            IMUL        EDX,[EBP+GPPY]
            ADD         EDX,[vlfb]
            MOVZX       EAX,WORD [EDX+ECX*2]

    RETURN

DgCGetPixel16:
    ARG CGPPX, 4, CGPPY, 4

            MOV         EDX,[EBP+CGPPY]
            MOV         ECX,[EBP+CGPPX]
            MOV         EAX,0xFFFFFFFF
            CMP         EDX,[MaxY]
            JG          SHORT .Clip
            CMP         ECX,[MaxX]
            JG          SHORT .Clip
            CMP         EDX,[MinY]
            JL          SHORT .Clip
            CMP         ECX,[MinX]
            JL          SHORT .Clip

            IMUL        EDX,[NegScanLine]
            ADD         EDX,[vlfb]
            MOVZX       EAX,WORD [EDX+ECX*2]
.Clip:

    RETURN

ClearSurf16:
    ARG ClearSurf16Col, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOVDQA      xmm1,[MaxX] ; = MaxX | MaxY | MinX | MinY
            MOVD        xmm0,[EBP+ClearSurf16Col]
            PEXTRD      EDI,xmm1,3 ; MinY
            PSHUFLW     xmm0,xmm0, 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
            PEXTRD      ESI,xmm1,1 ; MaxY
            PUNPCKLQDQ  xmm0,xmm0
            PEXTRD      ECX,xmm1,0 ; MaxX
            PEXTRD      EBX,xmm1,2 ; MinX
            SUB         ESI,EDI ; = (MaxY - MinY)
            JMP         SHORT InBar16.CommonInBar16

InBar16:
    ARG InRect16MinX, 4, InRect16MinY, 4, InRect16MaxX, 4, InRect16MaxY, 4, InRect16Col, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOVD        xmm0,[EBP+InRect16Col]
            MOV         EDI,[EBP+InRect16MinY]
            PSHUFLW     xmm0,xmm0, 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
            MOV         ESI,[EBP+InRect16MaxY]
            PUNPCKLQDQ  xmm0,xmm0
            MOV         ECX,[EBP+InRect16MaxX]
            SUB         ESI,EDI ; = (MaxY - MinY)
            MOV         EBX,[EBP+InRect16MinX]
.CommonInBar16:
            JLE         .EndInBar ; MinY >= MaxY ? exit
            IMUL        EDI,[NegScanLine]
            LEA         EBP,[ESI+1]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            INC         ECX
            LEA         EDI,[EDI+EBX*2]
            MOV         ESI,ECX ; ESI = dest hline size
            MOVD        EAX,xmm0
            MOV         EBX,EDI ; EBX = start Hline dest
            XOR         ECX,ECX ; should be zero for @SolidHLineSSE16
.BcBar:
            MOV         EDI,EBX ; start hline
            MOV         EDX,ESI ; dest hline size

            @SolidHLineSSE16

            ADD         EBX,[NegScanLine] ; next hline
            DEC         EBP
            JNZ         .BcBar

.EndInBar:
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN

; == xxxResizeViewSurf16 =====================================

ResizeViewSurf16:
    ARG SrcResizeSurf16, 4, ResizeRevertHz, 4, ResizeRevertVt, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcResizeSurf16]
            MOV         EDI,SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurfDA  ; copy the source surface


            MOV         EAX,[EBP+ResizeRevertHz]
            MOV         EDX,[EBP+ResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; xmm6 = start Hline dest
            MOVD        mm2,ECX ; xmm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; xmm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastTextHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

            EMMS
            POP         EDI
            POP         EBX
            POP         ESI
    RETURN


MaskResizeViewSurf16:
    ARG SrcMaskResizeSurf16, 4, MaskResizeRevertHz, 4, MaskResizeRevertVt, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcMaskResizeSurf16]
            MOV         EDI,SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurfDA  ; copy the source surface


            MOV         EAX,[EBP+MaskResizeRevertHz]
            MOV         EDX,[EBP+MaskResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; xmm6 = start Hline dest
            MOVD        mm2,ECX ; xmm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; xmm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            PSHUFLW     xmm7,[SMask], 0 ; xmm7 = SMask | SMask | SMask | SMask
            MOVD        mm3,EAX ; xmm3  = pntY
            PUNPCKLQDQ  xmm7,xmm7

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastMaskTextHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

            EMMS
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN


TransResizeViewSurf16:
    ARG SrcTransResizeSurf16, 4, TransResizeRevertHz, 4, TransResizeRevertVt, 4, TransResizeSurf16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcTransResizeSurf16]
            MOV         EDI,SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurfDA  ; copy the source surface

            MOV         EAX,[EBP+TransResizeSurf16] ;
            AND         EAX,BYTE BlendMask
            JZ          .End ; zero transparency no need to draw any thing
            MOV         EDX,EAX ;
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm6,xmm6


            MOV         EAX,[EBP+TransResizeRevertHz]
            MOV         EDX,[EBP+TransResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; xmm6 = start Hline dest
            MOVD        mm2,ECX ; xmm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; xmm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastTransTextHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

.End:
            EMMS
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN

MaskTransResizeViewSurf16:
    ARG SrcMaskTransResizeSurf16, 4, MaskTransResizeRevertHz, 4, MaskTransResizeRevertVt, 4, MaskTransResizeSurf16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcMaskTransResizeSurf16]
            MOV         EDI,SrcSurf
            XOR         EBX,EBX ; store flags revert Hz and Vt
            CopySurfDA  ; copy the source surface

            MOV         EAX,[EBP+MaskTransResizeSurf16] ;
            AND         EAX,BYTE BlendMask
            JZ          .End ; zero transparency no need to draw any thing
            MOV         EDX,EAX ;
            PSHUFLW     xmm0,[SMask],0
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm6,xmm6
            PUNPCKLQDQ  xmm0,xmm0
            MOVDQA      [QMulSrcBlend],xmm7
            MOVDQA      [DQ16Mask],xmm0

            MOV         EAX,[EBP+MaskTransResizeRevertHz]
            MOV         EDX,[EBP+MaskTransResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; xmm6 = start Hline dest
            MOVD        mm2,ECX ; xmm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; xmm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastMaskTransTextHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

.End:
            EMMS
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN



BlndResizeViewSurf16:
    ARG SrcBlndResizeSurf16, 4, BlndResizeRevertHz, 4, BlndResizeRevertVt, 4, ColBlndResizeSurf16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcBlndResizeSurf16]
            MOV         EDI,SrcSurf
            CopySurfDA  ; copy the source surface


; prepare col blending
            MOV         EAX,[EBP+ColBlndResizeSurf16] ;
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
            MOV         [WBGR16Blend],BX
            MOV         [WBGR16Blend+2],CX
            MOV         [WBGR16Blend+4],DX

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
            MOVDQA      xmm6,[QRed16Mask]

            MOV         EAX,[EBP+BlndResizeRevertHz]
            XOR         EBX,EBX ; store flags revert Hz and Vt
            MOV         EDX,[EBP+BlndResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; mm6 = start Hline dest
            MOVD        mm2,ECX ; mm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; mm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY

.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastTextBlndHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

.End:
            EMMS
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN

MaskBlndResizeViewSurf16:
  ARG SrcMaskBlndResizeSurf16, 4, MaskBlndResizeRevertHz, 4, MaskBlndResizeRevertVt, 4, ColMaskBlndResizeSurf16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+SrcMaskBlndResizeSurf16]
            MOV         EDI,SrcSurf
            CopySurfDA  ; copy the source surface


; prepare col blending
            MOV         EAX,[EBP+ColMaskBlndResizeSurf16] ;
            PSHUFLW     xmm0,[SMask],0

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
            MOV         [WBGR16Blend],BX
            MOV         [WBGR16Blend+2],CX
            MOV         [WBGR16Blend+4],DX
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
            PUNPCKLQDQ  xmm5,xmm5
            PUNPCKLQDQ  xmm7,xmm7
            MOVDQA      [DQ16Mask],xmm0

            MOV         EAX,[EBP+MaskBlndResizeRevertHz]
            XOR         EBX,EBX ; store flags revert Hz and Vt
            MOV         EDX,[EBP+MaskBlndResizeRevertVt]
            OR          EAX,EAX
            ; compute horizontal pnt in EBP
            MOV         EBP,[MaxY]
            SETNZ       BL ; BL = RevertHz ?
            OR          EDX,EDX
            MOV         EAX,[SMaxX]
            SETNZ       BH ; BH = RevertVt ?
            MOV         EDI,[MinY]
            MOV         ESI,[SMinX]
            PUSH        EBX ; save FLAGS Revert
            MOV         ECX,[MaxX]
            SUB         EBP,EDI ; = (MaxY - MinY)
            MOV         EBX,[MinX]
            INC         EBP ; = Delta_Y = (MaxY - MinY) + 1
            SUB         EAX,ESI
            IMUL        EDI,[NegScanLine]
            SUB         ECX,EBX
            ADD         EDI,[vlfb]
            MOVD        mm5,EBP ; count of hline
            MOVD        mm1,ESI ; SMinX
            INC         EAX
            LEA         EDI,[EDI+EBX*2]
            INC         ECX
            MOVD        mm6,EDI ; mm6 = start Hline dest
            MOVD        mm2,ECX ; mm2 = dest hline size
            MOV         EBX,[SMaxY]
            SHL         EAX,Prec
            MOV         EDI,EBP ; EDI = DeltaY
            XOR         EDX,EDX
            SUB         EBX,[SMinY]
            DIV         ECX
            INC         EBX ; Source DeltaYT
            SHL         EBX,Prec
            MOV         EBP,EAX
            XOR         EDX,EDX
            MOV         EAX,EBX
            DIV         EDI
            POP         EBX
            XOR         EDX,EDX ; EDX = acc PntX
            MOVD        mm7,[SMinY]
            PXOR        mm4,mm4 ; mm4 = acc pnt
            MOVD        ECX,mm5
            CMP         BL,0
            JZ          SHORT .NoRevertHz
            MOVD        mm1,[SMaxX] ; SMaxX
            MOV         EDX,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
            NEG         EBP ; revert Horizontal Pnt X
.NoRevertHz:
            CMP         BH,0
            JZ          SHORT .NoRevertVt
            NEG         EAX ; negate PntY
            MOVD        mm7,[SMaxY] ; SMaxX
            MOVD        mm4,[PntInitCPTDbrd+4] ; ((1<<Prec)-1)
.NoRevertVt:
            MOVD        mm3,EAX ; xmm3  = pntY
.BcResize:
            MOVQ        mm0,mm4
            MOVD        EBX,mm1 ; + [SMinX] | [SMaxX] (if RevertHz)
            PSRAD       mm0,Prec
            MOVD        mm5,ECX ; save hline counter
            PADDD       mm0,mm7 ; + [SMinY] | [SMaxY] (if RevertVt)
            MOVD        EDI,mm6 ; start hline
            MOVD        ESI,mm0
            MOVD        ECX,mm2 ; dest hline size
            IMUL        ESI,[SNegScanLine] ; - 2
            PUSH        EDX ; save acc PntX
            LEA         ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
            ADD         ESI,[Svlfb] ; - 5

            @InFastMaskTextBlndHLineDYZ16

            MOVD        ECX,mm5 ; restore hline counter
            PADDD       mm4,mm3 ; next source hline
            PADDD       mm6,[NegScanLine] ; next hline
            DEC         ECX
            POP         EDX  ; restore acc PntX
            JNZ         .BcResize

.End:
            EMMS
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN

; =======================================
; ====================== POLY16 ==========


POLY_FLAG_DBL_SIDED16   EQU 0x80000000
DEL_POLY_FLAG_DBL_SIDED16 EQU 0x7FFFFFFF

;****************************************************************************

RePoly16:
    ARG RePtrListPt16, 4, ReSSurf16, 4, ReTypePoly16, 4, ReColPoly16, 4

            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            CMP         [LastPolyStatus], BYTE 'N' ; last Poly16 failed to render ?
            JE          Poly16.PasDrawPoly

            MOV         EAX,[EBP+ReTypePoly16]
            MOV         EBX,[EBP+ReColPoly16]
            AND         EAX,DEL_POLY_FLAG_DBL_SIDED16
            MOV         ECX,[EBP+ReSSurf16]
            MOV         [clr],EBX
            CMP         [LastPolyStatus], BYTE 'I' ; last render IN ?
            MOV         [SSSurf],ECX
            JNE         .CheckClip
            JMP         [InFillPolyProc16+EAX*4]
.CheckClip:
            CMP         [LastPolyStatus], BYTE 'C' ; last render CLIPPED ?
            JNE         Poly16.PasDrawPoly
            JMP         [ClFillPolyProc16+EAX*4]



Poly16:
    ARG PtrListPt16, 4, SSurf16, 4, TypePoly16, 4, ColPoly16, 4

            PUSH        ESI
            PUSH        EBX
            MOV         ESI,[EBP+PtrListPt16]
            PUSH        EDI

            LODSD   ; MOV EAX,[ESI];  ADD ESI,4
            MOV         [LastPolyStatus], BYTE 'N' ; default no render
            MOV         [NbPPoly],EAX
            MOV         EDX,[ESI]
            MOV         ECX,[ESI+8]
            MOV         EBX,[ESI+4]
            MOVQ        xmm0,[EDX] ; = XP1, YP1
            MOVQ        xmm1,[EBX] ; = XP2, YP2
            MOVQ        xmm2,[ECX] ; = XP3, YP3
            MOVDQA      xmm3,xmm0 ; = XP1, YP1
            MOVDQA      xmm4,xmm1 ; = XP2, YP2
            MOVDQA      xmm5,xmm2 ; = XP3, YP3
            MOVQ        [XP1],xmm0 ; XP1, YP1

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
            PSUBD       xmm1,xmm0 ; = (XP2-XP1) | (YP2 - YP1)
            PSUBD       xmm2,xmm4 ; = (XP3-XP2) | (YP3 - YP2)
            PEXTRD      EDI,xmm1,1 ; = (YP2-YP1)
            PEXTRD      EBX,xmm2,1 ; = (YP3-YP2)
            MOVD        ECX,xmm1 ; = (XP2-XP1)
            MOVD        EDX,xmm2 ; = (XP3-XP2)
            IMUL        ECX,EBX
            IMUL        EDI,EDX
            CMP         ECX,EDI

            JL          .TstSiDblSide ; si <= 0 alors pas ok
            JZ          .SpecialCase
;****************
.DrawPoly:
    ; Save parameters and free EBP
            MOV         EAX,[EBP+TypePoly16]
            MOV         EBX,[EBP+ColPoly16]
            AND         EAX,DEL_POLY_FLAG_DBL_SIDED16
            MOV         ECX,[EBP+SSurf16]
            MOV         [PType],EAX
            MOV         [clr],EBX
            MOV         EDI,[NbPPoly]
            MOV         [PPtrListPt],ESI
            MOV         [SSSurf],ECX
;-new born determination--------------
            MOV         EBP,EDI
            MOVQ        xmm1,xmm3 ; init min = XP1 | YP1
            MOVQ        xmm2,xmm3 ; init max = XP1 | YP1
            PMINSD      xmm1,xmm4
            PMAXSD      xmm2,xmm4
            PMINSD      xmm1,xmm5
            PMAXSD      xmm2,xmm5
            DEC         EDI ; = [NbPPoly] - 1
            SUB         EBP, BYTE 3 ; EBP = [NbPPoly] - 3
            JZ          .NoBcMnMxXY
.PBoucMnMxXY:
            MOV         EAX,[ESI+EBP*4+8] ; = XN, YN
            MOVQ        xmm0,[EAX] ; = XN, YN
            DEC         EBP
            PMINSD      xmm1,xmm0
            PMAXSD      xmm2,xmm0
            JNZ         .PBoucMnMxXY
.NoBcMnMxXY:
            MOVD        EAX,xmm2 ; maxx
            MOVD        ECX,xmm1 ; minx
            PEXTRD      EBX,xmm2,1 ; maxy
            PEXTRD      EDX,xmm1,1 ; miny
;-----------------------------------------

; poly clipper ? dans l'ecran ? hors de l'ecran ?
            ;JMP      .PolyClip
            CMP         EAX,[MaxX]
            JG          .PolyClip
            CMP         ECX,[MinX]
            JL          .PolyClip
            CMP         EBX,[MaxY]
            JG          .PolyClip
            CMP         EDX,[MinY]
            JL          .PolyClip

; trace Poly non Clipper  **************************************************

            MOV         ECX,[OrgY]  ; calcule DebYPoly, FinYPoly
            MOV         EAX,[ESI+EDI*4]
            ADD         EDX,ECX
            ADD         EBX,ECX
            MOV         [DebYPoly],EDX
            MOVQ        xmm3,[EAX] ; XP2, YP2
            MOV         [FinYPoly],EBX
            MOVQ        xmm0,[XP1] ; = XP1 | YP1
            MOVQ        [XP2],xmm3 ; save XP2, YP2
; calcule les bornes horizontal du poly
            MOV         EDX,EDI ; = NbPPoly - 1
            @InCalculerContour16
            MOV         EAX,[PType]
            MOV         [LastPolyStatus], BYTE 'I'; In render
            JMP         [InFillPolyProc16+EAX*4]
            ;JMP        .PasDrawPoly
.PolyClip:
; outside view ? now draw !
            CMP         EAX,[MinX]
            JL          .PasDrawPoly
            CMP         EBX,[MinY]
            JL          .PasDrawPoly
            CMP         ECX,[MaxX]
            JG          .PasDrawPoly
            CMP         EDX,[MaxY]
            JG          .PasDrawPoly

; Drop too big poly
    ; drop too BIG poly
            SUB         ECX,EAX  ; deltaY
            SUB         EDX,EBX  ; deltaX
            CMP         ECX,MaxDeltaDim
            JGE         .PasDrawPoly
            CMP         EDX,MaxDeltaDim
            LEA         ECX,[ECX+EAX] ; restor MaxY
            JGE         .PasDrawPoly
            ADD         EDX,EBX ; restor MaxX

; trace Poly Clipper  ******************************************************
            MOV         EAX,[MaxY] ; determine DebYPoly, FinYPoly
            MOV         ECX,[MinY]
            CMP         EBX,EAX
            MOV         EBP,[OrgY]   ; Ajuste [DebYPoly],[FinYPoly]
            CMOVG       EBX,EAX
            CMP         EDX,ECX
            MOV         EAX,[ESI+EDI*4]
            CMOVL       EDX,ECX
            ADD         EBX,EBP
            ADD         EDX,EBP
            MOVQ        xmm4,[EAX] ; read XP2 | YP2
            MOV         [DebYPoly],EDX
            MOV         [FinYPoly],EBX
            MOVQ        [XP2],xmm4 ; write XP2 | YP2
            MOV         EDX,EDI ; EDX compteur de point = NbPPoly-1
            @ClipCalculerContour ; use same as 8bpp as it compute xdeb and xfin for eax hzline

            CMP         DWORD [DebYPoly],BYTE (-1)
            JE          SHORT .PasDrawPoly
            MOV         EAX,[PType]
            MOV         [LastPolyStatus], BYTE 'C' ; Clip render
            JMP         [ClFillPolyProc16+EAX*4]
.PasDrawPoly:
            POP         EDI
            POP         EBX
            POP         ESI

    RETURN

.TstSiDblSide:
            TEST        BYTE [EBP+TypePoly16+3],POLY_FLAG_DBL_SIDED16 >> 24
            JZ          SHORT .PasDrawPoly
            ; swap all points except P1 !
            MOV         ECX,[ESI]
            MOV         EDX,ReversedPtrListPt
            DEC         EAX
            MOV         [EDX],ECX
            LEA         EDI,[ESI+EAX*4]
            CMP         EAX,BYTE 2
            LEA         EBX,[EDX+4] ; P1 already copied
            MOV         ESI,EDX
            JA          .BcSwapPtsOver3
.BcSwapPts:
            MOV         ECX,[EDI]
            MOV         [EBX],ECX
            SUB         EDI,BYTE 4
            DEC         EAX
            LEA         EBX,[EBX+4]
            JNZ         SHORT .BcSwapPts
            JMP         .DrawPoly
.BcSwapPtsOver3:
            MOV         ECX,[EDI]
            MOV         [EBX],ECX
            SUB         EDI,BYTE 4
            DEC         EAX
            LEA         EBX,[EBX+4]
            JNZ         SHORT .BcSwapPtsOver3
            MOV         ECX,[EDX+4] ; new XP2 | YP2 Ptr
            MOV         EBX,[EDX+8] ; new XP3 | YP3 Ptr
            MOVQ        xmm4,[ECX] ; = XP2, YP2
            MOVQ        xmm5,[EBX] ; = XP3, YP3
            JMP         .DrawPoly

.SpecialCase:
            CMP         EAX,BYTE 3
            MOV         ECX,EAX
            JLE         .PasDrawPoly
; first loop fin any x or y not equal to P1
            MOV         EBX,[YP1]
            DEC         ECX
            MOV         EAX,[XP1]
            ;MOV        ESI,[EBP+PtrListPt16]
            ADD         ESI,BYTE 4 ; jump over number of points + p1
.lpAnydiff:
            MOV         EDI,[ESI]  ;
            CMP         EAX,[EDI] ; XP1 != XP[N]
            JNE         .finddiffP3
            CMP         EBX,[EDI+4] ; YP1 != YP[N]
            JNE         .finddiffP3
            DEC         ECX
            LEA         ESI,[ESI+4]
            JNZ         .lpAnydiff
            JMP         .PasDrawPoly ; failed

.finddiffP3:
            MOV         EAX,[EDI]
            MOV         EBX,[EDI+4]
            MOV         [XP2],EAX
            MOV         [YP2],EBX
            DEC         ECX
            LEA         ESI,[ESI+4]
            JZ          .PasDrawPoly ; no more points ? :(
            SUB         EAX,[XP1] ; = XP2-XP1
            SUB         EBX,[YP1] ; = YP2-YP1

.lpPdiff:
            MOV         EDI,[ESI]
            MOV         EDX,[EDI] ; XP3
            MOV         EDI,[EDI+4] ; YP3
            SUB         EDX,[XP2] ; XP3-XP2
            SUB         EDI,[YP2] ; YP3-YP2
            IMUL        EDX,EBX ; = (YP2-YP1)*(XP3-XP2)
            IMUL        EDI,EAX ; = (XP2-XP1)*(YP3-YP2)
            SUB         EDI,EDX
            JNZ         .P3ok
            DEC         ECX
            LEA         ESI,[ESI+4]
            JNZ         .lpPdiff
            JMP         .PasDrawPoly ; failed
.P3ok:
            MOV         ESI,[EBP+PtrListPt16]
            LODSD
            JL          .TstSiDblSide
            JMP         .DrawPoly


SECTION .bss   ALIGN=32
; Main DGSurf
; All graphic functions render on DGSurf pointed here
CurSurf:
ScanLine          RESD  1
rlfb              RESD  1
OrgX              RESD  1
OrgY              RESD  1
MaxX              RESD  1
MaxY              RESD  1
MinX              RESD  1
MinY              RESD  1;-----------------------
Mask              RESD  1
ResH              RESD  1
ResV              RESD  1
vlfb              RESD  1
NegScanLine       RESD  1
OffVMem           RESD  1
BitsPixel         RESD  1
SizeSurf          RESD  1;-----------------------
; source DgSurf mainly used to point to texture, sprites ..
SrcSurf:
SScanLine         RESD  1
Srlfb             RESD  1
SOrgX             RESD  1
SOrgY             RESD  1
SMaxX             RESD  1
SMaxY             RESD  1
SMinX             RESD  1
SMinY             RESD  1;-----------------------
SMask             RESD  1
SResH             RESD  1
SResV             RESD  1
Svlfb             RESD  1
SNegScanLine      RESD  1
SOffVMem          RESD  1
SBitsPixel        RESD  1
SSizeSurf         RESD  1;-----------------------
XP1               RESD  1
YP1               RESD  1
XP2               RESD  1
YP2               RESD  1
XP3               RESD  1
YP3               RESD  1
Plus              RESD  1
LastPolyStatus    RESD  1;-----------------------
XT1               RESD  1
YT1               RESD  1
XT2               RESD  1
YT2               RESD  1
Col1              RESD  1
Col2              RESD  1
revCol            RESD  1
CurViewVSurf      RESD  1;-----------------------
PutSurfMaxX       RESD  1
PutSurfMaxY       RESD  1
PutSurfMinX       RESD  1
PutSurfMinY       RESD  1
NbPPoly           RESD  1
DebYPoly          RESD  1
FinYPoly          RESD  1
PType             RESD  1;-----------------------
PType2            RESD  1
PPtrListPt        RESD  1
PntPlusX          RESD  1
PntPlusY          RESD  1
PlusX             RESD  1
PlusY             RESD  1
SSSurf            RESD  1
Plus2             RESD  1;-----------------------
; poly16 array
TPolyAdDeb        RESD  MaxResV
TPolyAdFin        RESD  MaxResV
TexXDeb           RESD  MaxResV
TexXFin           RESD  MaxResV
TexYDeb           RESD  MaxResV
TexYFin           RESD  MaxResV
PColDeb           RESD  MaxResV
PColFin           RESD  MaxResV

QMulSrcBlend      RESD  4
QMulDstBlend      RESD  4;--------------
WBGR16Blend       RESD  4
clr               RESD  1
Temp              RESD  1
PlusCol           RESD  1
PtrTbDegCol       RESD  1 ;-----------
QBlue16Blend      RESD  4
QGreen16Blend     RESD  4
QRed16Blend       RESD  4
DQ16Mask          RESD  4 ;------------------------

ReversedPtrListPt   RESD  MaxDblSidePolyPts

SECTION .data   ALIGN=32


;* 16bpp poly proc****
InFillPolyProc16:
    DD  InFillSOLID16, InFillTEXT16, InFillMASK_TEXT16, dummyFill16, dummyFill16 ; InFillFLAT_DEG,InFillDEG
    DD  dummyFill16, dummyFill16 ;InFillFLAT_DEG_TEXT,InFillMASK_FLAT_DEG_TEXT
    DD  dummyFill16, dummyFill16, dummyFill16;InFillDEG_TEXT,InFillMASK_DEG_TEXT,InFillEFF_FDEG
    DD  InFillTEXT_TRANS16,InFillMASK_TEXT_TRANS16
    DD  InFillRGB16,InFillSOLID_BLND16,InFillTEXT_BLND16,InFillMASK_TEXT_BLND16

ClFillPolyProc16:
    DD  ClipFillSOLID16,ClipFillTEXT16,ClipFillMASK_TEXT16, 0, 0 ;ClipFillFLAT_DEG,ClipFillDEG
    DD  dummyFill16, dummyFill16 ;ClipFillFLAT_DEG_TEXT,ClipFillMASK_FLAT_DEG_TEXT
    DD  dummyFill16, dummyFill16, dummyFill16 ;ClipFillDEG_TEXT,ClipFillMASK_DEG_TEXT,ClipFillEFF_FDEG
    DD  ClipFillTEXT_TRANS16, ClipFillMASK_TEXT_TRANS16
    DD  ClipFillRGB16,ClipFillSOLID_BLND16,ClipFillTEXT_BLND16,ClipFillMASK_TEXT_BLND16

