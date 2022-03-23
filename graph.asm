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


%include "param.asm"
%include "DGUTILS.asm"

; GLOBAL Functions
GLOBAL  _DgSetCurSurf, _DgSetSrcSurf, _DgGetCurSurf, _GetMaxResVSetSurf, _SurfCopy
GLOBAL  _DgClear16, _InBar16, _DgPutPixel16, _DgCPutPixel16
GLOBAL	_line16,_Line16,_linemap16,_LineMap16,_lineblnd16,_LineBlnd16, _linemapblnd16,_LineMapBlnd16
GLOBAL	_Poly16, _PutSurf16,_PutMaskSurf16,_PutSurfBlnd16,_PutMaskSurfBlnd16
GLOBAL	_PutSurfTrans16,_PutMaskSurfTrans16
GLOBAL	_SurfMaskCopy16, _SurfCopyBlnd16,_SurfMaskCopyBlnd16,_SurfCopyTrans16,_SurfMaskCopyTrans16
GLOBAL	_ResizeViewSurf16,_MaskResizeViewSurf16,_TransResizeViewSurf16,_MaskTransResizeViewSurf16,_BlndResizeViewSurf16,_MaskBlndResizeViewSurf16
GLOBAL  _SetFONT, _GetFONT, _OutText16, _WidthText,_WidthPosText,_PosWidthText

; GLOBAL Variables
GLOBAL _CurSurf, _RendFrontSurf, _RendSurf, _SrcSurf
GLOBAL _TPolyAdDeb, _TPolyAdFin, _TexXDeb, _TexXFin, _TexYDeb, _TexYFin, _PColDeb, _PColFin
GLOBAL	_CurFONT, _FntPtr, _FntHaut, _FntDistLgn, _FntLowPos, _FntHighPos
GLOBAL	_FntSens, _FntTab, _FntX, _FntY, _FntCol

GLOBAL	_vlfb,_rlfb,_ResH,_ResV,_MaxX,_MaxY,_MinX,_MinY,_OrgY,_OrgX,_SizeSurf,_OffVMem,_RMaxX,_RMaxY_RMinX
GLOBAL	_RMinY,_BitsPixel,_ScanLine,_Mask,_NegScanLine

GLOBAL _QBlue16Mask,_QGreen16Mask,_QRed16Mask


; GLOBAL Constants
Prec					EQU	12
MaxResV				EQU	2048
MaxDblSidePolyPts	EQU	128
BlendMask			EQU	0x1f
CMaskB_RGB16		EQU	0x1f	 ; blue bits 0->4
CMaskG_RGB16		EQU	0x3f<<5  ; green bits 5->10
CMaskR_RGB16		EQU	0x1f<<11 ; red bits 11->15
MaxDeltaDim			EQU	1<< (31-Prec)
SurfUtilSize		EQU     80

BITS 32

SECTION .text  ALIGN=32

%include "poly.asm"
%include "poly16.asm"
%include "fasthzline16.asm"
%include "hzline16.asm"
%include "pts16.asm"
%include "line16.asm"
%include "fill16.asm"

ALIGN 32
_DgSetCurSurf:
	ARG	S1, 4

		PUSH		ESI
		PUSH		EDI

		MOV			ESI,[EBP+S1]
		MOV			EAX,[ESI+_ResV-_CurSurf]
		CMP			EAX,MaxResV
		JG			.Error
		MOV			EDI,_CurSurf
		CopySurfDA
		OR			EAX,BYTE -1
		JMP			SHORT .Ok
.Error:
		XOR			EAX,EAX
.Ok:
		POP        EDI
		POP		   ESI

    RETURN

_GetMaxResVSetSurf:
		MOV			EAX,MaxResV
		RET

ALIGN 32
_DgSetSrcSurf:
	ARG	SrcS, 4
		PUSH			EDI
		PUSH	    	ESI

		MOV		 	ESI,[EBP+SrcS]
		MOV		   EDI,Svlfb
		CopySurfDA

		POP		   ESI
		POP		   EDI

    RETURN

ALIGN 32
_DgGetCurSurf:

	ARG	SGet, 4
        PUSH            EDI
        PUSH            ESI

        MOV		ESI,_CurSurf
        MOV		EDI,[EBP+SGet]
        CopySurfSA

        POP             ESI
        POP             EDI
    RETURN

ALIGN 32
_SurfCopy:
	ARG	PDstSrf, 4, PSrcSrf, 4

		PUSH		EDI
		PUSH		ESI
		PUSH		EBX

		MOV		ESI,[EBP+PSrcSrf]
		MOV		EDI,[EBP+PDstSrf]
		MOV		EBX,[ESI+_SizeSurf-_CurSurf]

		MOV		EDI,[EDI+_rlfb-_CurSurf]
		MOV		ESI,[ESI+_rlfb-_CurSurf]
		XOR     ECX,ECX
		TEST		EDI,0x7
		JZ		.CpyMMX
.CopyBAv:
        TEST	EDI,0x1
		JZ		.PasCopyBAv
		OR		EBX,EBX
		JZ		.FinSurfCopy
		DEC		EBX
		MOVSB
.PasCopyBAv:
.CopyWAv:
        TEST	EDI,0x2
		JZ		.PasCopyWAv
		CMP		EBX,BYTE 2
		JL		.CopyBAp
		SUB		EBX,BYTE 2
		MOVSW
.PasCopyWAv:
.CopyDAv:
        TEST		EDI,0x4
		JZ		    .PasCopyDAv
		CMP		    EBX,BYTE 4
		JL		    .CopyWAp
		SUB		    EBX,BYTE 4
		MOVSD
.PasCopyDAv:
        TEST		EDI,0x8
		JZ		    .PasCopyQAv
		CMP		    EBX,BYTE 8
		JL		    .CopyWAp
		MOVQ		xmm0,[ESI]
		SUB         EBX,8
		MOVQ		[EDI],xmm0
		LEA		    ESI,[ESI+8]
		LEA		    EDI,[EDI+8]
.PasCopyQAv:
.CpyMMX:
        SHLD        ECX,EBX,26 ; ECX = EBX >> 6 ; ECX should be zero
        JZ	        SHORT .PasCpyMMXBloc
        AND		    EBX,BYTE 0x3F
.BcCpyMMXBloc:
		MOVDQU		xmm0,[ESI]
		MOVDQU		xmm1,[ESI+32]
		MOVDQU		xmm2,[ESI+16]
		MOVDQU		xmm3,[ESI+48]
		MOVDQA		[EDI],xmm0
		MOVDQA		[EDI+32],xmm1
		MOVDQA		[EDI+16],xmm2
		MOVDQA		[EDI+48],xmm3
		DEC		    ECX
		LEA		    ESI,[ESI+64]
		LEA		    EDI,[EDI+64]
		JNZ		    SHORT .BcCpyMMXBloc
.PasCpyMMXBloc:
        SHLD    ECX,EBX,29 ; ECX = EBX >> 3 ; ECX should be zero
		JZ		SHORT .PasCpyMMX
		AND		EBX,BYTE 7
.BcCpyMMX:
		MOVQ	xmm0,[ESI]
		DEC		ECX
		MOVQ	[EDI],xmm0
		LEA		ESI,[ESI+8]
		LEA		EDI,[EDI+8]
		JNZ		SHORT .BcCpyMMX

.PasCpyMMX:
.CopyDAp:
		CMP		EBX,BYTE 4
		JL		.CopyWAp
		SUB		EBX,BYTE 4
		MOVSD
.PasCopyDAp:
.CopyWAp:
		CMP		EBX,BYTE 2
		JL		.CopyBAp
		SUB		EBX,BYTE 2
		MOVSW
.PasCopyWAp:
.CopyBAp:
		OR		EBX,EBX
		JZ		.FinSurfCopy
		MOVSB
.PasCopyBAp:
.FinSurfCopy:
		POP		EBX
		POP		ESI
		POP		EDI
		RETURN


_DgClear16:
	ARG	clrcol16, 4

		PUSH		EDI

		MOVD		xmm0,[EBP+clrcol16]
		MOV         EDX,[_SizeSurf]
		PSHUFLW	    xmm0,xmm0,0
		MOV         EDI,[_rlfb]
		PUNPCKLQDQ  xmm0,xmm0
		XOR         ECX,ECX
		SHR         EDX,1
		MOVD        EAX,xmm0

		@SolidHLineSSE16

		POP			EDI
		RETURN

ALIGN 32
_DgPutPixel16:
    ARG PPX, 4, PPY, 4, PPCOL16, 4

        ;PUSH       EDI ESI EBX

        MOV         EDX,[_NegScanLine]
		MOV         ECX,[EBP+PPX]
		IMUL        EDX,[EBP+PPY]
		MOV         EAX,[EBP+PPCOL16]
		ADD         EDX,[_vlfb]
		MOV         [EDX+ECX*2],AX

		;POP     EDI ESI EBX

    RETURN

_DgCPutPixel16:
    ARG CPPX, 4, CPPY, 4, CPPCOL16, 4

		MOV			EDX,[EBP+CPPY]
		MOV			ECX,[EBP+CPPX]
		CMP         EDX,[_MaxY]
		JG          SHORT .Clip
		CMP         ECX,[_MaxX]
		JG          SHORT .Clip
		CMP         EDX,[_MinY]
		JL          SHORT .Clip
		CMP         ECX,[_MinX]
		JL          SHORT .Clip

		IMUL	    EDX,[_NegScanLine]
		MOV		   	EAX,[EBP+CPPCOL16]
		ADD		   	EDX,[_vlfb]
		MOV		   	[EDX+ECX*2],AX
.Clip:

    RETURN

;===========================
;=================== FONT ==

_SetFONT:
	ARG	SF, 4

		MOV		   EAX,[EBP+SF]
		MOVDQU      xmm0,[EAX]
		MOVDQU      xmm1,[EAX+16]
		MOVDQA      [_CurFONT],xmm0
		MOVDQA      [_CurFONT+16],xmm1

		RETURN

_GetFONT:
	ARG	CF, 4

		MOV		   EAX,[EBP+CF]
		MOVDQA      xmm0,[_CurFONT]
		MOVDQA      xmm1,[_CurFONT+16]
		MOVDQU      [EAX],xmm0
		MOVDQU      [EAX+16],xmm1

		RETURN

_WidthText:
	ARG	LStr, 4
		PUSH		EBX
		PUSH		ESI

		MOV			EBX,[_FntPtr]
		XOR			ECX,ECX
		OR			EBX,EBX
		JZ			.FinLargText
		MOV			ESI,[EBP+LStr]
		XOR			EAX,EAX
.BcCalcLarg:
		LODSB
		OR			AL,AL
		JZ			.FinLargText
		CMP			AL,13
		JZ			.FinLargText
		CMP			AL,10
		JZ			.FinLargText
		CMP			AL,9	   ; Tab
		JNE			.PasTrtTab
		MOV			AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR			EAX,EAX
		MOV			AL,[_FntTab]
		IMUL		EDX,EAX
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.FinLargText:
		OR			ECX,ECX
		JNS			.Positiv
		NEG			ECX
.Positiv:
		MOV			EAX,ECX
		OR			EAX,EAX
		JZ			.ZeroRien
		DEC			EAX
.ZeroRien:
		POP			ESI
		POP			EBX
		RETURN

_WidthPosText:
	ARG	LPStr, 4, LPPos, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV			EBX,[_FntPtr]
		XOR			ECX,ECX
		OR			EBX,EBX
		JZ			.FinLargText
		MOV			ESI,[EBP+LPStr]
		MOV			EDI,[EBP+LPPos]
		XOR			EAX,EAX
		OR			EDI,EDI
		JZ			.FinLargText
		ADD			EDI,ESI
.BcCalcLarg:
		XOR			EAX,EAX
		CMP			EDI,ESI
		JBE			.FinLargText
		LODSB
		OR			AL,AL
		JZ			.FinLargText
		CMP			AL,13
		JE			.FinLargText
		CMP			AL,10
		JE			.FinLargText
		CMP			AL,9	   ; Tab
		JNE			.PasTrtTab
		MOV			AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR			EAX,EAX
		MOV			AL,[_FntTab]
		IMUL		EDX,EAX
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.FinLargText:
		OR			ECX,ECX
		JNS			.Positiv
		NEG			ECX
.Positiv:
		MOV			EAX,ECX
		OR			EAX,EAX
		JZ			.ZeroRien
		DEC			EAX
.ZeroRien:

		POP			ESI
		POP			EDI
		POP			EBX
		RETURN

_PosWidthText:
	ARG	PLStr, 4, PLLarg, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV			EBX,[_FntPtr]
		XOR			ECX,ECX
		OR			EBX,EBX
		JZ			.FinPosLargText
		MOV			ESI,[EBP+PLStr]
		XOR			EDI,EDI
.BcCalcLarg:
		XOR			EAX,EAX
		CMP			ECX,[EBP+PLLarg]
		JAE			.FinPosLargText
		LODSB
		INC			EDI
		OR			AL,AL
		JZ			.FinPosLargText
		CMP			AL,13
		JE			.FinPosLargText
		CMP			AL,10
		JE			.FinPosLargText
		CMP			AL,9	   ; Tab
		JNE			.PasTrtTab
		MOV			AL,32
		MOVSX		EDX,BYTE [EBX+EAX*8+4] ; space
		XOR			EAX,EAX
		MOV			AL,[_FntTab]
		IMUL		EDX,EAX
		OR			EDX,EDX
		JS			.NegTab
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.NegTab:
		SUB			ECX,EDX
		JMP			SHORT .BcCalcLarg
.PasTrtTab:
		MOVSX		EDX,BYTE [EBX+EAX*8+4]
		OR			EDX,EDX
		JS			.NegNorm
		ADD			ECX,EDX
		JMP			SHORT .BcCalcLarg
.NegNorm:
		SUB			ECX,EDX
		JMP			SHORT .BcCalcLarg

.FinPosLargText:
		OR			EDI,EDI
		JZ			.PosZero
		DEC			EDI
.PosZero:
		MOV			EAX,EDI

		POP			ESI
		POP			EDI
		POP			EBX
		RETURN


ALIGN 32
_OutText16:
	ARG	Str16, 4
		PUSH		EBX
		PUSH		EDI
		PUSH		ESI

		MOV			EBX,[_FntPtr]
		OR		   	EBX,EBX
		JZ		   .FinOutText
		MOV			ESI,[EBP+Str16]
		XOR			EAX,EAX
.BcOutChar:
		LODSB
		MOVD		xmm3,ESI
		MOVD		xmm4,EAX
		MOVD		xmm5,EBX
		OR			AL,AL
		JZ			.FinOutText
;**************** Affichage et traitement **********************************
;***************************************************************************
		CMP			AL,13		 ;** Debut Cas Special
		MOVSX		ESI,BYTE [EBX+EAX*8+4] ; PlusX
		JE			.DebLigne
		XOR			EDX,EDX
		CMP			AL,10
		MOV			DL,[EBX+EAX*8+7] ;Largeur
		JE			.DebNextLigne
		XOR			ECX,ECX
		CMP			AL,9
		MOV			CL,[EBX+EAX*8+6] ; Haut
		JE			.TabCar	 ;** Fin   Cas Special
		MOVSX		EDI,BYTE [EBX+EAX*8+5] ; PlusLgn
		MOV			[ChLarg],EDX
		MOV			[ChPlusX],ESI
		MOVD		xmm6,[EBX+EAX*8]        ; PtrDat
		OR			ESI,ESI
		MOV			[ChPlusLgn],EDI
		MOV			[ChHaut],ECX
		JNS			.GauchDroit
		JZ			SHORT .RienZero1
		LEA			EAX,[ESI+1]
		ADD			[_FntX],EAX
.GauchDroit:
.RienZero1:
		MOV			EBP,[_FntX]  ; MinX
		ADD			EDI,[_FntY]  ; MinY
		LEA			EBX,[EBP+EDX-1] ; MaxX: EBX=MinX+Larg-1
		LEA			ESI,[EDI+ECX-1] ; MaxY: ESI=MinY+Haut-1

		CMP			EBX,[_MaxX]
		JG			.CharClip
		CMP			ESI,[_MaxY]
		JG			.CharClip
		CMP			EBP,[_MinX]
		JL			.CharClip
		CMP			EDI,[_MinY]
		JL			.CharClip
;****** trace caractere IN *****************************
.CharIn:
		MOV			ECX,[_ScanLine]
		MOV			EBP,EDX ;Largeur
		IMUL		EDI,ECX
		LEA			ECX,[ECX+EDX*2]
		NEG			EDI
		MOV			[ChPlus],ECX
		ADD			EDI,[_FntX]
		ADD			EDI,[_FntX]
		MOV			EDX,[ChHaut]
		ADD			EDI,[_vlfb]
		XOR			EAX,EAX
		MOVD		ESI,xmm6
		MOV			EAX,[_FntCol]
.LdNext:
		MOV			EBX,[ESI]
		MOV			CL,32
		ADD			ESI,BYTE 4
;ALIGN 4
.BcDrCarHline:
		TEST		BL,1
		JZ			SHORT .PasDrPixel
		MOV			[EDI],AX
.PasDrPixel:
		SHR			EBX,1
		DEC			EBP
		LEA			EDI,[EDI+2]
		JZ			SHORT .FinDrCarHline
		DEC			CL
		JNZ			SHORT .BcDrCarHline
		JZ			.LdNext
;ALIGN 4
.FinDrCarHline:
		MOV			EBX,[ESI]
		SUB			EDI,[ChPlus]
		MOV			CL,32
		LEA			ESI,[ESI+4]
		DEC			DL
		MOV 		EBP,[ChLarg]
		JNZ			.BcDrCarHline
		JMP			.FinDrChar
;****** Trace Caractere Clip ***************************
.CharClip:
		CMP			EBX,[_MinX]
		JL			.FinDrChar
		CMP			ESI,[_MinY]
		JL			.FinDrChar
		CMP			EBP,[_MaxX]
		JG			.FinDrChar
		CMP			EDI,[_MaxY]
		JG			.FinDrChar
		; traitement MaxX********************************************
		CMP			EBX,[_MaxX]	; MaxX>_MaxX
		MOV			EAX,EBX
		JLE			.PasApPlus
		SUB			EAX,[_MaxX]	; DXAp = EAX = MaxX-_MaxX
		SUB			EDX,EAX 	; EDX = Larg-DXAp
		CMP			EAX,BYTE 32
		JL			SHORT .PasApPlus
		MOV			DWORD [ChApPlus],4
		JMP			SHORT .ApPlus
.PasApPlus:
		XOR			EAX,EAX
		MOV			[ChApPlus],EAX
.ApPlus:
		; traitement MinX********************************************
		MOV			EAX,[_MinX]
		SUB			EAX,EBP
		JLE			.PasAvPlus
		SUB			EDX,EAX

		CMP			EAX,BYTE 32
		JL			.PasAvPlus2
		MOV			DWORD [ChAvPlus],4
		SUB			AL,32
		MOV			AH,32
		MOV			[ChAvDecal],AL
		SUB			AH,AL
		MOV			[ChNbBitDat],AH
		JMP			SHORT .AvPlus
.PasAvPlus2:
		MOV			AH,32
		MOV			[ChAvDecal],AL
		SUB			AH,AL
		MOV			[ChNbBitDat],AH
		XOR			EAX,EAX
		MOV			[ChAvPlus],EAX
		JMP			SHORT .AvPlus
.PasAvPlus:
		XOR			EAX,EAX
		MOV			BYTE [ChNbBitDat],32
		MOV			[ChAvPlus],EAX
		MOV			[ChAvDecal],AL
.AvPlus:
		; traitement MaxY********************************************
		CMP			ESI,[_MaxY]	; MaxY>_MaxY
		MOV			EAX,ESI
		JLE			.PasSupMaxY
		SUB			EAX,[_MaxY]	; DY = EAX = MaxY-_MaxY
		SUB			ECX,EAX 	; ECX = Haut-DY
.PasSupMaxY:
		; traitement MinY********************************************
		MOV			EAX,[_MinY]
		SUB			EAX,EDI
		JLE			.PasInfMinY
		SUB			ECX,EAX
		MOV			EDI,[_MinY]
		CMP			DWORD [ChLarg],BYTE 32
		JLE			.Larg1DD
.Larg2DD:
		IMUL		EAX,BYTE 8
		MOVD		xmm7,EAX
		PADDD		xmm6,xmm7
		JMP			SHORT .PasInfMinY
.Larg1DD:
		IMUL		EAX,BYTE 4
		MOVD		xmm7,EAX
		PADDD		xmm6,xmm7
.PasInfMinY:
		MOV			[ChHaut],ECX
		MOV			[ChLarg],EDX
;************************************************
		MOV			ECX,[_ScanLine]
		MOV			EBP,EDX ;Largeur
		IMUL		EDI,ECX
		XOR			EAX,EAX
		LEA			ECX,[ECX+EDX*2] ;
		MOV			AL,[ChAvDecal]
		NEG			EDI
		MOV			[ChPlus],ECX
		ADD			EDI,[_FntX]
		ADD			EDI,[_FntX]  ; 2*_FntX 16bpp
		LEA			EDI,[EDI+EAX*2]      ; EDI +=2*ChAvDecal
		MOV			EDX,[ChHaut]
		ADD			EDI,[_vlfb]
		MOVD		ESI,xmm6

		MOV			EAX,[_FntCol]  ;*************
		ADD			ESI,[ChAvPlus]
		MOV			EBX,[ESI]
		MOV			CL,[ChAvDecal]
		MOV			CH,[ChNbBitDat]
		ADD			ESI,BYTE 4
		SHR			EBX,CL
		JMP			SHORT .CBcDrCarHline

.CLdNext:
		MOV			EBX,[ESI]
		MOV			CH,32
		ADD			ESI,BYTE 4
;ALIGN 4
.CBcDrCarHline:
		TEST		BL,1
		JZ			SHORT .CPasDrPixel
		MOV			[EDI],AX
.CPasDrPixel:
		SHR			EBX,1
		DEC			EBP
		LEA			EDI,[EDI+2]
		JZ			SHORT .CFinDrCarHline
		DEC			CH
		JNZ			SHORT .CBcDrCarHline
		JZ			SHORT .CLdNext
;ALIGN 4
.CFinDrCarHline:
		ADD			ESI,[ChApPlus]
		SUB			EDI,[ChPlus]
		ADD			ESI,[ChAvPlus]
		MOV			CL,[ChAvDecal]
		MOV			EBX,[ESI]
		MOV			CH,[ChNbBitDat]
		SHR			EBX,CL
		LEA			ESI,[ESI+4]
		DEC			DL
		MOV			EBP,[ChLarg]
		JNZ			.CBcDrCarHline

.FinDrChar:;********************************************
		MOV			ESI,[ChPlusX]
		OR			ESI,ESI
		JS			SHORT .DroitGauch
		JZ			SHORT .RienZero2
		ADD			[_FntX],ESI
.DroitGauch:
.RienZero2:
		OR			ESI,ESI
		JNS			SHORT .GauchDroit2
		JZ			.RienZero3
		MOV			EAX,[_FntX]
		DEC			EAX
		MOV			[_FntX],EAX
.GauchDroit2:
.RienZero3:
		JMP			SHORT .Norm

.DebNextLigne:
		XOR			EAX,EAX 	      ;***debut trait Cas sp
		MOV			AL,[_FntDistLgn]
		MOV			EBX,[_FntY]
		SUB			EBX,EAX
		MOV			[_FntY],EBX
.DebLigne:
		MOV			AL,[_FntSens]
		OR			AL,AL
		JZ			SHORT .GchDrt
		MOV			EBX,[_MaxX]
		JMP			SHORT .DrtGch
.GchDrt:
		MOV			EBX,[_MinX]
.DrtGch:
		MOV			[_FntX],EBX
		JMP			SHORT .Norm
.TabCar:
		MOV			AL,32	     ; TAB
		MOV			ESI,[_FntX]
		MOVZX		ECX,BYTE [_FntTab]
		MOVSX		EAX,BYTE [EBX+EAX*8+4] ; PlusX
		IMUL		ECX,EAX
		ADD			ESI,ECX
		MOV			[_FntX],ESI	;***********fin trait Cas sp
.Norm:
		MOVD		ESI,xmm3
		MOVD		EAX,xmm4
		MOVD		EBX,xmm5
		JMP		.BcOutChar
.FinOutText:
		POP			ESI
		POP			EDI
		POP			EBX
		RETURN

_InBar16:
	ARG	InRect16MinX, 4, InRect16MinY, 4, InRect16MaxX, 4, InRect16MaxY, 4, InRect16Col, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOVD		xmm0,[EBP+InRect16Col]
		MOV         EDI,[EBP+InRect16MinY]
		PSHUFLW		xmm0,xmm0, 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
		MOV         ESI,[EBP+InRect16MaxY]
		PUNPCKLQDQ	xmm0,xmm0
		MOV         ECX,[EBP+InRect16MaxX]
		SUB         ESI,EDI ; = (_MaxY - MinY)
		MOV         EBX,[EBP+InRect16MinX]
		IMUL        EDI,[_NegScanLine]
		LEA			EBP,[ESI+1]
		SUB			ECX,EBX
		ADD         EDI,[_vlfb]
		INC         ECX
		LEA         EDI,[EDI+EBX*2]
		MOV			ESI,ECX ; ESI = dest hline size
		MOVD		EAX,xmm0
		MOV        	EBX,EDI ; EBX = start Hline dest
		XOR			ECX,ECX ; should be zero for @SolidHLineSSE16
.BcBar:
        MOV			EDI,EBX ; start hline
        MOV			EDX,ESI ; dest hline size

		@SolidHLineSSE16

        ADD       	EBX,[_NegScanLine] ; next hline
        DEC         EBP
        JNZ         .BcBar

		POP			EDI
		POP			EBX
		POP			ESI

    RETURN

;ClearSurf16(int clrcol)
;_ClearSurf16:
;	ARG	ClearSurf16Col, 4
;
;		PUSH		ESI
;		PUSH		EBX
;		PUSH		EDI
;
;
;		MOVD		xmm0,[EBP+ClearSurf16Col]
;		MOV         EDI,[_MinY]
;		PSHUFLW		xmm0,xmm0, 0 ; xmm0 = clr16 | clr16 | clr16 | clr16
;		PUNPCKLQDQ	xmm0,xmm0
;
;		MOV         EBP,[_MaxY]
;		MOV         ECX,[_MaxX]
;		SUB         EBP,EDI ; = (_MaxY - MinY)
;		MOV         EBX,[_MinX]
;		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
;		IMUL        EDI,[_NegScanLine]
;		SUB			ECX,EBX
;		ADD         EDI,[_vlfb]
;		INC         ECX
;		LEA         EDI,[EDI+EBX*2]
;		MOV			ESI,ECX ; ESI = dest hline size
;		MOVD		EAX,xmm0
;		MOV        	EBX,EDI ; EBX = start Hline dest
;		XOR			ECX,ECX ; should be zero for @SolidHLineSSE16
;.BcClear:
;        MOV			EDI,EBX ; start hline
;        MOV			EDX,ESI ; dest hline size
;
;		@SolidHLineSSE16
;
;        ADD       	EBX,[_NegScanLine] ; next hline
;        DEC         EBP
;        JNZ         .BcClear
;
;		POP			EDI
;		POP			EBX
;		POP			ESI
;
;    RETURN

; == xxxResizeViewSurf16 =====================================

_ResizeViewSurf16:
	ARG	SrcResizeSurf16, 4, ResizeRevertHz, 4, ResizeRevertVt, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcResizeSurf16]
		MOV		    EDI,_SrcSurf
		XOR         EBX,EBX ; store flags revert Hz and Vt
		CopySurfDA  ; copy the source surface


		MOV		    EAX,[EBP+ResizeRevertHz]
		MOV		    EDX,[EBP+ResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

        @InFastTextHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN


_MaskResizeViewSurf16:
	ARG	SrcMaskResizeSurf16, 4, MaskResizeRevertHz, 4, MaskResizeRevertVt, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcMaskResizeSurf16]
		MOV		    EDI,_SrcSurf
		XOR         EBX,EBX ; store flags revert Hz and Vt
		CopySurfDA  ; copy the source surface


		MOV		    EAX,[EBP+MaskResizeRevertHz]
		MOV		    EDX,[EBP+MaskResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		PSHUFLW 	xmm7,[SMask], 0 ; xmm7 = SMask | SMask | SMask | SMask
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

        @InFastMaskTextHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN


_TransResizeViewSurf16:
	ARG	SrcTransResizeSurf16, 4, TransResizeRevertHz, 4, TransResizeRevertVt, 4, TransResizeSurf16, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcTransResizeSurf16]
		MOV		    EDI,_SrcSurf
		XOR         EBX,EBX ; store flags revert Hz and Vt
		CopySurfDA  ; copy the source surface

		MOV			EAX,[EBP+TransResizeSurf16] ;
		AND			EAX,BYTE BlendMask
		JZ			.End ; zero transparency no need to draw any thing
		MOV			EDX,EAX ;
		INC			EAX

		XOR		    DL,BlendMask ; 31-blendsrc
		MOVD		xmm7,EAX
		MOVD		xmm6,EDX
		PSHUFLW 	xmm7,xmm7,0
		PSHUFLW	    xmm6,xmm6,0
		PUNPCKLQDQ  xmm7,xmm7
		PUNPCKLQDQ  xmm6,xmm6


		MOV		    EAX,[EBP+TransResizeRevertHz]
		MOV		    EDX,[EBP+TransResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

        @InFastTransTextHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

.End:
        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN

_MaskTransResizeViewSurf16:
	ARG	SrcMaskTransResizeSurf16, 4, MaskTransResizeRevertHz, 4, MaskTransResizeRevertVt, 4, MaskTransResizeSurf16, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcMaskTransResizeSurf16]
		MOV		    EDI,_SrcSurf
		XOR         EBX,EBX ; store flags revert Hz and Vt
		CopySurfDA  ; copy the source surface

		MOV			EAX,[EBP+MaskTransResizeSurf16] ;
		AND			EAX,BYTE BlendMask
		JZ			.End ; zero transparency no need to draw any thing
		MOV			EDX,EAX ;
		PSHUFLW     xmm0,[SMask],0
		INC			EAX

		XOR		    DL,BlendMask ; 31-blendsrc
		MOVD		xmm7,EAX
		MOVD		xmm6,EDX
		PSHUFLW 	xmm7,xmm7,0
		PSHUFLW	    xmm6,xmm6,0
		PUNPCKLQDQ  xmm7,xmm7
		PUNPCKLQDQ  xmm6,xmm6
		PUNPCKLQDQ	xmm0,xmm0
		MOVDQA		[QMulSrcBlend],xmm7
		MOVDQA  	[DQ16Mask],xmm0

		MOV		    EAX,[EBP+MaskTransResizeRevertHz]
		MOV		    EDX,[EBP+MaskTransResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

        @InFastMaskTransTextHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

.End:
        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN



_BlndResizeViewSurf16:
	ARG	SrcBlndResizeSurf16, 4, BlndResizeRevertHz, 4, BlndResizeRevertVt, 4, ColBlndResizeSurf16, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcBlndResizeSurf16]
		MOV		    EDI,_SrcSurf
		CopySurfDA  ; copy the source surface


; prepare col blending
		MOV			EAX,[EBP+ColBlndResizeSurf16] ;
		MOV			EBX,EAX ;
		MOV			ECX,EAX ;
		MOV			EDX,EAX ;
		AND			EBX,[_QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[_QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		AND			EDX,[_QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			EDI,EAX
		XOR			AL,BlendMask ; 31-blendsrc
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		xmm3,EBX
		MOVD		xmm4,ECX
		MOVD		xmm5,EDX
		MOVD		xmm7,EDI
		PSHUFLW		xmm3,xmm3,0
		PSHUFLW		xmm4,xmm4,0
		PSHUFLW		xmm5,xmm5,0
		PSHUFLW		xmm7,xmm7,0
		PUNPCKLQDQ  xmm3,xmm3
		PUNPCKLQDQ  xmm4,xmm4
		PUNPCKLQDQ  xmm5,xmm5
		PUNPCKLQDQ  xmm7,xmm7
		MOVDQA		xmm6,[_QRed16Mask]

		MOV		    EAX,[EBP+BlndResizeRevertHz]
		XOR         EBX,EBX ; store flags revert Hz and Vt
		MOV		    EDX,[EBP+BlndResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

		@InFastTextBlndHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

.End:
        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN

_MaskBlndResizeViewSurf16:
	ARG	SrcMaskBlndResizeSurf16, 4, MaskBlndResizeRevertHz, 4, MaskBlndResizeRevertVt, 4, ColMaskBlndResizeSurf16, 4

		PUSH		ESI
		PUSH		EBX
		PUSH		EDI

		MOV		    ESI,[EBP+SrcMaskBlndResizeSurf16]
		MOV		    EDI,_SrcSurf
		CopySurfDA  ; copy the source surface


; prepare col blending
		MOV			EAX,[EBP+ColMaskBlndResizeSurf16] ;
		MOV			EBX,EAX ;
		MOV			ECX,EAX ;
		MOV			EDX,EAX ;
		AND			EBX,[_QBlue16Mask] ; EBX = Bclr16 | Bclr16
		SHR			EAX,24
		AND			ECX,[_QGreen16Mask] ; ECX = Gclr16 | Gclr16
		AND			AL,BlendMask ; remove any ineeded bits
		AND			EDX,[_QRed16Mask] ; EDX = Rclr16 | Rclr16
		XOR			AL,BlendMask ; 31-blendsrc
		MOV			EDI,EAX
		XOR			AL,BlendMask ; 31-blendsrc
		INC			AL
		SHR			DX,5 ; right shift red 5bits
		IMUL		BX,AX
		IMUL		CX,AX
		IMUL		DX,AX
		MOVD		xmm3,EBX
		MOVD		xmm4,ECX
		MOVD		xmm5,EDX
		MOVD		xmm7,EDI
		PSHUFLW		xmm3,xmm3,0
		PSHUFLW		xmm4,xmm4,0
		PSHUFLW		xmm5,xmm5,0
		PSHUFLW		xmm7,xmm7,0
		PUNPCKLQDQ  xmm3,xmm3
		PUNPCKLQDQ  xmm4,xmm4
		PUNPCKLQDQ  xmm5,xmm5
		PUNPCKLQDQ  xmm7,xmm7

		MOV		    EAX,[EBP+MaskBlndResizeRevertHz]
		XOR         EBX,EBX ; store flags revert Hz and Vt
		MOV		    EDX,[EBP+MaskBlndResizeRevertVt]
		OR          EAX,EAX
		; compute horizontal pnt in EBP
		MOV         EBP,[_MaxY]
		SETNZ       BL ; BL = RevertHz ?
		OR          EDX,EDX
		MOV         EAX,[SMaxX]
		SETNZ       BH ; BH = RevertVt ?
		MOV         EDI,[_MinY]
		MOV         ESI,[SMinX]
		PUSH        EBX ; save FLAGS Revert
		MOV         ECX,[_MaxX]
		SUB         EBP,EDI ; = (_MaxY - MinY)
		MOV         EBX,[_MinX]
		INC         EBP ; = Delta_Y = (_MaxY - MinY) + 1
		SUB         EAX,ESI
		IMUL        EDI,[_NegScanLine]
		SUB         ECX,EBX
		ADD         EDI,[_vlfb]
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
		IMUL	    ESI,[SNegScanLine] ; - 2
        PUSH        EDX ; save acc PntX
		LEA		    ESI,[ESI+EBX*2]   ; - 4 + (XT1*2) as 16bpp
		ADD		    ESI,[Svlfb] ; - 5

		@InFastMaskTextBlndHLineDYZ16

        MOVD        ECX,mm5 ; restore hline counter
        PADDD       mm4,mm3 ; next source hline
        PADDD       mm6,[_NegScanLine] ; next hline
        DEC         ECX
        POP         EDX  ; restore acc PntX
        JNZ         .BcResize

.End:
        EMMS
		POP			EDI
		POP			EBX
		POP			ESI

    RETURN

; =======================================
; ====================== POLY16 ==========


POLY_FLAG_DBL_SIDED16		EQU	0x80000000
DEL_POLY_FLAG_DBL_SIDED16	EQU	0x7FFFFFFF

;****************************************************************************

ALIGN 32
_Poly16:
		ARG	PtrListPt16, 4, SSurf16, 4, TypePoly16, 4, ColPoly16, 4

			PUSH		ESI
			PUSH		EBX
			MOV		    ESI,[EBP+PtrListPt16]
			PUSH		EDI

			LODSD		; MOV EAX,[ESI];  ADD ESI,4
			MOV		    [NbPPoly],EAX
			MOV		    EDX,[ESI]
			MOV		    ECX,[ESI+8]
			MOV		    EBX,[ESI+4]
			MOVQ		xmm0,[EDX] ; = XP1, YP1
			MOVQ		xmm1,[EBX] ; = XP2, YP2
			MOVQ		xmm2,[ECX] ; = XP3, YP3
			MOVDQA		xmm3,xmm0 ; = XP1, YP1
			MOVDQA		xmm4,xmm1 ; = XP2, YP2
			MOVDQA		xmm5,xmm2 ; = XP3, YP3
			MOVQ		[XP1],xmm0 ; XP1, YP1

;(XP2-XP1)*(YP3-YP2)-(XP3-XP2)*(YP2-YP1)
; s'assure que les points suive le sens inverse de l'aiguille d'une montre
.verifSens:
			PSUBD		xmm1,xmm0 ; = (XP2-XP1) | (YP2 - YP1)
			PSUBD		xmm2,xmm4 ; = (XP3-XP2) | (YP3 - YP2)
			PEXTRD		EDI,xmm1,1 ; = (YP2-YP1)
			PEXTRD		EBX,xmm2,1 ; = (YP3-YP2)
			MOVD		ECX,xmm1 ; = (XP2-XP1)
			MOVD		EDX,xmm2 ; = (XP3-XP2)
			IMUL		ECX,EBX
			IMUL		EDI,EDX
			CMP		    ECX,EDI

			JL			.TstSiDblSide ; si <= 0 alors pas ok
			JZ			.SpecialCase
;****************
.DrawPoly:
		; Sauvegarde les parametre et libere EBP
			MOV			EAX,[EBP+TypePoly16]
			MOV			EBX,[EBP+ColPoly16]
			AND			EAX,DEL_POLY_FLAG_DBL_SIDED16
			MOV			ECX,[EBP+SSurf16]
			MOV			[PType],EAX
			MOV			[clr],EBX
			MOV			EDI,[NbPPoly]
			MOV			[PPtrListPt],ESI
			MOV			[SSSurf],ECX
;-new born determination--------------
			MOV			EBP,EDI
			MOVQ		xmm1,xmm3 ; init min = XP1 | YP1
			MOVQ		xmm2,xmm3 ; init max = XP1 | YP1
			PMINSD      xmm1,xmm4
			PMAXSD      xmm2,xmm4
			PMINSD      xmm1,xmm5
			PMAXSD      xmm2,xmm5
			DEC			EDI ; = [NbPPoly] - 1
			SUB			EBP, BYTE 3 ; EBP = [NbPPoly] - 3
			JZ			.NoBcMnMxXY
.PBoucMnMxXY:
			MOV			EAX,[ESI+EBP*4+8] ; = XN, YN
			MOVQ		xmm0,[EAX] ; = XN, YN
			DEC         EBP
			PMINSD      xmm1,xmm0
			PMAXSD      xmm2,xmm0
			JNZ			.PBoucMnMxXY
.NoBcMnMxXY:
			MOVD		EAX,xmm2 ; maxx
			MOVD		ECX,xmm1 ; minx
			PEXTRD  	EBX,xmm2,1 ; maxy
			PEXTRD		EDX,xmm1,1 ; miny
;-----------------------------------------

; poly clipper ? dans l'ecran ? hors de l'ecran ?
			;JMP			.PolyClip
			CMP			EAX,[_MaxX]
			JG			.PolyClip
			CMP			ECX,[_MinX]
			JL			.PolyClip
			CMP			EBX,[_MaxY]
			JG			.PolyClip
			CMP			EDX,[_MinY]
			JL			.PolyClip

; trace Poly non Clipper  **************************************************

			MOV			ECX,[_OrgY]	 ; calcule DebYPoly, FinYPoly
			MOV			EAX,[ESI+EDI*4]
			ADD			EDX,ECX
			ADD			EBX,ECX
			MOV			[DebYPoly],EDX
			MOVQ		xmm3,[EAX] ; XP2, YP2
			MOV			[FinYPoly],EBX
			MOVQ        xmm0,[XP1] ; = XP1 | YP1
			MOVQ    	[XP2],xmm3 ; save XP2, YP2
; calcule les bornes horizontal du poly
			MOV			EDX,EDI ; = NbPPoly - 1
			@InCalculerContour16
			MOV			EAX,[PType]
			JMP			[InFillPolyProc16+EAX*4]
			;JMP		.PasDrawPoly
.PolyClip:
; outside view ? now draw !
			CMP			EAX,[_MinX]
			JL			.PasDrawPoly
			CMP			EBX,[_MinY]
			JL			.PasDrawPoly
			CMP			ECX,[_MaxX]
			JG			.PasDrawPoly
			CMP			EDX,[_MaxY]
			JG			.PasDrawPoly

; Drop too big poly
		; drop too BIG poly
			SUB			ECX,EAX  ; deltaY
			SUB			EDX,EBX  ; deltaX
			CMP			ECX,MaxDeltaDim
			JGE			.PasDrawPoly
			CMP			EDX,MaxDeltaDim
			LEA			ECX,[ECX+EAX] ; restor MaxY
			JGE			.PasDrawPoly
			ADD			EDX,EBX ; restor MaxX

; trace Poly Clipper  ******************************************************
			MOV			EAX,[_MaxY]	; determine DebYPoly, FinYPoly
			MOV			ECX,[_MinY]
			CMP			EBX,EAX
			MOV			EBP,[_OrgY]	  ; Ajuste [DebYPoly],[FinYPoly]
			CMOVG		EBX,EAX
			CMP			EDX,ECX
			MOV			EAX,[ESI+EDI*4]
			CMOVL		EDX,ECX
			ADD			EBX,EBP
			ADD			EDX,EBP
			MOVQ    	xmm4,[EAX] ; read XP2 | YP2
			MOV			[DebYPoly],EDX
			MOV			[FinYPoly],EBX
			MOVQ		[XP2],xmm4 ; write XP2 | YP2
			MOV			EDX,EDI ; EDX compteur de point = NbPPoly-1
			@ClipCalculerContour ; use same as 8bpp as it compute xdeb and xfin for eax hzline

			CMP			DWORD [DebYPoly],BYTE (-1)
			JE			.PasDrawPoly
			MOV			EAX,[PType]
			JMP			[ClFillPolyProc16+EAX*4]
.PasDrawPoly:
			POP			EDI
			POP			EBX
			POP			ESI

		RETURN

.TstSiDblSide:
			TEST		BYTE [EBP+TypePoly16+3],POLY_FLAG_DBL_SIDED16 >> 24
			JZ			SHORT .PasDrawPoly
			; swap all points except P1 !
			MOV			ECX,[ESI]
			MOV			EDX,ReversedPtrListPt
			DEC			EAX
			MOV			[EDX],ECX
			LEA			EDI,[ESI+EAX*4]
			CMP			EAX,BYTE 2
			LEA			EBX,[EDX+4] ; P1 already copied
			MOV			ESI,EDX
			JA			.BcSwapPtsOver3
.BcSwapPts:
			MOV			ECX,[EDI]
			MOV			[EBX],ECX
			SUB			EDI,BYTE 4
			DEC			EAX
			LEA			EBX,[EBX+4]
			JNZ			SHORT .BcSwapPts
			JMP			.DrawPoly
.BcSwapPtsOver3:
			MOV			ECX,[EDI]
			MOV			[EBX],ECX
			SUB			EDI,BYTE 4
			DEC			EAX
			LEA			EBX,[EBX+4]
			JNZ			SHORT .BcSwapPtsOver3
			MOV			ECX,[EDX+4] ; new XP2 | YP2 Ptr
			MOV			EBX,[EDX+8] ; new XP3 | YP3 Ptr
			MOVQ		xmm4,[ECX] ; = XP2, YP2
			MOVQ		xmm5,[EBX] ; = XP3, YP3
			JMP			.DrawPoly

.SpecialCase:
			CMP			EAX,BYTE 3
			MOV			ECX,EAX
			JLE			.PasDrawPoly
; first loop fin any x or y not equal to P1
			MOV			EBX,[YP1]
			DEC			ECX
			MOV			EAX,[XP1]
			;MOV		ESI,[EBP+PtrListPt16]
			ADD			ESI,BYTE 4 ; jump over number of points + p1
.lpAnydiff:
			MOV			EDI,[ESI]  ;
			CMP			EAX,[EDI] ; XP1 != XP[N]
			JNE			.finddiffP3
			CMP			EBX,[EDI+4] ; YP1 != YP[N]
			JNE			.finddiffP3
			DEC			ECX
			LEA			ESI,[ESI+4]
			JNZ			.lpAnydiff
			JMP			.PasDrawPoly ; failed

.finddiffP3:
			MOV			EAX,[EDI]
			MOV			EBX,[EDI+4]
			MOV			[XP2],EAX
			MOV			[YP2],EBX
			DEC			ECX
			LEA			ESI,[ESI+4]
			JZ			.PasDrawPoly ; no more points ? :(
			SUB			EAX,[XP1] ; = XP2-XP1
			SUB			EBX,[YP1] ; = YP2-YP1

.lpPdiff:
			MOV			EDI,[ESI]
			MOV			EDX,[EDI] ; XP3
			MOV			EDI,[EDI+4] ; YP3
			SUB			EDX,[XP2] ; XP3-XP2
			SUB			EDI,[YP2] ; YP3-YP2
			IMUL		EDX,EBX ; = (YP2-YP1)*(XP3-XP2)
			IMUL		EDI,EAX ; = (XP2-XP1)*(YP3-YP2)
			SUB			EDI,EDX
			JNZ			.P3ok
			DEC			ECX
			LEA			ESI,[ESI+4]
			JNZ			.lpPdiff
			JMP			.PasDrawPoly ; failed
.P3ok:
			MOV			ESI,[EBP+PtrListPt16]
			LODSD
			JL			.TstSiDblSide
			JMP			.DrawPoly


SECTION	.bss   ALIGN=32
; Main DGSurf
; All graphic functions render on DGSurf pointed here
_CurSurf:
_vlfb					RESD    1
_rlfb					RESD    1
_ResH					RESD    1
_ResV					RESD    1
_MaxX					RESD    1
_MaxY					RESD    1
_MinX					RESD    1
_MinY					RESD    1;-----------------------
_Mask					RESD    1
_OrgY					RESD    1
_OrgX					RESD    1
_SizeSurf			    RESD    1
_ScanLine			    RESD    1
_OffVMem				RESD    1
_RMaxX				    RESD    1
_RMaxY				    RESD    1;-----------------------
_RMinX				    RESD    1
_RMinY				    RESD    1
_BitsPixel			    RESD    1
_NegScanLine		    RESD    1
_Resv2				    RESD    1
_Resv3				    RESD    1
_Resv4				    RESD    1
_Resv5				    RESD    1;-----------------------
; source DgSurf mainly used to point to texture, sprites ..
_SrcSurf:
Svlfb					RESD    1
Srlfb					RESD    1
SResH					RESD    1
SResV					RESD    1
SMaxX					RESD    1
SMaxY					RESD    1
SMinX					RESD    1
SMinY					RESD    1;-----------------------
SMask					RESD    1
SOrgY					RESD    1
SOrgX					RESD    1
SSizeSurf			    RESD    1
SScanLine			    RESD    1
SOffVMem				RESD    1
SRMaxX				    RESD    1
SRMaxY				    RESD    1;-----------------------
SRMinX				    RESD    1
SRMinY				    RESD    1
SBitsPixel			    RESD    1
SNegScanLine		    RESD    1
SResv2				    RESD    1
SResv3				    RESD    1
SResv4				    RESD    1
SResv5				    RESD    1;-----------------------
XP1		        	    RESD	1
YP1		        	    RESD		1
XP2		        	    RESD		1
YP2		        	    RESD		1
XP3		        	    RESD		1
YP3		        	    RESD		1
Plus		    		RESD		1
Temp0	        	    RESD		1;-----------------------
XT1		        	    RESD	1
YT1		        	    RESD	1
XT2		        	    RESD	1
YT2		        	    RESD	1
Col1	        		RESD	1
Col2	        		RESD	1
revCol	        	    RESD	1
_CurViewVSurf		    RESD	1;-----------------------
PMaxX		    		RESD	1
PMaxY		    		RESD	1
PMinX		    		RESD	1
PMinY		    		RESD	1
NbPPoly		    	    RESD	1
DebYPoly	    		RESD	1
FinYPoly	    		RESD	1
PType		    		RESD	1;-----------------------
PType2		    	    RESD	1
PPtrListPt	    	    RESD	1
PntPlusX	    		RESD	1
PntPlusY	    		RESD	1
PlusX		    		RESD	1
PlusY				    RESD	1
SSSurf		    	    RESD	1
Plus2		    	    RESD	1;-----------------------
; poly16 array
_TPolyAdDeb     	    RESD    MaxResV
_TPolyAdFin     	    RESD    MaxResV
_TexXDeb        	    RESD    MaxResV
_TexXFin        	    RESD    MaxResV
_TexYDeb        	    RESD    MaxResV
_TexYFin        	    RESD    MaxResV
_PColDeb        	    RESD    MaxResV
_PColFin        	    RESD    MaxResV

_CurFONT:
_FntPtr				    RESD    1
_FntHaut	    		RESB	1
_FntDistLgn	    	    RESB	1
_FntLowPos	    	    RESB	1
_FntHighPos	    	    RESB	1
_FntSens	    		RESB	1
_FntTab		    	    RESB	3 ; 2 DB reserved
_FntX		    		RESD	1
_FntY		    		RESD	1
_FntCol		    	    RESD	1
FntResv		    	    RESD	2 ;---------------------
ChHaut		    	    RESD	1
ChLarg		    	    RESD	1
ChPlus		    	    RESD	1
ChPlusX		    	    RESD	1
ChPlusLgn	    	    RESD	1
ChAvPlus	    		RESD	1
ChApPlus	    		RESD	1
ChAvDecal	    	    RESB	1
ChNbBitDat	    	    RESB	1
ChResvW		    	    RESW	1;-----------------------
QMulSrcBlend		    RESD	4
QMulDstBlend		    RESD	4;--------------
WBGR16Blend     	    RESD	4
clr                     RESD    1
Temp		    		RESD	1
Temp2		    		RESD	1
PlusCol		    	    RESD	1 ;-----------
PtrTbDegCol	    	    RESD	1
_PtrTbColConv		    RESD	1
Temp3           	    RESD    2
PutSurfMaxX	    	    RESD	1
PutSurfMaxY	    	    RESD	1
PutSurfMinX	    	    RESD	1
PutSurfMinY	    	    RESD	1 ;------------------------
QBlue16Blend		    RESD	4
QGreen16Blend		    RESD	4
QRed16Blend			    RESD	4
DQ16Mask	    		RESD	4 ;------------------------

; the main Surf 16bpp that DUGL will render to
;   user mostly has to set this as CurSurf unless other intermediate DgSurf
_RendSurf:			RESD		24
_RendFrontSurf		RESD		24

ReversedPtrListPt	RESD		MaxDblSidePolyPts

SECTION	.data   ALIGN=32

PntInitCPTDbrd	DD	0,((1<<Prec)-1)
MaskB_RGB16	    DD	0x1f	 ; blue bits 0->4
MaskG_RGB16	    DD	0x3f<<5  ; green bits 5->10
MaskR_RGB16	    DD	0x1f<<11 ; red bits 11->15
RGB16_PntNeg	DD	((1<<Prec)-1) ;----------
Mask2B_RGB16	DD	0x1f,0x1f ; blue bits 0->4
Mask2G_RGB16	DD	0x3f<<5,0x3f<<5  ; green bits 5->10 ;----------
Mask2R_RGB16	DD	0x1f<<11,0x1f<<11 ; red bits 11->15
RGBDebMask_GGG	DD	0,0,0,0
RGBDebMask_IGG	DD	((1<<Prec)-1),0,0,0
RGBDebMask_GIG	DD	0,((1<<(Prec+5))-1),0,0
RGBDebMask_IIG	DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBDebMask_GGI	DD	0,0,((1<<(Prec+11))-1),0
RGBDebMask_IGI	DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBDebMask_GII	DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBDebMask_III	DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0

RGBFinMask_GGG	DD	((1<<Prec)-1),((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_IGG	DD	0,((1<<(Prec+5))-1),((1<<(Prec+11))-1),0
RGBFinMask_GIG	DD	((1<<Prec)-1),0,((1<<(Prec+11))-1),0
RGBFinMask_IIG	DD	0,0,((1<<(Prec+11))-1),0
RGBFinMask_GGI	DD	((1<<Prec)-1),((1<<(Prec+5))-1),0,0
RGBFinMask_IGI	DD	0,((1<<(Prec+5))-1),0,0
RGBFinMask_GII	DD	((1<<Prec)-1),0,0,0
RGBFinMask_III	DD	0,0,0,0

; BLENDING 16BPP ----------
_QBlue16Mask	DW	CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
Q2Blue16Mask	DW	CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16,CMaskB_RGB16
_QGreen16Mask	DW	CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
Q2Green16Mask	DW	CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16,CMaskG_RGB16
_QRed16Mask		DW	CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16
Q2Red16Mask		DW	CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16,CMaskR_RGB16
WBGR16Mask      DW	CMaskB_RGB16,CMaskG_RGB16,CMaskR_RGB16,CMaskR_RGB16
W2BGR16Mask     DW	CMaskB_RGB16,CMaskG_RGB16,CMaskR_RGB16,CMaskR_RGB16

;* 16bpp poly proc****
InFillPolyProc16:
		DD	InFillSOLID16, InFillTEXT16, InFillMASK_TEXT16, dummyFill16, dummyFill16 ; InFillFLAT_DEG,InFillDEG
		DD	dummyFill16, dummyFill16 ;InFillFLAT_DEG_TEXT,InFillMASK_FLAT_DEG_TEXT
		DD	dummyFill16, dummyFill16, dummyFill16;InFillDEG_TEXT,InFillMASK_DEG_TEXT,InFillEFF_FDEG
		DD	InFillTEXT_TRANS16,InFillMASK_TEXT_TRANS16
		DD	InFillRGB16,InFillSOLID_BLND16,InFillTEXT_BLND16,InFillMASK_TEXT_BLND16

ClFillPolyProc16:
		DD	ClipFillSOLID16,ClipFillTEXT16,ClipFillMASK_TEXT16, 0, 0 ;ClipFillFLAT_DEG,ClipFillDEG
		DD	dummyFill16, dummyFill16 ;ClipFillFLAT_DEG_TEXT,ClipFillMASK_FLAT_DEG_TEXT
		DD	dummyFill16, dummyFill16, dummyFill16 ;ClipFillDEG_TEXT,ClipFillMASK_DEG_TEXT,ClipFillEFF_FDEG
		DD	ClipFillTEXT_TRANS16, ClipFillMASK_TEXT_TRANS16
		DD	ClipFillRGB16,ClipFillSOLID_BLND16,ClipFillTEXT_BLND16,ClipFillMASK_TEXT_BLND16

