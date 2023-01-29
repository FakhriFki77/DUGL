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
GLOBAL DistanceDVEC4, DistancePow2DVEC4, DotDVEC4, LengthDVEC4, NormalizeDVEC4,  LerpDVEC4Res
GLOBAL MulValDVEC4, MulValDVEC4Res, MulValDVEC4Array, MulDVEC4, MulDVEC4Res, MulDVEC4Array
GLOBAL AddDVEC4, AddDVEC4Res, AddDVEC4Array
GLOBAL SubDVEC4, SubDVEC4Res, CrossDVEC4

GLOBAL DVEC4Array2DVec4i, DVEC4Array2DVec4iNT, DVEC4iArray2DVec4, DVEC4iArray2DVec4NT, ClipDVEC4Array
GLOBAL CopyDVEC4, CopyDVEC4NT, StoreDVEC4, StoreDVEC4NT

GLOBAL FetchDAAMinBBoxDVEC4Array, FetchDAABBoxDVEC4Array,  EqualDVEC4
GLOBAL DVEC4InAAMinBBox, DVEC4MaskInAAMinBBox, DVEC4ArrayIdxCountInAAMinBBox, DVEC4ArrayIdxCountInMapAAMinBBox
GLOBAL DVEC4MinRes, DVEC4MaxRes, DVEC4MinXYZ, DVEC4MaxXYZ


GLOBAL DMatrix4MulDMatrix4, DMatrix4MulDMatrix4Res_DMatrix4MulDMatrix4Persp, DMatrix4MulDVEC4ArrayPerspRes
GLOBAL DMatrix4MulDVEC4ArrayPerspResNT, DMatrix4MulDVEC4Array, DMatrix4MulDVEC4ArrayRes, DMatrix4MulDVEC4ArrayResNT
GLOBAL DMatrix4MulDVEC4ArrayResDVec4i, DMatrix4MulDVEC4ArrayResDVec4iNT
GLOBAL DMatrix4MulDVEC4ArrayResDVec2i, DMatrix4MulDVEC4ArrayResDVec2iNT

SECTION .text
ALIGN 32
[BITS 32]

DistanceDVEC4:
        ARG    DistDVEC1P, 4, DistDVEC2P, 4, DistFResP, 4

            MOV         EAX,[EBP+DistDVEC1P]
            MOV         ECX,[EBP+DistDVEC2P]
            MOVDQA      xmm3,[EAX]
            SUBPS       xmm3,[ECX]
            MULPS       xmm3,xmm3
            PSHUFD      xmm5,xmm3,(0<<6) | (3<<4) | (2<<2) | (1)
            PSHUFD      xmm4,xmm3,(0<<6) | (0<<4) | (3<<2) | (2)
            ADDSS       xmm5,xmm3
            ADDSS       xmm5,xmm4
            SQRTSS      xmm0,xmm5
            MOV         EAX,[EBP+DistFResP]
            MOVD        [EAX],xmm0

        RETURN

DistancePow2DVEC4:
        ARG    DistDVEC1Pow2P, 4, DistDVEC2Pow2P, 4, DistPow2FResP, 4

            MOV         EAX,[EBP+DistDVEC1Pow2P]
            MOV         ECX,[EBP+DistDVEC2Pow2P]
            MOVDQA      xmm3,[EAX]
            SUBPS       xmm3,[ECX]
            MULPS       xmm3,xmm3
            PSHUFD      xmm5,xmm3,(0<<6) | (3<<4) | (2<<2) | (1)
            PSHUFD      xmm4,xmm3,(0<<6) | (0<<4) | (3<<2) | (2)
            ADDSS       xmm5,xmm3
            ADDSS       xmm5,xmm4
            MOV         EAX,[EBP+DistPow2FResP]
            MOVD        [EAX],xmm5

        RETURN

; v1.x*v2.x + v1.y*v2.y + v1.z*v2.z
DotDVEC4:
        ARG    DotDVEC1P, 4, DotDVEC2P, 4, DotFResP, 4

            MOV         EAX,[EBP+DotDVEC1P]
            MOV         ECX,[EBP+DotDVEC2P]
            MOVDQA      xmm3,[EAX]
            MULPS       xmm3,[ECX]
            PSHUFD      xmm5,xmm3,(0<<6) | (3<<4) | (2<<2) | (1)
            PSHUFD      xmm4,xmm3,(0<<6) | (0<<4) | (3<<2) | (2)
            ADDSS       xmm5,xmm3
            ADDSS       xmm5,xmm4
            MOV         EAX,[EBP+DotFResP]
            MOVD        [EAX],xmm5

        RETURN

LengthDVEC4:
        ARG    LenDVECP, 4, LenFResP, 4

            MOV         EAX,[EBP+LenDVECP]
            MOVDQA      xmm3,[EAX]
            MULPS       xmm3,xmm3
            PSHUFD      xmm5,xmm3,(0<<6) | (3<<4) | (2<<2) | (1)
            PSHUFD      xmm4,xmm3,(0<<6) | (0<<4) | (3<<2) | (2)
            ADDSS       xmm5,xmm3
            ADDSS       xmm5,xmm4
            SQRTSS      xmm0,xmm5
            MOV         EAX,[EBP+LenFResP]
            MOVD        [EAX],xmm0

        RETURN

NormalizeDVEC4:
        ARG    NormDVECP, 4

            MOV         EAX,[EBP+NormDVECP]
            MOVDQA      xmm3,[EAX]
            MOVDQA      xmm1,xmm3
            MULPS       xmm3,xmm3
            PSHUFD      xmm5,xmm3,(0<<6) | (3<<4) | (2<<2) | (1)
            PSHUFD      xmm4,xmm3,(0<<6) | (0<<4) | (3<<2) | (2)
            ADDSS       xmm5,xmm3
            ADDSS       xmm5,xmm4
            MOVD        ECX,xmm5
            JECXZ       .NoDivNorm
            SQRTSS      xmm0,xmm5
            PSHUFD      xmm0,xmm0, 0 ; xmm0 = LEN | LEN | LEN | LEN
            DIVPS       xmm1,xmm0
            MOVDQA      [EAX],xmm1
.NoDivNorm:

        RETURN

;([v1.y * v2.z - v1.z * v2.y],  [v1.z * v2.x - v1.x * v2.z],  [v1.x * v2.y - v1.y * v2.x])
CrossDVEC4:
        ARG    CrossDVEC1P, 4, CrossDVEC2P, 4, CrossResDVECP, 4

            MOV         EAX,[EBP+CrossDVEC1P]
            MOV         ECX,[EBP+CrossDVEC2P]
            MOVDQA      xmm0,[EAX]
            MOVDQA      xmm1,[ECX]
            PSHUFD      xmm2,xmm0,(0<<6) | (0<<4) | (2<<2) | (1) ; v1.y | v1.Z | v1.x
            PSHUFD      xmm3,xmm1,(0<<6) | (1<<4) | (0<<2) | (2) ; y2.z | y2.x | y2.y
            PSHUFD      xmm0,xmm0,(0<<6) | (1<<4) | (0<<2) | (2) ; v1.z | v1.x | v1.y
            PSHUFD      xmm1,xmm1,(0<<6) | (0<<4) | (2<<2) | (1) ; y2.y | y2.z | y2.x
            MULPS       xmm2,xmm3
            MULPS       xmm0,xmm1
            MOV         EAX,[EBP+CrossResDVECP]
            SUBPS       xmm2,xmm0
            MOVDQA      [EAX],xmm2

        RETURN

; vRes = v1 + ((v2 - v1) * alpha)
LerpDVEC4Res:
        ARG    LerpALPHA, 4, LerpDVEC1P, 4, LerpDVEC2P, 4, LerpResDVECP, 4

            MOV         EAX,[EBP+LerpDVEC1P]
            MOV         ECX,[EBP+LerpDVEC2P]
            MOVD        xmm3,[EBP+LerpALPHA] ; xmm3 = ALPHA | 0 | 0 | 0
            MOVDQA      xmm0,[EAX]
            MOVDQA      xmm1,[ECX]
            PSHUFD      xmm3,xmm3,0 ; xmm3 = ALPHA | ALPHA | ALPHA | ALPHA
            SUBPS       xmm1,xmm0   ; xmm1 = v2 - v1
            MOV         EDX,[EBP+LerpResDVECP]
            MULPS       xmm1,xmm3   ; xmm1 = alpha * (v2-v1)
            ADDPS       xmm1,xmm0   ; xmm1 = v1 + alpha * (v2-v1)
            MOVDQA      [EDX],xmm1

        RETURN

;([v1.x * v2.x],  [v1.y * v2.y],  [v1.z * v2.z])
MulDVEC4:
        ARG    MulDVEC1P, 4, MulDVEC2P, 4

            MOV         EAX,[EBP+MulDVEC1P]
            MOV         ECX,[EBP+MulDVEC2P]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            MULPS       xmm0,[ECX] ; xmm1
            MOVDQA      [EAX],xmm0

        RETURN

;([v1.x * v2.x],  [v1.y * v2.y],  [v1.z * v2.z])
MulDVEC4Res:
        ARG    MulDVEC1ResP, 4, MulDVEC2ResP, 4, DVEC4ResMulP, 4

            MOV         EAX,[EBP+MulDVEC1ResP]
            MOV         ECX,[EBP+MulDVEC2ResP]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            MOV         EDX,[EBP+DVEC4ResMulP]
            MULPS       xmm0,[ECX] ; xmm1
            MOVDQA      [EDX],xmm0

        RETURN

MulValDVEC4:
        ARG    MulVDVECP, 4, MulVF, 4

            MOV         EAX,[EBP+MulVDVECP]
            MOVD        xmm0,[EBP+MulVF]
            MOVDQA      xmm3,[EAX]
            PSHUFD      xmm0,xmm0, 0 ; xmm0 = MulVF | MulVF | MulVF | MulVF
            MULPS       xmm3,xmm0
            MOVDQA      [EAX],xmm3

        RETURN

MulValDVEC4Res:
        ARG    MulVDVECResP, 4, MulVFRes, 4, MulDestDVECResP, 4

            MOV         EAX,[EBP+MulVDVECResP]
            MOVD        xmm0,[EBP+MulVFRes]
            MOVDQA      xmm3,[EAX]
            PSHUFD      xmm0,xmm0, 0 ; xmm0 = MulVF | MulVF | MulVF | MulVF
            MOV         EAX,[EBP+MulDestDVECResP]
            MULPS       xmm3,xmm0
            MOVDQA      [EAX],xmm3

        RETURN

MulDVEC4Array:
        ARG    MulDVECArrayP, 4, MulArraySize, 4, MulDVECP, 4

            MOV         ECX,[EBP+MulDVECP]
            MOV         EAX,[EBP+MulDVECArrayP]
            MOVDQA      xmm0,[ECX]
            MOV         ECX,[EBP+MulArraySize]
            JMP         SHORT MulValDVEC4Array.DoMul

MulValDVEC4Array:
        ARG    MulVDVECArrayP, 4, MulValArraySize, 4, MulVArrayF, 4

            MOVD        xmm0,[EBP+MulVArrayF]
            MOV         ECX,[EBP+MulValArraySize]
            MOV         EAX,[EBP+MulVDVECArrayP]
            PSHUFD      xmm0,xmm0, 0 ; xmm0 = MulVF | MulVF | MulVF | MulVF
.DoMul:     JECXZ       .endMulArray
            TEST        CL,1
            JZ          SHORT .NoUniqueMul
            MOVDQA      xmm1,[EAX]
            MULPS       xmm1,xmm0
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endMulArray
            LEA         EAX,[EAX+16]
.NoUniqueMul:
            SHR         ECX,1
.BcArrayMul:
            MOVDQA      xmm1,[EAX]
            MOVDQA      xmm2,[EAX+16]
            MULPS       xmm1,xmm0
            MULPS       xmm2,xmm0
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+16],xmm2
            DEC         ECX
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcArrayMul
.endMulArray:

        RETURN


;([v1.x + v2.x],  [v1.y + v2.y],  [v1.z + v2.z])
AddDVEC4:
        ARG    AddDVEC1P, 4, AddDVEC2P, 4

            MOV         EAX,[EBP+AddDVEC1P]
            MOV         ECX,[EBP+AddDVEC2P]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            ADDPS       xmm0,[ECX] ;xmm1
            MOVDQA      [EAX],xmm0

        RETURN

AddDVEC4Res:
        ARG    AddDVEC1ResP, 4, AddDVEC2ResP, 4, DVEC4ResAddP, 4

            MOV         EAX,[EBP+AddDVEC1ResP]
            MOV         ECX,[EBP+AddDVEC2ResP]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            MOV         EDX,[EBP+DVEC4ResAddP]
            ADDPS       xmm0,[ECX] ;xmm1
            MOVDQA      [EDX],xmm0

        RETURN

AddDVEC4Array:
        ARG    AddDVECArrayP, 4, AddDVECArraySize, 4, AddDVECP, 4

            MOV         EAX,[EBP+AddDVECP]
            MOV         ECX,[EBP+AddDVECArraySize]
            MOVDQA      xmm7,[EAX]
            JECXZ       .endAddArray
            MOV         EAX,[EBP+AddDVECArrayP]
            TEST        CL,1
            JZ          SHORT .NoUniqueAdd
            MOVDQA      xmm0,[EAX]
            ADDPS       xmm0,xmm7
            DEC         ECX
            MOVDQA      [EAX],xmm0
            JZ          SHORT .endAddArray
            LEA         EAX,[EAX+16]
.NoUniqueAdd:
            SHR         ECX,1
.BcArrayAdd:
            MOVDQA      xmm0,[EAX]
            MOVDQA      xmm1,[EAX+16]
            ADDPS       xmm0,xmm7
            ADDPS       xmm1,xmm7
            MOVDQA      [EAX],xmm0
            MOVDQA      [EAX+16],xmm1
            DEC         ECX
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcArrayAdd
.endAddArray:

        RETURN

;([v1.x - v2.x],  [v1.y - v2.y],  [v1.z - v2.z])
SubDVEC4:
        ARG    SubDVEC1P, 4, SubDVEC2P, 4

            MOV         EAX,[EBP+SubDVEC1P]
            MOV         ECX,[EBP+SubDVEC2P]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            SUBPS       xmm0,[ECX] ;xmm1
            MOVDQA      [EAX],xmm0

        RETURN

SubDVEC4Res:
        ARG    SubDVEC1ResP, 4, SubDVEC2ResP, 4, DVEC4ResSubP, 4

            MOV         EAX,[EBP+SubDVEC1ResP]
            MOV         ECX,[EBP+SubDVEC2ResP]
            MOVDQA      xmm0,[EAX]
            ;MOVDQA      xmm1,[ECX]
            MOV         EDX,[EBP+DVEC4ResSubP]
            SUBPS       xmm0,[ECX] ; xmm1
            MOVDQA      [EDX],xmm0

        RETURN

; Conversion / Clip ================

DVEC4Array2DVec4i:
        ARG    DVEC4iDstP, 4, DVEC4SrcP, 4, VEC4Array2iCount, 4

            MOV         EAX,[EBP+DVEC4iDstP]
            MOV         ECX,[EBP+VEC4Array2iCount]
            MOV         EDX,[EBP+DVEC4SrcP]
            JECXZ       .endConvArray

            TEST        CL,1
            JZ          SHORT .NoUniqueConv
            CVTTPS2DQ   xmm1,[EDX]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endConvArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueConv:
            SHR         ECX,1
.BcConvArray:
            CVTTPS2DQ   xmm1,[EDX]
            CVTTPS2DQ   xmm2,[EDX+16]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcConvArray
.endConvArray:

        RETURN

DVEC4iArray2DVec4:
        ARG    DVEC4DstP, 4, DVEC4iSrcP, 4, VEC4Array2Count, 4

            MOV         EAX,[EBP+DVEC4DstP]
            MOV         ECX,[EBP+VEC4Array2Count]
            MOV         EDX,[EBP+DVEC4iSrcP]
            JECXZ       .endConvArray

            TEST        CL,1
            JZ          SHORT .NoUniqueConv
            CVTDQ2PS    xmm1,[EDX]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endConvArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueConv:
            SHR         ECX,1
.BcConvArray:
            CVTDQ2PS    xmm1,[EDX]
            CVTDQ2PS    xmm2,[EDX+16]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcConvArray
.endConvArray:

        RETURN

DVEC4Array2DVec4iNT:
        ARG    DVEC4iDstNTP, 4, DVEC4SrcNTP, 4, VEC4Array2iNTCount, 4

            MOV         EAX,[EBP+DVEC4iDstNTP]
            MOV         ECX,[EBP+VEC4Array2iNTCount]
            MOV         EDX,[EBP+DVEC4SrcNTP]
            JECXZ       .endConvArray

            TEST        CL,1
            JZ          SHORT .NoUniqueConv
            CVTTPS2DQ   xmm1,[EDX]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            JZ          SHORT .endConvArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueConv:
            SHR         ECX,1
.BcConvArray:
            CVTTPS2DQ   xmm1,[EDX]
            CVTTPS2DQ   xmm2,[EDX+16]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            MOVNTDQ     [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcConvArray
.endConvArray:

        RETURN

DVEC4iArray2DVec4NT:
        ARG    DVEC4DstNTP, 4, DVEC4iSrcNTP, 4, VEC4Array2NTCount, 4

            MOV         EAX,[EBP+DVEC4DstNTP]
            MOV         ECX,[EBP+VEC4Array2NTCount]
            MOV         EDX,[EBP+DVEC4iSrcNTP]
            JECXZ       .endConvArray

            TEST        CL,1
            JZ          SHORT .NoUniqueConv
            CVTDQ2PS    xmm1,[EDX]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            JZ          SHORT .endConvArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueConv:
            SHR         ECX,1
.BcConvArray:
            CVTDQ2PS    xmm1,[EDX]
            CVTDQ2PS    xmm2,[EDX+16]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            MOVNTDQ     [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcConvArray
.endConvArray:

        RETURN

ClipDVEC4Array:
        ARG    DVEC4ArrayClipP, 4, DVEC4ArrayCount, 4, VEC4ClipMinP, 4, VEC4ClipMaxP, 4

            MOV         ECX,[EBP+VEC4ClipMaxP]
            MOV         EAX,[EBP+VEC4ClipMinP]
            MOVDQA      xmm4,[ECX] ; max
            MOVDQA      xmm3,[EAX] ; min
            MOV         ECX,[EBP+DVEC4ArrayCount]
            MOV         EAX,[EBP+DVEC4ArrayClipP]
            JECXZ       .endClipArray

            TEST        CL,1
            JZ          SHORT .NoUniqueClip
            MOVDQA      xmm1,[EAX]
            MAXPS       xmm1,xmm3
            MINPS       xmm1,xmm4
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endClipArray
            LEA         EAX,[EAX+16]
.NoUniqueClip:
            SHR         ECX,1
.BcClipArray:
            MOVDQA      xmm1,[EAX]
            MOVDQA      xmm2,[EAX+16]
            MAXPS       xmm1,xmm3
            MAXPS       xmm2,xmm3
            MINPS       xmm1,xmm4
            MINPS       xmm2,xmm4
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+16],xmm2
            DEC         ECX
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcClipArray

.endClipArray:

        RETURN

CopyDVEC4:
        ARG    DVEC4CopyDstP, 4, DVEC4CopySrcP, 4, VEC4CopyCount, 4

            MOV         EAX,[EBP+DVEC4CopyDstP]
            MOV         ECX,[EBP+VEC4CopyCount]
            MOV         EDX,[EBP+DVEC4CopySrcP]
            JECXZ       .endCopyArray

            TEST        CL,1
            JZ          SHORT .NoUniqueCopy
            MOVDQA      xmm1,[EDX]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endCopyArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueCopy:
            TEST        CL,2
            JZ          SHORT .NoDoubleCopy
            MOVDQA      xmm1,[EDX]
            MOVDQA      xmm2,[EDX+16]
            SUB         ECX,BYTE 2
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JZ          SHORT .endCopyArray
.NoDoubleCopy:
            SHR         ECX,2
.BcCopyArray:
            MOVDQA      xmm1,[EDX]
            MOVDQA      xmm3,[EDX+32]
            MOVDQA      xmm2,[EDX+16]
            MOVDQA      xmm4,[EDX+48]
            DEC         ECX
            MOVDQA      [EAX],xmm1
            MOVDQA      [EAX+32],xmm3
            MOVDQA      [EAX+16],xmm2
            MOVDQA      [EAX+48],xmm4
            LEA         EDX,[EDX+64]
            LEA         EAX,[EAX+64]
            JNZ         SHORT .BcCopyArray
.endCopyArray:

        RETURN

CopyDVEC4NT:
        ARG    DVEC4CopyNTDstP, 4, DVEC4CopyNTSrcP, 4, VEC4CopyNTCount, 4

            MOV         EAX,[EBP+DVEC4CopyNTDstP]
            MOV         ECX,[EBP+VEC4CopyNTCount]
            MOV         EDX,[EBP+DVEC4CopyNTSrcP]
            JECXZ       .endCopyArray

            TEST        CL,1
            JZ          SHORT .NoUniqueCopy
            MOVDQA      xmm1,[EDX]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            JZ          SHORT .endCopyArray
            LEA         EDX,[EDX+16]
            LEA         EAX,[EAX+16]
.NoUniqueCopy:
            TEST        CL,2
            JZ          SHORT .NoDoubleCopy
            MOVDQA      xmm1,[EDX]
            MOVDQA      xmm2,[EDX+16]
            SUB         ECX,BYTE 2
            MOVNTDQ     [EAX],xmm1
            MOVNTDQ     [EAX+16],xmm2
            LEA         EDX,[EDX+32]
            LEA         EAX,[EAX+32]
            JZ          SHORT .endCopyArray
.NoDoubleCopy:
            SHR         ECX,2
.BcCopyArray:
            MOVDQA      xmm1,[EDX]
            MOVDQA      xmm3,[EDX+32]
            MOVDQA      xmm2,[EDX+16]
            MOVDQA      xmm4,[EDX+48]
            DEC         ECX
            MOVNTDQ     [EAX],xmm1
            MOVNTDQ     [EAX+32],xmm3
            MOVNTDQ     [EAX+16],xmm2
            MOVNTDQ     [EAX+48],xmm4
            LEA         EDX,[EDX+64]
            LEA         EAX,[EAX+64]
            JNZ         SHORT .BcCopyArray
.endCopyArray:

        RETURN

StoreDVEC4:
        ARG    DVEC4storeDstP, 4, DVEC4storeSrcP, 4, VEC4storeCount, 4

            MOV         EAX,[EBP+DVEC4storeDstP]
            MOV         ECX,[EBP+VEC4storeCount]
            MOV         EDX,[EBP+DVEC4storeSrcP]
            JECXZ       .endCopyArray
            MOVDQA      xmm0,[EDX]
            TEST        CL,1
            JZ          SHORT .NoUniqueCopy
            DEC         ECX
            MOVDQA      [EAX],xmm0
            JZ          SHORT .endCopyArray
            LEA         EAX,[EAX+16]
.NoUniqueCopy:
            TEST        CL,2
            JZ          SHORT .NoDoubleCopy
            SUB         ECX,BYTE 2
            MOVDQA      [EAX],xmm0
            MOVDQA      [EAX+16],xmm0
            LEA         EAX,[EAX+32]
            JZ          SHORT .endCopyArray
.NoDoubleCopy:
            SHR         ECX,2
.BcCopyArray:
            MOVDQA      [EAX],xmm0
            MOVDQA      [EAX+32],xmm0
            MOVDQA      [EAX+16],xmm0
            MOVDQA      [EAX+48],xmm0
            DEC         ECX
            LEA         EAX,[EAX+64]
            JNZ         SHORT .BcCopyArray
.endCopyArray:

        RETURN

StoreDVEC4NT:
        ARG    DVEC4storeNTDstP, 4, DVEC4storeNTSrcP, 4, VEC4storeNTCount, 4

            MOV         EAX,[EBP+DVEC4storeNTDstP]
            MOV         ECX,[EBP+VEC4storeNTCount]
            MOV         EDX,[EBP+DVEC4storeNTSrcP]
            JECXZ       .endCopyArray
            MOVDQA      xmm0,[EDX]
            TEST        CL,1
            JZ          SHORT .NoUniqueCopy
            DEC         ECX
            MOVNTDQ     [EAX],xmm0
            JZ          SHORT .endCopyArray
            LEA         EAX,[EAX+16]
.NoUniqueCopy:
            TEST        CL,2
            JZ          SHORT .NoDoubleCopy
            SUB         ECX,BYTE 2
            MOVNTDQ     [EAX],xmm0
            MOVNTDQ     [EAX+16],xmm0
            LEA         EAX,[EAX+32]
            JZ          SHORT .endCopyArray
.NoDoubleCopy:
            SHR         ECX,2
.BcCopyArray:
            MOVNTDQ     [EAX],xmm0
            MOVNTDQ     [EAX+32],xmm0
            MOVNTDQ     [EAX+16],xmm0
            MOVNTDQ     [EAX+48],xmm0
            DEC         ECX
            LEA         EAX,[EAX+64]
            JNZ         SHORT .BcCopyArray
.endCopyArray:

        RETURN

; search/AABBox/Filtering

FetchDAAMinBBoxDVEC4Array:
        ARG    DVEC4ArrayFMBBoxP, 4, DVEC4ArrayFMBBoxCount, 4, FAAMBBoxP, 4

            MOV         ECX,[EBP+DVEC4ArrayFMBBoxCount]
            MOV         EAX,[EBP+DVEC4ArrayFMBBoxP]
            JECXZ       .endDoNothing
            MOVDQA      xmm6,[EAX] ; min
            DEC         ECX
            MOVDQA      xmm7,xmm6 ; max
            LEA         EAX,[EAX+16]
            JZ          SHORT .endFetchDAABBox

            TEST        CL,1
            JZ          SHORT .NoUniqueFetchDAABBox
            MOVDQA      xmm0,[EAX]
            DEC         ECX
            MINPS       xmm6,xmm0
            MAXPS       xmm7,xmm0
            JZ          SHORT .endFetchDAABBox
            LEA         EAX,[EAX+16]
.NoUniqueFetchDAABBox:
            SHR         ECX,1
.BcFetchDAABBoxArray:
            MOVDQA      xmm0,[EAX]
            MOVDQA      xmm1,[EAX+16]
            MINPS       xmm6,xmm0
            MAXPS       xmm7,xmm0
            MINPS       xmm6,xmm1
            MAXPS       xmm7,xmm1
            DEC         ECX
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcFetchDAABBoxArray

.endFetchDAABBox:
            MOV         ECX,[EBP+FAAMBBoxP]
            MOVDQA      [ECX],xmm6
            MOVDQA      [ECX+16],xmm7
.endDoNothing:

        RETURN

FetchDAABBoxDVEC4Array:
        ARG    DVEC4ArrayFBBoxP, 4, DVEC4ArrayFBBoxCount, 4, FAABBoxP, 4

            MOV         ECX,[EBP+DVEC4ArrayFBBoxCount]
            MOV         EAX,[EBP+DVEC4ArrayFBBoxP]
            OR          ECX,ECX
            JZ          .endDoNothing
            MOVDQA      xmm6,[EAX] ; min
            DEC         ECX
            MOVDQA      xmm7,xmm6 ; max
            LEA         EAX,[EAX+16]
            JZ          SHORT .endFetchDAABBox

            TEST        CL,1
            JZ          SHORT .NoUniqueFetchDAABBox
            MOVDQA      xmm0,[EAX]
            DEC         ECX
            MINPS       xmm6,xmm0
            MAXPS       xmm7,xmm0
            JZ          SHORT .endFetchDAABBox
            LEA         EAX,[EAX+16]
.NoUniqueFetchDAABBox:
            SHR         ECX,1
.BcFetchDAABBoxArray:
            MOVDQA      xmm0,[EAX]
            MOVDQA      xmm1,[EAX+16]
            MINPS       xmm6,xmm0
            MAXPS       xmm7,xmm0
            MINPS       xmm6,xmm1
            MAXPS       xmm7,xmm1
            DEC         ECX
            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcFetchDAABBoxArray

.endFetchDAABBox:
            MOV         ECX,[EBP+FAABBoxP]
            MOVDQA      xmm0,xmm6
            MOVDQA      [ECX],xmm6 ; min(x,y,z,d)
            PUNPCKLQDQ  xmm0,xmm7 ; min(x,y) | max(x,y) : (0, 1) | (2, 3)
            MOVDQA      [ECX+96],xmm7
            MOVDQA      xmm1,xmm0
            MOVDQA      xmm2,xmm0
            MOVDQA      xmm3,xmm0
            MOVDQA      xmm4,xmm1
            MOVDQA      xmm5,xmm2

            SHUFPS      xmm0,xmm6, (3<<6) | (2<<4) | (1<<2) | (2) ; maxX, minY, minZ, minD
            SHUFPS      xmm1,xmm6, (3<<6) | (2<<4) | (3<<2) | (2) ; maxX, maxY, minZ, minD
            SHUFPS      xmm2,xmm6, (3<<6) | (2<<4) | (3<<2) | (0) ; minX, maxY, minZ, minD

            MOVDQA      [ECX+16], xmm0
            SHUFPS      xmm3,xmm7, (3<<6) | (2<<4) | (1<<2) | (0) ; minX, minY, maxZ, maxD
            MOVDQA      [ECX+32], xmm1
            SHUFPS      xmm4,xmm7, (3<<6) | (2<<4) | (1<<2) | (2) ; maxX, minY, maxZ, maxD
            MOVDQA      [ECX+48], xmm2
            SHUFPS      xmm5,xmm7, (3<<6) | (2<<4) | (3<<2) | (0) ; minX, maxY, maxZ, maxD
            MOVDQA      [ECX+64], xmm3
            MOVDQA      [ECX+80], xmm4
            MOVDQA      [ECX+112], xmm5
.endDoNothing:

        RETURN


;// culling / collision / comparison

; compare equality of x,y and z
;ALIGN 32
EqualDVEC4:
        ARG    DVEC4Equal1P, 4, DVEC4Equal2P, 4

            MOV         ECX,[EBP+DVEC4Equal1P]
            MOV         EDX,[EBP+DVEC4Equal2P]
            MOVDQA      xmm0,[ECX] ; xmm0 = v1 (x, y, z, d)
            ;MOVDQA     xmm1,[EDX] ; xmm1 = min (x, y, z, d)
            XOR         EAX,EAX
            ;CMPEQPS        xmm0,[EDX]
            PCMPEQD     xmm0,[EDX]
            MOV         EBP,0x111
            PMOVMSKB    EDX,xmm0
            AND         EDX,EBP
            CMP         EDX,EBP ; x, y, Z mask
            SETE        AL

        RETURN


DVEC4InAAMinBBox:
        ARG    DVEC4PosP, 4, AAMinBBoxLimitsP, 4

            MOV         ECX,[EBP+DVEC4PosP]
            MOV         EAX,[EBP+AAMinBBoxLimitsP]
            MOVDQA      xmm0,[ECX] ; pos (x, y, z, d)
            MOVDQA      xmm1,[EAX] ; min (x, y, z, d)
            MOVDQA      xmm3,xmm0
            MOVDQA      xmm2,[EAX+16] ; max (x, y, z, d)
            CMPLEPS     xmm1,xmm0
            CMPLEPS     xmm3,xmm2
            PMOVMSKB    EDX,xmm1
            PMOVMSKB    ECX,xmm3
            MOV         BP,0x111
            AND         DX,CX
            XOR         EAX,EAX
            AND         DX,BP
            CMP         DX,BP
            SETE        AL

        RETURN

DVEC4ArrayIdxCountInAAMinBBox:
        ARG    DVEC4ArrayInAABBP, 4, IdxsInDVEC4ArrayP, 4, IdxsInDVEC4ArrayCount, 4, InIdxsAAMinBBoxLimitsP, 4

            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         EAX,[EBP+InIdxsAAMinBBoxLimitsP]
            MOV         ESI,[EBP+IdxsInDVEC4ArrayP]
            MOV         ECX,[EBP+IdxsInDVEC4ArrayCount]
            MOVDQA      xmm1,[EAX] ; min (x, y, z, d)
            MOVDQA      xmm2,[EAX+16] ; max (x, y, z, d)
            MOV         EBX,[EBP+DVEC4ArrayInAABBP]
            XOR         EAX,EAX
            MOV         DI,0x111
            XOR         EBP,EBP ; counter IN
.BcCountInIdx:

            MOV         EDX,[ESI]
            MOVDQA      xmm4,xmm1 ; xmm4 = min (x, y, z, d)
            SHL         EDX,4 ; *= 16 bytes (sizeof(DVEC4))
            MOVDQA      xmm0,[EBX+EDX] ; pos n (x, y, z, d)
            ADD         ESI,BYTE 4

            MOVDQA      xmm3,xmm0
            CMPLEPS     xmm4,xmm0
            CMPLEPS     xmm3,xmm2
            PAND        xmm4,xmm3
            PMOVMSKB    EDX,xmm4
            AND         DX,DI
            CMP         DX,DI
            SETE        AL
            DEC         ECX
            LEA         EBP,[EBP+EAX]
            JNZ         .BcCountInIdx
            MOV         EAX,EBP

            POP         EBX
            POP         EDI
            POP         ESI

        RETURN

DVEC4ArrayIdxCountInMapAAMinBBox:
        ARG    DVEC4ArrayInMapAABBP, 4, IdxsInMapDVEC4ArrayP, 4, IdxsInMapDVEC4ArrayCount, 4, InMapIdxsAAMinBBoxLimitsP, 4, InMapCharP, 4

            PUSH        ESI
            PUSH        EDI
            PUSH        EBX

            MOV         EAX,[EBP+InMapIdxsAAMinBBoxLimitsP]
            MOV         ESI,[EBP+IdxsInMapDVEC4ArrayP]
            MOV         ECX,[EBP+IdxsInMapDVEC4ArrayCount]
            MOVDQA      xmm1,[EAX] ; min (x, y, z, d)
            MOVDQA      xmm2,[EAX+16] ; max (x, y, z, d)
            MOV         EBX,[EBP+DVEC4ArrayInMapAABBP]
            MOV         EDI,[EBP+InMapCharP]
            XOR         EAX,EAX
            XOR         EBP,EBP ; counter IN
.BcCountInIdx:

            MOV         EDX,[ESI]
            MOVDQA      xmm4,xmm1 ; xmm4 = min (x, y, z, d)
            SHL         EDX,4 ; *= 16 bytes (sizeof(DVEC4))
            MOVDQA      xmm0,[EBX+EDX] ; pos n (x, y, z, d)
            ADD         ESI,BYTE 4

            MOVDQA      xmm3,xmm0
            CMPLEPS     xmm4,xmm0
            CMPLEPS     xmm3,xmm2
            PAND        xmm4,xmm3
            PMOVMSKB        EDX,xmm4
            AND         DX,0x111
            CMP         DX,0x111
            SETE        AL
            DEC         ECX
            STOSB           ; MOV [EDI], AL ; INC EDI
            LEA         EBP,[EBP+EAX]
            JNZ         .BcCountInIdx
            MOV         EAX,EBP

            POP         EBX
            POP         EDI
            POP         ESI

        RETURN

DVEC4MaskInAAMinBBox:
        ARG    DVEC4MaskPosP, 4, AAMinBBoxLimitsMaskP, 4, IPosMaskXYZD, 4

            MOV         ECX,[EBP+DVEC4MaskPosP]
            MOV         EAX,[EBP+AAMinBBoxLimitsMaskP]
            MOVDQA      xmm0,[ECX] ; pos (x, y, z, d)
            MOVDQA      xmm1,[EAX] ; min (x, y, z, d)
            MOVDQA      xmm3,xmm0
            MOVDQA      xmm2,[EAX+16] ; max (x, y, z, d)
            CMPLEPS     xmm1,xmm0
            CMPLEPS     xmm3,xmm2
            PMOVMSKB    EDX,xmm1
            PMOVMSKB    ECX,xmm3
            MOV         BP,[EBP+IPosMaskXYZD]
            AND         DX,CX
            XOR         EAX,EAX
            AND         DX,BP
            CMP         DX,BP
            SETE        AL

        RETURN

DVEC4MinRes:
        ARG    MinDVEC1ResP, 4, MinDVEC2ResP, 4, DVEC4ResMinP, 4

            MOV         EAX,[EBP+MinDVEC1ResP]
            MOV         ECX,[EBP+MinDVEC2ResP]
            MOVDQA      xmm0,[EAX]
            MOV         EDX,[EBP+DVEC4ResMinP]
            MINPS       xmm0,[ECX]
            MOVDQA      [EDX],xmm0

        RETURN

DVEC4MaxRes:
        ARG    MaxDVEC1ResP, 4, MaxDVEC2ResP, 4, DVEC4ResMaxP, 4

            MOV         EAX,[EBP+MaxDVEC1ResP]
            MOV         ECX,[EBP+MaxDVEC2ResP]
            MOVDQA      xmm0,[EAX]
            MOV         EDX,[EBP+DVEC4ResMaxP]
            MAXPS       xmm0,[ECX]
            MOVDQA      [EDX],xmm0

        RETURN

DVEC4MinXYZ:
        ARG    MinDVEC4XYZP, 4, ResXYZMinP, 4

            MOV         EAX,[EBP+MinDVEC4XYZP]
            MOV         EDX,[EBP+ResXYZMinP]
            MOVD        xmm0,[EAX]
            MINSS       xmm0,[EAX+4]
            MINSS       xmm0,[EAX+8]
            MOVD        [EDX],xmm0

        RETURN

DVEC4MaxXYZ:
        ARG    MaxDVEC4XYZP, 4, ResXYZMaxP, 4

            MOV         EAX,[EBP+MaxDVEC4XYZP]
            MOV         EDX,[EBP+ResXYZMaxP]
            MOVD        xmm0,[EAX]
            MAXSS       xmm0,[EAX+4]
            MAXSS       xmm0,[EAX+8]
            MOVD        [EDX],xmm0

        RETURN

; DMatrix4 ===================

DMatrix4MulDVEC4Array:
        ARG    DMAT4MulVEC4ArrayP, 4, DVEC4ArrayMulMAT4P, 4, DVEC4ArrayMulMAT4Count, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4Count]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4P]
            JZ          SHORT .NoUniqueMulMat4

            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            MOVDQA      [EAX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EAX,[EAX+16]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            MOVDQA      [EAX],xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            MOVDQA      [EAX+16],xmm0 ; ' second

            LEA         EAX,[EAX+32]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN


DMatrix4MulDVEC4ArrayRes:
        ARG    DMAT4MulVEC4ArrayResP, 4, DVEC4ArrayMulMAT4SrcP, 4, DVEC4ArrayMulMAT4CountRes, 4, DVEC4ArrayMulMAT4ResP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountRes]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrcP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResP]
            JZ          SHORT .NoUniqueMulMat4

            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            MOVDQA      [EDX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EAX,[EAX+16]
            LEA         EDX,[EDX+16]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            MOVDQA      [EDX],xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            MOVDQA      [EDX+16],xmm0 ; ' second

            LEA         EAX,[EAX+32]
            LEA         EDX,[EDX+32]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4PerspArray:
        ARG    DMAT4MulVEC4ArrayPerspP, 4, DVEC4ArrayMulMAT4PerspP, 4, DVEC4ArrayMulMAT4CountPersp, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountPersp]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayPerspP]
            MOVDQA      xmm4,[EAX]
            JECXZ       .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4PerspP]
            MOVDQA      xmm7,[EAX+48]

.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EDX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            PSHUFD      xmm0,xmm1,(3<<6) | (3<<4) | (3<<2) | (3)
            MAXPS       xmm0,[DQ_CONST_ONE]
            DIVPS       xmm1,xmm0

            MOVDQA      [EDX],xmm1
            LEA         EDX,[EDX+16]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN


DMatrix4MulDVEC4ArrayPerspRes:
        ARG    DMAT4MulVEC4ArrayResPerspP, 4, DVEC4ArrayMulMAT4SrcPerspP, 4, DVEC4ArrayMulMAT4CountResPersp, 4, DVEC4ArrayMulMAT4ResPerspP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountResPersp]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResPerspP]
            MOVDQA      xmm4,[EAX]
            JECXZ       .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrcPerspP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResPerspP]

.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            PSHUFD      xmm0,xmm1,(3<<6) | (3<<4) | (3<<2) | (3)
            MAXPS       xmm0,[DQ_CONST_ONE]
            DIVPS       xmm1,xmm0
            LEA         EAX,[EAX+16]
            MOVDQA      [EDX],xmm1
            LEA         EDX,[EDX+16]
            JNZ         SHORT .BcMulMAT4xVEC4

.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayPerspResNT:
        ARG    DMAT4MulVEC4ArrayResPerspNTP, 4, DVEC4ArrayMulMAT4SrcPerspNTP, 4, DVEC4ArrayMulMAT4CountResPerspNT, 4, DVEC4ArrayMulMAT4ResPerspNTP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountResPerspNT]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResPerspNTP]
            MOVDQA      xmm4,[EAX]
            JECXZ       .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrcPerspNTP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResPerspNTP]

.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            PSHUFD      xmm0,xmm1,(3<<6) | (3<<4) | (3<<2) | (3)
            MAXPS       xmm0,[DQ_CONST_ONE]
            DIVPS       xmm1,xmm0
            LEA         EAX,[EAX+16]
            MOVNTDQ     [EDX],xmm1
            LEA         EDX,[EDX+16]
            JNZ         SHORT .BcMulMAT4xVEC4

.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayResDVec4i:
        ARG     DMAT4MulVEC4ArrayResiP, 4, DVEC4ArrayMulMAT4SrciP, 4, DVEC4ArrayMulMAT4CountResi, 4, DVEC4ArrayMulMAT4ResiP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountResi]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResiP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrciP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResiP]
            JZ          SHORT .NoUniqueMulMat4

            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            CVTTPS2DQ   xmm1,xmm1
            LEA         EAX,[EAX+16]
            MOVDQA      [EDX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EDX,[EDX+16]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            CVTTPS2DQ   xmm2,xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MOVDQA      [EDX],xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            CVTTPS2DQ   xmm0,xmm0
            LEA         EAX,[EAX+32]
            MOVDQA      [EDX+16],xmm0 ; ' second
            LEA         EDX,[EDX+32]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayResDVec2i:
        ARG    DMAT4MulVEC4ArrayRes2iP, 4, DVEC4ArrayMulMAT4Src2iP, 4, DVEC2iArrayMulMAT4CountResi, 4, DVEC2iArrayMulMAT4ResiP, 4
            MOV         ECX,[EBP+DVEC2iArrayMulMAT4CountResi]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayRes2iP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4Src2iP]
            MOV         EDX,[EBP+DVEC2iArrayMulMAT4ResiP]
            JZ          SHORT .NoUniqueMulMat4
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            CVTTPS2DQ   xmm1,xmm1
            DEC         ECX
            MOVQ        [EDX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EAX,[EAX+16]
            LEA         EDX,[EDX+8]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC2i:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            CVTTPS2DQ   xmm2,xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MOVQ        [EDX],xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            CVTTPS2DQ   xmm0,xmm0
            LEA         EAX,[EAX+32]
            MOVQ        [EDX+8],xmm0 ; ' second
            LEA         EDX,[EDX+16]
            JNZ         SHORT .BcMulMAT4xVEC2i

.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayResDVec2iNT:
        ARG    DMAT4MulVEC4ArrayRes2iNTP, 4, DVEC4ArrayMulMAT4Src2iNTP, 4, DVEC2iArrayMulMAT4CountResiNT, 4, DVEC2iArrayMulMAT4ResiNTP, 4

            MOV         ECX,[EBP+DVEC2iArrayMulMAT4CountResiNT]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayRes2iNTP]
            OR              ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            MOV         EAX,[EBP+DVEC4ArrayMulMAT4Src2iNTP]
            MOV         EDX,[EBP+DVEC2iArrayMulMAT4ResiNTP]

            MOV         EBP,ECX
            SHR         ECX,1
            JZ              SHORT .TestUnique
.BcMulMAT4xVEC2i:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            CVTTPS2DQ   xmm2,xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            ;MOVQ           [EDX],xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            CVTTPS2DQ   xmm0,xmm0
            LEA         EAX,[EAX+32]
            PUNPCKLQDQ  xmm2,xmm0
            MOVNTDQ     [EDX],xmm2 ; ' second | first
            LEA         EDX,[EDX+16]
            JNZ         SHORT .BcMulMAT4xVEC2i
.TestUnique:
            AND         EBP,BYTE 1
            JZ          SHORT .NoUniqueMulMat4
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            CVTTPS2DQ   xmm1,xmm1
            MOVQ        [EDX],xmm1
.NoUniqueMulMat4:

.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayResNT:
        ARG    DMAT4MulVEC4ArrayResNTP, 4, DVEC4ArrayMulMAT4SrcNTP, 4, DVEC4ArrayMulMAT4CountResNT, 4, DVEC4ArrayMulMAT4ResNTP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountResNT]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResNTP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrcNTP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResNTP]
            JZ          SHORT .NoUniqueMulMat4

            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            MOVNTDQ     [EDX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EAX,[EAX+16]
            LEA         EDX,[EDX+16]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            MOVNTDQ     [EDX],xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            MOVNTDQ     [EDX+16],xmm0 ; ' second

            LEA         EAX,[EAX+32]
            LEA         EDX,[EDX+32]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDVEC4ArrayResDVec4iNT:
        ARG    DMAT4MulVEC4ArrayResiNTP, 4, DVEC4ArrayMulMAT4SrciNTP, 4, DVEC4ArrayMulMAT4CountResiNT, 4, DVEC4ArrayMulMAT4ResiNTP, 4

            MOV         ECX,[EBP+DVEC4ArrayMulMAT4CountResiNT]
            MOV         EAX,[EBP+DMAT4MulVEC4ArrayResiNTP]
            OR          ECX,ECX
            MOVDQA      xmm4,[EAX]
            JZ          .endDMat4MulDVEC4
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm7,[EAX+48]

            TEST        CL,1
            MOV         EAX,[EBP+DVEC4ArrayMulMAT4SrciNTP]
            MOV         EDX,[EBP+DVEC4ArrayMulMAT4ResiNTP]
            JZ          SHORT .NoUniqueMulMat4

            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            ADDPS       xmm1,xmm7
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            ADDPS       xmm1,xmm3
            DEC         ECX
            CVTTPS2DQ   xmm1,xmm1
            LEA         EAX,[EAX+16]
            MOVNTDQ     [EDX],xmm1
            JZ          SHORT .endDMat4MulDVEC4
            LEA         EDX,[EDX+16]
.NoUniqueMulMat4:
            SHR         ECX,1
.BcMulMAT4xVEC4:
            MOVDQA      xmm0,[EAX]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            MULPS       xmm3,xmm6
            MOVDQA      xmm0,[EAX+16] ; ' second
            ADDPS       xmm2,xmm1
            ADDPS       xmm3,xmm7
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0) ; ' second
            ADDPS       xmm2,xmm3
            MULPS       xmm1,xmm4 ; ' second
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2) ; ' second
            CVTTPS2DQ   xmm2,xmm2
            PSHUFD      xmm0,xmm0,(1<<6) | (1<<4) | (1<<2) | (1) ; ' second xmm0 take place of xmm2
            MOVNTDQ     [EDX],xmm2
            MULPS       xmm3,xmm6 ; ' second
            MULPS       xmm0,xmm5 ; ' second
            ADDPS       xmm3,xmm7 ; ' second
            ADDPS       xmm0,xmm1 ; ' second
            ADDPS       xmm0,xmm3 ; ' second
            DEC         ECX
            CVTTPS2DQ   xmm0,xmm0
            LEA         EAX,[EAX+32]
            MOVNTDQ     [EDX+16],xmm0 ; ' second
            LEA         EDX,[EDX+32]
            JNZ         SHORT .BcMulMAT4xVEC4
.endDMat4MulDVEC4:

        RETURN

DMatrix4MulDMatrix4:
        ARG    DMAT4MulLeftP, 4, DMAT4MulRightP, 4

            MOV         EAX,[EBP+DMAT4MulLeftP]
            MOV         ECX,[EBP+DMAT4MulRightP]
            MOVDQA      xmm4,[EAX]
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm0,[ECX]
            MOVDQA      xmm7,[EAX+48]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            PSHUFD      xmm0,xmm0,(3<<6) | (3<<4) | (3<<2) | (3)
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            MULPS       xmm0,xmm7
            ADDPS       xmm1,xmm3
            ADDPS       xmm1,xmm0
            MOVDQA      [EAX],xmm1
            JMP         SHORT DMatrix4MulDMatrix4Res.FinishLast3Rows

DMatrix4MulDMatrix4Res:
        ARG    DMAT4MulLeftResP, 4, DMAT4MulRightResP, 4, DMAT4MulResP, 4

            MOV         EAX,[EBP+DMAT4MulLeftResP]
            MOV         ECX,[EBP+DMAT4MulRightResP]
            MOVDQA      xmm4,[EAX]
            MOVDQA      xmm5,[EAX+16]
            MOVDQA      xmm6,[EAX+32]
            MOVDQA      xmm0,[ECX]
            MOVDQA      xmm7,[EAX+48]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            PSHUFD      xmm0,xmm0,(3<<6) | (3<<4) | (3<<2) | (3)
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            MULPS       xmm0,xmm7
            ADDPS       xmm1,xmm3
            MOV         EAX,[EBP+DMAT4MulResP]
            ADDPS       xmm1,xmm0
            MOVDQA      [EAX],xmm1

.FinishLast3Rows:
            MOVDQA      xmm0,[ECX+16]
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            PSHUFD      xmm0,xmm0,(3<<6) | (3<<4) | (3<<2) | (3)
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            MULPS       xmm0,xmm7
            ADDPS       xmm1,xmm3
            ADDPS       xmm1,xmm0

            MOVDQA      xmm3,[ECX+32]
            MOVDQA      [EAX+16],xmm1
            PSHUFD      xmm2,xmm3,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm1,xmm3,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm0,xmm3,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            PSHUFD      xmm3,xmm3,(3<<6) | (3<<4) | (3<<2) | (3)
            MULPS       xmm0,xmm6
            ADDPS       xmm1,xmm2
            MULPS       xmm3,xmm7
            ADDPS       xmm1,xmm0
            ADDPS       xmm1,xmm3

            MOVDQA      xmm0,[ECX+48]
            MOVDQA      [EAX+32],xmm1
            PSHUFD      xmm2,xmm0,(1<<6) | (1<<4) | (1<<2) | (1)
            PSHUFD      xmm1,xmm0,(0<<6) | (0<<4) | (0<<2) | (0)
            PSHUFD      xmm3,xmm0,(2<<6) | (2<<4) | (2<<2) | (2)
            MULPS       xmm1,xmm4
            MULPS       xmm2,xmm5
            PSHUFD      xmm0,xmm0,(3<<6) | (3<<4) | (3<<2) | (3)
            MULPS       xmm3,xmm6
            ADDPS       xmm1,xmm2
            MULPS       xmm0,xmm7
            ADDPS       xmm1,xmm3
            ADDPS       xmm1,xmm0
            MOVDQA      [EAX+48],xmm1

        RETURN

SECTION .data   ALIGN=32
DQ_CONST_ONE        DD      1.0, 1.0, 1.0, 1.0




