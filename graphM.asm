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
GLOBAL  GetMaxResVSetSurf, BlndCol16
GLOBAL  DgSurfCGetPixel16, DgSurfCPutPixel16
GLOBAL  SurfCopy, SurfMaskCopy16, SurfCopyBlnd16, SurfCopyTrans16

; GLOBAL Vars
GLOBAL  QBlue16Mask, QGreen16Mask, QRed16Mask, WBGR16Mask

GLOBAL  PntInitCPTDbrd
GLOBAL  MaskB_RGB16, MaskG_RGB16, MaskR_RGB16, RGB16_PntNeg, Mask2B_RGB16, Mask2G_RGB16, Mask2R_RGB16
GLOBAL  RGBDebMask_GGG, RGBDebMask_IGG, RGBDebMask_GIG, RGBDebMask_IIG, RGBDebMask_GGI, RGBDebMask_IGI, RGBDebMask_GII, RGBDebMask_III
GLOBAL  RGBFinMask_GGG, RGBFinMask_IGG, RGBFinMask_GIG, RGBFinMask_IIG, RGBFinMask_GGI, RGBFinMask_IGI, RGBFinMask_GII, RGBFinMask_III

GLOBAL  RendFrontSurf, RendSurf
BITS 32

SECTION .text  ALIGN=32

%include "fasthzline16.asm"
%include "hzline16.asm"

BlndCol16:
  ARG SrcCol16, 4, DstCol16, 4, BlndVal16, 4

            MOV         ECX,[EBP+BlndVal16] ;
            MOV         EAX,[EBP+SrcCol16] ;
            AND         ECX,BYTE BlendMask
            MOV         EDX,[EBP+DstCol16] ;
            JZ          .FinBlndCol16
            CMP         CL,31
            JZ          .ChooseDst16
            MOVD        xmm3,ECX ; dst Mul
            MOVD        xmm0,EAX ; srcCol16 | 0 | 0 | 0
            MOVD        xmm1,EDX ; dstCol16 | 0 | 0 | 0
            XOR         CL,BlendMask ; = 31-blendVal
            PSHUFD      xmm3,xmm3, (0<<6) | (0<<4) | (0<<2) | (0) ; dst Mul | dst Mul | dst Mul | dst Mul
            PSHUFLW     xmm0,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; srcCol16 | srcCol16 | srcCol16 | srcCol16
            PSHUFLW     xmm1,xmm1,(0<<6) | (0<<4) | (0<<2) | (0) ; dstCol16 | dstCol16 | dstCol16 | dstCol16
            MOVD        xmm2,ECX ; src Mul
            PAND        xmm0, [WBGR16Mask] ; srcColB16 | srcColG16 | srcColR16 | srcColR16
            PSHUFD      xmm2,xmm2, (0<<6) | (0<<4) | (0<<2) | (0) ; src Mul | src Mul | src Mul | src Mul
            PAND        xmm1, [WBGR16Mask] ; dstColB16 | dstColG16 | dstColR16 | dstColR16
            PMOVZXWD    xmm0, xmm0 ; extend 16 bits Word src color de 32 bit DWord
            PMOVZXWD    xmm1, xmm1 ; extend 16 bits Word dst color de 32 bit DWord
            PMULLD      xmm0, xmm2 ; *= srcMul
            PMULLD      xmm1, xmm3 ; *= dstMul
            PADDD       xmm0, xmm1 ; xmm0 = srcCol (R|G|B|B) * srcMul + dstCol (R|G|B|B) * dstMul
            PSRLD       xmm0, 5
            PSHUFD      xmm4,xmm0, (1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm5,xmm0, (2<<6) | (2<<4) | (2<<2) | (2)
            ;PAND        xmm0,[QBlue16Mask]
            PAND        xmm4,[QGreen16Mask]
            PAND        xmm5,[QRed16Mask]
            POR         xmm0,xmm4
            POR         xmm0,xmm5
            MOVD        EAX,xmm0

            JMP         .FinBlndCol16
.ChooseDst16:
            MOV         EAX,EDX
.FinBlndCol16:

      RETURN

GetMaxResVSetSurf:
            MOV         EAX,MaxResV
            RET

ALIGN 32
SurfCopy:
  ARG PDstSrf, 4, PSrcSrf, 4

            PUSH        EDI
            PUSH        ESI
            PUSH        EBX

            MOV         ESI,[EBP+PSrcSrf]
            MOV         EDI,[EBP+PDstSrf]
            MOV         EBX,[ESI+DuglSurf.SizeSurf]

            MOV         EDI,[EDI+DuglSurf.rlfb]
            MOV         ESI,[ESI+DuglSurf.rlfb]
            XOR         ECX,ECX
            TEST        EDI,0x7
            JZ          .CpyMMX
.CopyBAv:
            TEST        EDI,0x1
            JZ          .PasCopyBAv
            OR          EBX,EBX
            JZ          .FinSurfCopy
            DEC         EBX
            MOVSB
.PasCopyBAv:
.CopyWAv:
            TEST        EDI,0x2
            JZ          .PasCopyWAv
            CMP         EBX,BYTE 2
            JL          .CopyBAp
            SUB         EBX,BYTE 2
            MOVSW
.PasCopyWAv:
.CopyDAv:
            TEST        EDI,0x4
            JZ          .PasCopyDAv
            CMP         EBX,BYTE 4
            JL          .CopyWAp
            SUB         EBX,BYTE 4
            MOVSD
.PasCopyDAv:
            TEST        EDI,0x8
            JZ          .PasCopyQAv
            CMP         EBX,BYTE 8
            JL          .CopyWAp
            MOVQ        xmm0,[ESI]
            SUB         EBX,8
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasCopyQAv:
.CpyMMX:
            SHLD        ECX,EBX,26 ; ECX = EBX >> 6 ; ECX should be zero
            JZ          SHORT .PasCpyMMXBloc
            AND         EBX,BYTE 0x3F
.BcCpyMMXBloc:
            MOVDQU      xmm0,[ESI]
            MOVDQU      xmm1,[ESI+32]
            MOVDQU      xmm2,[ESI+16]
            MOVDQU      xmm3,[ESI+48]
            MOVDQA      [EDI],xmm0
            MOVDQA      [EDI+32],xmm1
            MOVDQA      [EDI+16],xmm2
            MOVDQA      [EDI+48],xmm3
            DEC         ECX
            LEA         ESI,[ESI+64]
            LEA         EDI,[EDI+64]
            JNZ         SHORT .BcCpyMMXBloc
.PasCpyMMXBloc:
            SHLD        ECX,EBX,29 ; ECX = EBX >> 3 ; ECX should be zero
            JZ          SHORT .PasCpyMMX
            AND         EBX,BYTE 7
.BcCpyMMX:
            MOVQ        xmm0,[ESI]
            DEC         ECX
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
            JNZ         SHORT .BcCpyMMX

.PasCpyMMX:
.CopyDAp:
            CMP         EBX,BYTE 4
            JL          .CopyWAp
            SUB         EBX,BYTE 4
            MOVSD
.PasCopyDAp:
.CopyWAp:
            CMP         EBX,BYTE 2
            JL          .CopyBAp
            SUB         EBX,BYTE 2
            MOVSW
.PasCopyWAp:
.CopyBAp:
            OR          EBX,EBX
            JZ          .FinSurfCopy
            MOVSB
.PasCopyBAp:
.FinSurfCopy:
            POP         EBX
            POP         ESI
            POP         EDI

    RETURN

ALIGN 32
SurfMaskCopy16:
    ARG PDstSrfMaskB, 4, PSrcSrfMaskB, 4
            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         ESI,[EBP+PSrcSrfMaskB]
            MOV         EDI,[EBP+PDstSrfMaskB]

            MOV         EBX,[ESI+DuglSurf.SizeSurf]
            PSHUFLW     xmm3,[ESI+DuglSurf.Mask],0
            MOV         EDI,[EDI+DuglSurf.rlfb]
            PUNPCKLQDQ  xmm3,xmm3
            SHR         EBX,1
            MOV         ESI,[ESI+DuglSurf.rlfb]
            MOVD        EBP,xmm3
            XOR         ECX,ECX

.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            CMP         AX,BP
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

            PCMPEQW     xmm2,xmm3 ; [DQ16Mask]
            PCMPEQW     xmm1,xmm3 ; [DQ16Mask]
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

            PCMPEQW     xmm1,xmm3 ; [DQ16Mask]
            PCMPEQW     xmm2,xmm3 ; [DQ16Mask]
            PAND        xmm4,xmm1
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

            PCMPEQW     xmm2,xmm3 ; [DQ16Mask]
            PCMPEQW     xmm1,xmm3 ; [DQ16Mask]
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
            CMP         AX,BP
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
            POP         EBX
            POP         EDI
            POP         ESI

    RETURN


ALIGN 32
SurfCopyBlnd16:
  ARG PDstSrfB, 4, PSrcSrfB, 4, SCBCol, 4
            PUSH        EDI
            PUSH        ESI
            PUSH        EBX

; prepare col blending
            MOV         EAX,[EBP+SCBCol] ;
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

            MOV         ESI,[EBP+PSrcSrfB]
            MOV         EDI,[EBP+PDstSrfB]
            MOV         EBX,[ESI+DuglSurf.SizeSurf]

            MOV         EDI,[EDI+DuglSurf.rlfb]
            SHR         EBX,1
            MOV         ESI,[ESI+DuglSurf.rlfb]
            XOR         ECX,ECX

.BcStBAv:
            TEST        EDI,6     ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            DEC         EBX
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            MOVD        EAX,xmm0
            LEA         ESI,[ESI+2]
            STOSW
            JZ          .FinSHLine
            JMP         SHORT .BcStBAv
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
            MOV         AX,[ESI]
            DEC         BL
            MOVD        xmm0,EAX
            MOVD        xmm1,EAX
            MOVD        xmm2,EAX
            @SolidBlndQ
            MOVD        EAX,xmm0
            LEA         ESI,[ESI+2]
            STOSW
            JNZ         .BcStBAp
.PasStBAp:
.FinSHLine:
            POP         EBX
            POP         ESI
            POP         EDI
    RETURN


ALIGN 32
SurfCopyTrans16:
    ARG PDstSrfT, 4, PSrcSrfT, 4, SCTrans, 4
            PUSH        EDI
            PUSH        ESI
            PUSH        EBX

; prepare col blending
            MOV         EAX,[EBP+SCTrans] ;
            AND         EAX,BYTE BlendMask
            JZ          .FinSHLine
            MOV         EDX,EAX ;
            INC         EAX

            XOR         DL,BlendMask ; 31-blendsrc
            MOVD        xmm7,EAX
            MOVD        xmm6,EDX
            PSHUFLW     xmm7,xmm7,0
            PSHUFLW     xmm6,xmm6,0
            PUNPCKLQDQ  xmm7,xmm7
            PUNPCKLQDQ  xmm6,xmm6

            MOV         ESI,[EBP+PSrcSrfT]
            MOV         EDI,[EBP+PDstSrfT]
            MOV         EBX,[ESI+DuglSurf.SizeSurf]

            MOV         EDI,[EDI+DuglSurf.rlfb]
            SHR         EBX,1
            MOV         ESI,[ESI+DuglSurf.rlfb]
            XOR         ECX,ECX

.BcStBAv:
            TEST        EDI,6   ; dword aligned ?
            JZ          .FPasStBAv
            MOV         AX,[ESI]
            MOVD        xmm0,EAX
            DEC         EBX
            MOV         AX,[EDI]
            MOVQ        xmm1,xmm0
            MOVD        xmm3,EAX
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
            MOVQ        [EDI],xmm0
            LEA         ESI,[ESI+8]
            LEA         EDI,[EDI+8]
.PasStQAp:
            AND         BL,BYTE 3
            JZ          .FinSHLine
.BcStBAp:
            MOV         AX,[ESI]
            MOVD        xmm0,EAX
            DEC         BL
            MOV         AX,[EDI]
            MOVQ        xmm1,xmm0
            MOVD        xmm3,EAX
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

            POP         EBX
            POP         ESI
            POP         EDI
    RETURN


DgSurfCGetPixel16:
    ARG PSURFCGP, 4, SCGPPX, 4, SCGPPY, 4

            MOV         EDX,[EBP+SCGPPY]
            MOV         ECX,[EBP+SCGPPX]
            MOV         EAX,0xFFFFFFFF
            MOV         EBP,[EBP+PSURFCGP]
            CMP         EDX,[EBP+DuglSurf.MaxY]
            JG          SHORT .Clip
            CMP         ECX,[EBP+DuglSurf.MaxX]
            JG          SHORT .Clip
            CMP         EDX,[EBP+DuglSurf.MinY]
            JL          SHORT .Clip
            CMP         ECX,[EBP+DuglSurf.MinX]
            JL          SHORT .Clip

            IMUL        EDX,[EBP+DuglSurf.NegScanLine]
            ADD         EDX,[EBP+DuglSurf.vlfb]
            MOVZX       EAX,WORD [EDX+ECX*2]
.Clip:

    RETURN

DgSurfCPutPixel16:
    ARG PSURFCPP, 4, SCPPPX, 4, SCPPPY, 4, SCPPCOL, 4

            MOV         EAX,[EBP+PSURFCGP]
            MOV         EDX,[EBP+SCPPPY]
            MOV         ECX,[EBP+SCPPPX]
            CMP         EDX,[EAX+DuglSurf.MaxY]
            JG          SHORT .Clip
            CMP         ECX,[EAX+DuglSurf.MaxX]
            JG          SHORT .Clip
            CMP         EDX,[EAX+DuglSurf.MinY]
            JL          SHORT .Clip
            CMP         ECX,[EAX+DuglSurf.MinX]
            JL          SHORT .Clip

            IMUL        EDX,[EAX+DuglSurf.NegScanLine]
            MOV         ECX,[EBP+SCPPCOL]
            ADD         EDX,[EAX+DuglSurf.vlfb]
            MOV         [EDX+ECX*2],CX
.Clip:

    RETURN


SECTION .data   ALIGN=32

; BLENDING 16BPP ----------
QBlue16Mask     DW  CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
Q2Blue16Mask    DW  CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
QGreen16Mask    DW  CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
Q2Green16Mask   DW  CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
QRed16Mask      DW  CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16
Q2Red16Mask     DW  CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16
WBGR16Mask      DW  CMaskB_RGB16,CMaskG_RGB16,CMaskR_RGB16,CMaskR_RGB16
W2BGR16Mask     DW  CMaskB_RGB16,CMaskG_RGB16,CMaskR_RGB16,CMaskR_RGB16

PntInitCPTDbrd  DD  0,((1<<Prec)-1)
MaskB_RGB16     DD  0x1f   ; blue bits 0->4
MaskG_RGB16     DD  0x3f<<5  ; green bits 5->10
MaskR_RGB16     DD  0x1f<<11 ; red bits 11->15
RGB16_PntNeg    DD  ((1<<Prec)-1) ;----------
Mask2B_RGB16    DD  0x1f,0x1f ; blue bits 0->4
Mask2G_RGB16    DD  0x3f<<5,0x3f<<5  ; green bits 5->10 ;----------
Mask2R_RGB16    DD  0x1f<<11,0x1f<<11 ; red bits 11->15
RGBDebMask_GGG  DD  0,0,0,0
RGBDebMask_IGG  DD  ((1<<Prec)-1),0,0,0
RGBDebMask_GIG  DD  0,((1<<(Prec+5))-1),0,0
RGBDebMask_IIG  DD  ((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBDebMask_GGI  DD  0,0,((1<<(Prec+11))-1),0
RGBDebMask_IGI  DD  ((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBDebMask_GII  DD  0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBDebMask_III  DD  ((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0

RGBFinMask_GGG  DD  ((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_IGG  DD  0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_GIG  DD  ((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBFinMask_IIG  DD  0,0,((1<<(Prec+11))-1),0
RGBFinMask_GGI  DD  ((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBFinMask_IGI  DD  0,((1<<(Prec+5))-1),0,0
RGBFinMask_GII  DD  ((1<<Prec)-1),0,0,0
RGBFinMask_III  DD  0,0,0,0

; the main Surf 16bpp that DUGL will render to
;   user mostly has to set this as CurSurf unless other intermediate DgSurf
RendSurf            DD    0
RendFrontSurf       DD    0

SECTION .bss   ALIGN=32
