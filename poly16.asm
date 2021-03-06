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


;****************************************************************************
; MACRO UTILISER DANS POLY
;****************************************************************************
; calcule adresse physique du contour

; IN: XP1,YP1,XP2,YP2,EBX: Index _TPolyAdFin,EAX: XP1, EDI XP2,ECX: YP1,ESI; YP2:EBP[_ScanLine]
; condition XP1<XP2 && YP1<YP2
%macro 	@InContourGch16	0
		CMP		    EAX,EDI
		MOV			EBX,ECX
        SETG        DL
		SUB 		EAX,EDI ; EAX = [XP1]-[XP2]
		SUB			ECX,EBP  ; [YP1]-[YP2]
		MOV			EDI,EBX	; [YP1]
		NEG         EAX ; EAX = [XP2]-[XP1]
		NEG         ECX ; = [YP2]-[YP1] counter in ECX
		MOVD        xmm4,[PntInitCPTDbrd+EDX*4] ; count Dbdr In xmm4

		IMUL		EDI,ESI ; YP1*_ScanLine
		SHL			EAX,Prec
		CDQ
		ADD			EDI,[_vlfb]
		IDIV		ECX
		MOVD		EBP,xmm0 ; [XP1]
		ADD			EBX,[_OrgY]
		LEA			EDI,[EDI+EBP*2] ; 2*XP1 as 16bpp
		TEST		CL,1
		MOVD		EDX,xmm4 ; Dbrd Counter in EDX
		LEA			EBP,[_TPolyAdDeb+EBX*4]
%endmacro
; IN : XP1, YP1, XP2, YP2, EBX: Index dans _TPolyAdFin,	EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2

%macro 	@InContourDrt16	0
		CMP		    EAX,EDI
		MOV			EBX,EBP  ; [YP2]
        SETG        DL
		SUB 		EAX,EDI ; EAX = [XP1]-[XP2]
		SUB			ECX,EBP  ; [YP1]-[YP2]
		MOVD        xmm4,[PntInitCPTDbrd+EDX*4] ; count Dbdr In xmm4
		XCHG		EDI,EBP  ; swap [XP2] <=> [YP2]
		SHL			EAX,Prec
		IMUL		EDI,ESI
		ADD			EBX,[_OrgY]
		ADD			EDI,[_vlfb]
		CDQ
		IDIV   		ECX
		LEA			EDI,[EDI+EBP*2] ; +=2*XP2 as 16bpp
		MOVD		EDX,xmm4
		TEST		CL,1
		LEA			EBP,[_TPolyAdFin+EBX*4]
%endmacro

;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************
;calcule du contour du polygone lorsqu'il est totalement dans l'ecran
%macro	@InCalculerContour16	0
		MOVD		xmm1,[_NegScanLine]
;ALIGN 4
%%InBcCalCont:
        MOVD		xmm2,EDX     ; save EDX counter
        PEXTRD	    ECX,xmm0,1 ;  = [YP1]
        PEXTRD	    EBP,xmm3,1 ;  = [YP2]
		MOVD		ESI,xmm1
		XOR         EDX,EDX
		CMP		    ECX,EBP  ; YP2
		JE			%%DYZero
		MOVD	    EAX,xmm0 ; = [XP1]
		MOVD        EDI,xmm3 ; = [XP2]
		JG			SHORT %%ContDrt; si YP1<YP2 alors drt sinon gch
		@InContourGch16		; YP1<YP2  &&  (XP1<XP2 || XP1>XP2)
		JNZ			SHORT %%PasClc1Pt
		JMP		    SHORT %%DoOdd
%%ContDrt:
		@InContourDrt16		; YP1>YP2  &&  (XP1<XP2 || XP1>XP2)
		JNZ			SHORT %%PasClc1Pt
%%DoOdd:
		MOV			[EBP],EDI
		ADD			EDX,EAX
		INC			EBX
		ADD			EBP,BYTE 4
		ADD			EDI,ESI
%%PasClc1Pt:
		MOVD		xmm4,EDX  ; Cpt Dbrd
		MOVD		xmm3,EDI  ; Addr+XP1
		ADD			EDX,EAX  ; += Pnt
		ADD			EDI,ESI
		ADD			EAX,EAX ; - *2
		ADD			ESI,ESI
		INC         ECX
		PINSRD      xmm4,EDX,1 ; Cpt Dbrd + Pnt
		PINSRD      xmm3,EDI,1 ; Addr+XP1
		MOVD		xmm0,EAX ; - mm0 = PntPlusX * 2
		MOVD		xmm6,ESI
		SHR			ECX,1
		PUNPCKLDQ	xmm0,xmm0 ; - PntPlusX * 2
		PUNPCKLDQ	xmm6,xmm6 ; (ResH*2) * 2
;ALIGN 4
%%BcClcCtr:
		MOVQ		xmm5,xmm4  ; = cptDbrd
		MOVQ		xmm7,xmm3  ; = Addr addr
		PSRAD		xmm5,Prec ; shift r Dbrd
		PADDD		xmm3,xmm6  ; -= (ResH*2)
		PADDD		xmm5,xmm5 ; *2 as we are in 16bpp
		PADDD		xmm4,xmm0  ; += PntPlus * 2
		PADDD		xmm7,xmm5  ; + = Addr+XP1

		MOVQ		[EBP],xmm7
		DEC			ECX
		LEA			EBP,[EBP+8]
		JNZ			SHORT %%BcClcCtr

%%DYZero:
		MOVD		EDX,xmm2     ; restore EDX counter
		DEC		    EDX
		JS			NEAR %%FinCalcContr ; EDX < 0
		MOV		    ESI,[PPtrListPt]     ; ESI = PtrListPt
		MOV		    EAX,[ESI+EDX*4]	; EAX=PtrPt[EDX]
		MOVQ    	xmm0,[XP2] ; old XP2 | YP2 will be new XP1 | YP1
		;MOVQ    	[XP1],xmm0 ; put XP2 | YP2 in XP1 | YP1
		MOVQ    	xmm3,[EAX] ; read new XP2 | YP2
		MOVQ    	[XP2],xmm3 ; save XP2 | YP2

		JMP		%%InBcCalCont
%%FinCalcContr:
%endmacro


;*************************************************************
; compute RGB16 Start and end contour in _PColDEb and _PColFin
;*************************************************************

%macro	@InCalcRGB_Cnt16	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EBP,[EBX+20] ; col_RGB16(1)
		MOV		ECX,[EBX+4]  ; YP1
		;MOV		[Col1],EAX

		MOV		EDI,[ESI+EDX*4]
		MOV		[YP1],ECX
		MOV		EAX,[EDI+20] ; col_RGB16(n-1)
		MOV		ECX,[EDI+4] ; YP(n-1)
		MOV		[YP2],ECX
		MOV		[Col2],EAX

%%BcClColCnt:	MOV		ECX,[YP2]
		PUSH		ESI
		SUB		ECX,[YP1]
		PUSH		EDX
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOVD		xmm2,EAX
		MOVD		xmm4,EBP ; *
		MOVD		xmm3,EAX
		MOVD		xmm5,EBP ; *
		PUNPCKLDQ	xmm2,xmm2
		PUNPCKLDQ	xmm4,xmm4

		PAND		xmm2,[MaskB_RGB16] ; mm2 : Blue | green
		PAND		xmm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		xmm3,[MaskR_RGB16] ; mm3 : red | 0
		PAND		xmm5,[MaskR_RGB16] ; * mm5 : red | 0

		PSUBD		xmm2,xmm4 ; mm2 : DeltaBlue | DeltaGreen
		PSUBD		xmm3,xmm5 ; mm3 : DeltaRed
		PSLLD		xmm2,Prec ; mm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
		MOVD		EAX,xmm2
		PSLLD		xmm3,Prec ; mm3 : DeltaRed<<Prec

		XOR		EBX,EBX
		CDQ
		XOR		EDI,EDI
		IDIV		ECX
		PSRLQ		xmm2,32
		OR		EAX,EAX
		MOVD		xmm6,EAX ; mm6 = PntBlue | -
		SETL		BL

		MOVD		EAX,xmm3
		OR		EDI,EBX
		CDQ
		IDIV		ECX
		OR		EAX,EAX
		MOVD		xmm7,EAX ; mm7 = PntRed | -
		SETL		BL

		MOVD		EAX,xmm2
		LEA		EDI,[EDI+EBX*4]
		CDQ
		IDIV		ECX
		PUNPCKLDQ	xmm7,xmm7 ; mm7 = PntR | PntR
		OR		EAX,EAX
		MOVD		xmm3,EAX ; mm3 = PntGReen | -
		SETL		BL
		PUNPCKLDQ	xmm6,xmm6 ; mm6 = PntB | PntB
		LEA		EDI,[EDI+EBX*2]
		PUNPCKLDQ	xmm3,xmm3 ; mm3 = PntGreen | PntGReen
;---------------
		MOV		ESI,[YP1]
		SHL		EDI,4 ; EDI * 16
		INC		ECX	       ; -
		CMP		ESI,[YP2]
		JG		%%CntColFin
		;--- ajuste Cpt Dbrd X  pour SAR
		;MOV		EBP,[Col1] ; -

		PSLLD		xmm4,Prec ; mm4 : Col1_B<<Prec | Col1_G<<Prec
		PSLLD		xmm5,Prec ; mm5 : Col1_R<<Prec | -
		PADDD		xmm4,[RGBDebMask_GGG+EDI]   ; mm4 = cptDbrd B | cptDbrd G ;; += Col1B | Col1G  Shifted
		PADDD		xmm5,[RGBDebMask_GGG+EDI+8] ; mm5 = cptDbrd R | - ;; += Col1R | -  Shifted
		MOVQ		xmm2,xmm4 ; mm2 = cptDbrd B | cptDbrd G
		MOVQ		xmm1,xmm4 ; = Cpt dbrd B| -
		MOV		    EBX,[YP1]
		PUNPCKHDQ	xmm2,xmm2 ; mm4 = cptDbrd G | cptDbrd G

		MOVQ		xmm0,xmm5 ; = Cpt dbrd R| -
		PADDD		xmm1,xmm6 ; += Pnt B | B
		PADDD		xmm0,xmm7 ; += Pnt R | R
		PUNPCKLDQ	xmm4,xmm1 ; mm4 = cpt dbrd B | (cpt dbrd B + Pnt B)
		PUNPCKLDQ	xmm5,xmm0 ; mm5 = cpt dbrd R | (cpt dbrd R + Pnt R)
		MOVQ		xmm1,xmm2 ; = cpt Dbrd G|G
		ADD		EBX,[_OrgY]
		TEST		CL,1
		PADDD		xmm1,xmm3
		PUNPCKLDQ	xmm2,xmm1 ; mm2 = cpt dbrd G | (cpt dbrd G + Pnt G)

;---------------
		JZ		%%NoFDebCol
		MOVQ		xmm0,xmm2 ; mm0 = cptDbrd G|G
		MOVQ		xmm1,xmm5 ; mm1 = cptDbrd R,R
		PSRLD		xmm0,Prec
		PSRLD		xmm1,Prec
		PAND		xmm0,[Mask2G_RGB16]
		PAND		xmm1,[Mask2R_RGB16]
		POR		    xmm1,xmm0
		PADDD		xmm5,xmm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		xmm0,xmm4 ; mm0 = cptDbrd B,B
		PADDD		xmm2,xmm3 ; = cptDbrd G|G + Pnt G|G
		PADDD		xmm4,xmm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		xmm0,Prec
		POR		    xmm1,xmm0
		MOVD		[_PColDeb+EBX*4],xmm1
		INC		EBX
%%NoFDebCol:
;---------------
		PADDD		xmm6,xmm6
		PADDD		xmm7,xmm7
		SHR		    ECX,1
		PADDD		xmm3,xmm3
%%BcCntRGBDeb:
		MOVQ		xmm0,xmm2 ; mm0 = cptDbrd G|G
		MOVQ		xmm1,xmm5 ; mm1 = cptDbrd R,R
		PSRLD		xmm0,Prec
		PSRLD		xmm1,Prec
		PAND		xmm0,[Mask2G_RGB16]
		PAND		xmm1,[Mask2R_RGB16]
		POR		    xmm1,xmm0
		PADDD		xmm5,xmm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		xmm0,xmm4 ; mm0 = cptDbrd B,B
		PADDD		xmm2,xmm3 ; = cptDbrd G|G + Pnt G|G
		PADDD		xmm4,xmm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		xmm0,Prec
		POR		    xmm1,xmm0

		MOVQ		[_PColDeb+EBX*4],xmm1
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		NEAR %%BcCntRGBDeb
		JMP		%%FinCntColFin

%%CntColFin:
		MOV		EAX,[Col2]
		MOVD		xmm4,EAX ; *
		MOVD		xmm5,EAX ; *
		PUNPCKLDQ	xmm4,xmm4
		PAND		xmm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		xmm5,[MaskR_RGB16] ; * mm5 : red | 0
		PSLLD		xmm4,Prec ; mm4 : Col2_B<<Prec | Col2_G<<Prec
		PSLLD		xmm5,Prec ; mm5 : Col2_R<<Prec | -

		PADDD		xmm4,[RGBFinMask_GGG+EDI] ; mm4 : CptDbrdBlue | CptDbrdGreen
		PADDD		xmm5,[RGBFinMask_GGG+EDI+8] ; mm5 : CptDbrdRed

		MOVQ		xmm2,xmm4 ; mm2 = cptDbrd B | cptDbrd G
		MOVQ		xmm1,xmm4 ; = Cpt dbrd B| -

		MOVQ		xmm0,xmm5 ; = Cpt dbrd R| -
		PUNPCKHDQ	xmm2,xmm2 ; mm4 = cptDbrd G | cptDbrd G
		PSUBD		xmm0,xmm7 ; += Pnt R | R
		PSUBD		xmm1,xmm6 ; += Pnt B | B
		MOV		EBX,[YP2]
		PUNPCKLDQ	xmm4,xmm1 ; mm4 = cpt dbrd B | (cpt dbrd B - Pnt B)
		PUNPCKLDQ	xmm5,xmm0 ; mm5 = cpt dbrd R | (cpt dbrd R - Pnt R)
		MOVQ		xmm1,xmm2 ; = cpt Dbrd G|G
		ADD		EBX,[_OrgY]
		TEST		CL,1
		PSUBD		xmm1,xmm3
		PUNPCKLDQ	xmm2,xmm1 ; mm2 = cpt dbrd G | (cpt dbrd G - Pnt G)

		JZ		%%NoFFinCol
		MOVQ		xmm0,xmm2 ; mm0 = cptDbrd G|G
		MOVQ		xmm1,xmm5 ; mm1 = cptDbrd R,R
		PSRLD		xmm0,Prec
		PSRLD		xmm1,Prec
		PAND		xmm0,[Mask2G_RGB16]
		PAND		xmm1,[Mask2R_RGB16]
		POR		    xmm1,xmm0
		PSUBD		xmm5,xmm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		xmm0,xmm4 ; mm0 = cptDbrd B,B
		PSUBD		xmm2,xmm3 ; = cptDbrd G|G + Pnt G|G
		PSUBD		xmm4,xmm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		xmm0,Prec
		POR		    xmm1,xmm0
		MOVD		[_PColFin+EBX*4],xmm1
		INC		EBX
%%NoFFinCol:
;---------------
		PADDD		xmm6,xmm6
		PADDD		xmm7,xmm7
		SHR		    ECX,1
		PADDD		xmm3,xmm3

%%BcCntRGBFin:
		MOVQ		xmm0,xmm2 ; mm0 = cptDbrd G|G
		MOVQ		xmm1,xmm5 ; mm1 = cptDbrd R,R
		PSRLD		xmm0,Prec
		PSRLD		xmm1,Prec
		PAND		xmm0,[Mask2G_RGB16]
		PAND		xmm1,[Mask2R_RGB16]
		POR		    xmm1,xmm0
		PSUBD		xmm5,xmm7 ; = cptDbrd R|R + Pnt R|R
		MOVQ		xmm0,xmm4 ; mm0 = cptDbrd B,B
		PSUBD		xmm2,xmm3 ; = cptDbrd G|G + Pnt G|G
		PSUBD		xmm4,xmm6 ; = cptDbrd B|B + Pnt B|B
		PSRLD		xmm0,Prec
		POR		    xmm1,xmm0
		MOVQ		[_PColFin+EBX*4],xmm1
		DEC		ECX
		LEA		EBX,[EBX+2]
		JNZ		%%BcCntRGBFin

%%FinCntColFin:
%%PasClCrLn:	POP		EDX
		POP		ESI
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		EAX,[YP2]
		MOV		EBP,[Col2] ; EBP = Col1
		MOV		[YP1],EAX
		MOV		ECX,[EBX+4]   ; YP
		MOV		EAX,[EBX+20]  ; EAX = Col2
		;MOV		[Col1],ECX
		MOV		[YP2],ECX
		MOV		[Col2],EAX

		JMP		%%BcClColCnt
%%FinClColCnt:

%endmacro

%macro	@ClipCalcRGB_Cnt16	0
		MOV		ESI,[PPtrListPt]
		MOV		EDX,[NbPPoly]
		MOV		EBX,[ESI]
		DEC		EDX
		MOV		EAX,[EBX+20] ; col_RGB16(1)
		MOV		ECX,[EBX+4]  ; YP1
		MOV		[YP1],ECX
		MOV		[Col1],EAX

		MOV		EBX,[ESI+EDX*4]
		MOV		EAX,[EBX+20] ; col_RGB16(n-1)
		MOV		ECX,[EBX+4] ; YP(n-1)
		MOV		[YP2],ECX
		MOV		[Col2],EAX

%%BcClColCnt:	PUSH		ESI
		PUSH		EDX

		MOV		ECX,[YP2]
		MOV		EBX,[YP1]
		SUB		ECX,EBX
		JZ		NEAR %%PasClCrLn
		JNS		%%PosDYP
		NEG		ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOVD		xmm3,[Col2]
		MOVD		xmm5,[Col1]
		PXOR		xmm2,xmm2 ; = 0 | 0
		PUNPCKLDQ	xmm3,xmm3
		PXOR		xmm4,xmm4 ; = 0 | 0
		PUNPCKLDQ	xmm5,xmm5
		POR		    xmm2,xmm3
		POR		    xmm4,xmm5

		PAND		xmm2,[MaskB_RGB16] ; mm2 : Blue | green
		PAND		xmm4,[MaskB_RGB16] ; * mm4 : Blue | green
		PAND		xmm3,[MaskR_RGB16] ; mm3 : red | 0
		PAND		xmm5,[MaskR_RGB16] ; * mm5 : red | 0

		PSUBD		xmm2,xmm4 ; mm2 : DeltaBlue | DeltaGreen
		PSUBD		xmm3,xmm5 ; mm3 : DeltaRed
		PSLLD		xmm4,Prec ; mm4 : Col1_B<<Prec | Col1_G<<Prec
		PSLLD		xmm5,Prec ; mm5 : Col1_R<<Prec | -
		PSLLD		xmm2,Prec ; mm2 : DeltaBlue<<Prec | DeltaGreed<<Prec
		PSLLD		xmm3,Prec ; mm3 : DeltaRed<<Prec

		XOR		EBX,EBX
		XOR		EDI,EDI
		MOVD		EAX,xmm2
		CDQ
		IDIV		ECX
		PSRLQ		xmm2,32
		MOVD		xmm6,EAX ; mm6 = PntBlue | -
		OR		    EAX,EAX
		SETL		BL
		OR		    EDI,EBX

		MOVD		EAX,xmm3
		CDQ
		IDIV		ECX
		MOVD		xmm7,EAX ; mm7 = PntRed | -
		OR		    EAX,EAX
		SETL		BL
		LEA		    EDI,[EDI+EBX*4]

		MOVD		EAX,xmm2
		CDQ
		IDIV		ECX
		MOVD		xmm3,EAX ; mm3 = PntGReen | -
		MOV		    EBP,EAX ; EBP = PntGReen
		PSLLQ		xmm3,32
		POR		    xmm6,xmm3 ; mm6 = PntBlue | PntGReen
		OR		    EAX,EAX
		SETL		BL
		LEA		    EDI,[EDI+EBX*2] ; EDI : idx initial CptDbrd

		MOV		    ESI,[YP1]
		MOV		    EAX,[YP2]
		SHL		    EDI,4 ; EDI * 16
		;INC		ECX	       ; -
		CMP		    ESI,EAX
		JG		    %%CntColFin

		;--- ajuste Cpt Dbrd X  pour SAR
		;MOV		EBP,[Col1] ; -

		MOVQ		xmm2,[RGBDebMask_GGG+EDI] ; mm2 : CptDbrdBlue | CptDbrdGreen
		MOVD		xmm3,[RGBDebMask_GGG+EDI+8] ; mm3 : CptDbrdRed

;**** Deb Aj Deb **********************
		CMP		EAX,[_MinY]	; YP2 < _MinY ?
		JL		%%PasClCrLn
		CMP		ESI,[_MaxY]	; YP1 > _MaxY ?
		JG		%%PasClCrLn
		CMP		ESI,[_MinY]	; YP1 >= _MinY ?
		JGE		%%PasAjYP1
		MOV		EBX,[_MinY]	; EBX = _MinY
		MOVD		EDI,xmm6		; EDI = Pnt Blue
		SUB		EBX,ESI		; EBX = _MinY - YP1
		MOVD		EDX,xmm7		; EDX = Pnt Red
		IMUL		EBP,EBX ; PntGreen*DeltaY
		IMUL		EDI,EBX ; PntBlue*DeltaY
		MOVD		xmm1,EBP
		MOVD		xmm0,EDI
		;PSLLQ		mm0,32
		IMUL		EDX,EBX ; PntREd*DeltaY
		;POR		mm0,mm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		PUNPCKLDQ	xmm0,xmm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		MOV		ESI,[_MinY]
		MOVD		xmm1,EDX ; mm1 : +CptDbrdRed | -
		PADDD		xmm2,xmm0 ; mm2+= CptDbrd B | G
		PADDD		xmm3,xmm1 ; mm3+= CptDbrd R | -
%%PasAjYP1:	CMP		EAX,[_MaxY]  ; YP2 <= _MaxY
		JLE		%%PasAjYP2
		MOV		EAX,[_MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
		MOV		ECX,EAX ; = Clip YP2
		MOV		EBX,ESI ; = clipped YP1
		SUB		ECX,ESI ; - Clip YP1
		ADD		EBX,[_OrgY]
		INC		ECX
		; mm2, mm3 : cptDbrd B,G,R
		; mm6, mm7 : pnt     B,G,R
		; mm4, mm5 : pnt     Col1B,Col1G,Col1R
		; Free EAX,EDX, ESI, EDI, EBP
		MOVD		ESI,xmm4 ; Col1B shifted
		MOVD		EBP,xmm5 ; Col1R shifted
		PSRLQ		xmm4,32
		MOVD		EDI,xmm4 ; Col1G shifted
%%BcCntRGBDeb:
		MOVQ		xmm5,xmm3 ; = cptDbrd R
		MOVQ		xmm4,xmm2 ; = cptDbrd B,G
		MOVD		EDX,xmm3 ; * cptDbrd R
		MOVD		EAX,xmm2 ; = cptDbrd B
		ADD		    EDX,EBP ; * += ColR Sifted
		ADD		    EAX,ESI ; += ColB Sifted
		SHR		    EDX,Prec+11 ; *
		SHR		    EAX,Prec
		SHL		    EDX,11 ; *
		PSRLQ		xmm4,32 ; **
		OR		    EAX,EDX ; * affect R to EAX

		PADDD		xmm2,xmm6 ; = cptDbrd B,G - Pnt B,G
		MOVD		EDX,xmm4 ; cptDbrd G
		ADD		    EDX,EDI ; += ColG Sifted
		SHR		    EDX,Prec+5
		SHL		    EDX,5
		OR		    EAX,EDX ; affect G to EAX

		PADDD		xmm3,xmm7 ; = cptDbrd R - Pnt R

		MOV		[_PColDeb+EBX*4],EAX
		DEC		ECX
		LEA		EBX,[EBX+1]
		JNZ		NEAR %%BcCntRGBDeb
		JMP		%%FinCntColFin

%%CntColFin:

		MOVQ		xmm2,[RGBFinMask_GGG+EDI] ; mm2 : CptDbrdBlue | CptDbrdGreen
		MOVD		xmm3,[RGBFinMask_GGG+EDI+8] ; mm3 : CptDbrdRed
;**** Deb Aj Fin **********************
		CMP		    ESI,[_MinY]	; YP1 < _MinY ?
		JL		    %%PasClCrLn
		CMP		    EAX,[_MaxY]	; YP2 > _MaxY ?
		JG		    %%PasClCrLn
		CMP		    EAX,[_MinY]	; YP2 >= _MinY ?
		JGE		    %%PasAjYP1Fin
		MOV		    EBX,[_MinY]	; EBX = _MinY
		MOVD		EDI,xmm6		; EDI = Pnt Blue
		SUB		    EBX,EAX		; EBX = _MinY - YP1
		MOVD		EDX,xmm7		; EDX = Pnt Red
		IMUL		EBP,EBX ; PntGreen*DeltaY
		IMUL		EDI,EBX ; PntBlue*DeltaY
		MOVD		xmm1,EBP
		MOVD		xmm0,EDI
		IMUL		EDX,EBX ; PntREd*DeltaY
		PUNPCKLDQ	xmm0,xmm1 ; mm0 : +CptDbrdBlue | +CptDbrdGreen
		MOV		    EAX,[_MinY]
		MOVD		xmm1,EDX ; mm1 : +CptDbrdRed | -
		PSUBD		xmm2,xmm0 ; mm2-= CptDbrd B | G
		PSUBD		xmm3,xmm1 ; mm3-= CptDbrd R | -
%%PasAjYP1Fin:	CMP		ESI,[_MaxY]  ; YP1 <= _MaxY
		JLE		%%PasAjYP2Fin
		MOV		ESI,[_MaxY]
%%PasAjYP2Fin:
;**** Fin Aj Fin **********************

		MOV		ECX,ESI ; clipped YP1
		MOV		EBX,EAX ; clipped YP2
		SUB		ECX,EAX ; - clipped YP2
		ADD		EBX,[_OrgY]
		INC		ECX ; ++

		MOV		ESI,[Col2]
		MOV		EDI,[Col2]
		MOV		EBP,[Col2]
		AND		ESI,CMaskB_RGB16 ;  Blue
		AND		EDI,CMaskG_RGB16 ;  green
		AND		EBP,CMaskR_RGB16 ;  red
		SHL		ESI,Prec ; Col2B shifted
		SHL		EDI,Prec ; Col2G shifted
		SHL		EBP,Prec ; Col2R shifted

%%BcCntRGBFin:
		MOVQ	xmm5,xmm3 ; = cptDbrd R
		MOVQ	xmm4,xmm2 ; = cptDbrd B,G
		MOVD	EDX,xmm3 ; * cptDbrd R
		MOVD	EAX,xmm2 ; = cptDbrd B
		ADD		EDX,EBP ; * += ColR Sifted
		ADD		EAX,ESI ; += ColB Sifted
		SHR		EDX,Prec+11 ; *
		SHR		EAX,Prec
		SHL		EDX,11 ; *
		PSRLQ	xmm4,32 ; **
		OR		EAX,EDX ; * affect R to EAX

		PSUBD	xmm2,xmm6 ; = cptDbrd B,G - Pnt B,G
		MOVD	EDX,xmm4 ; cptDbrd G
		ADD		EDX,EDI ; += ColG Sifted
		SHR		EDX,Prec+5
		SHL		EDX,5
		OR		EAX,EDX ; affect G to EAX

		PSUBD	xmm3,xmm7 ; = cptDbrd R - Pnt R

		MOV		[_PColFin+EBX*4],EAX
		DEC		ECX
		LEA		EBX,[EBX+1]
		JNZ		%%BcCntRGBFin

%%FinCntColFin:
%%PasClCrLn:
		POP		EDX
		POP		ESI
		DEC		EDX
		JS		%%FinClColCnt

		MOV		EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV		ECX,[Col2]
		MOV		EAX,[YP2]
		MOV		[Col1],ECX
		MOV		[YP1],EAX
		MOV		ECX,[EBX+20]  ; Col
		MOV		EAX,[EBX+4]   ; YP
		MOV		[YP2],EAX
		MOV		[Col2],ECX

		JMP		%%BcClColCnt
%%FinClColCnt:

%endmacro


