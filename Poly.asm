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


;**CLIP*****************************************************
;GLOB DebYPoly : MinY_temporaire, _MaxY : MaxY_temporaire
;     DebYPoly = -1 : Poly hors de l'ecran
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; calcule X debut et X fin du contour

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1<YP2
%macro 	@ClipContourGchX2Sup	0
		CMP		ECX,[_MaxY]  ; [YP1]
		JG		NEAR %%Fin
		CMP		EBP,[_MinY]
		JL		NEAR %%Fin
		; Calcule la pente
		NEG		EAX		; -[XP1]
		NEG		ECX     ; -[YP1]
		ADD		EAX,[XP2]
		XOR		EDX,EDX
		ADD		ECX,EBP			; ECX = YP2-YP1
		SHL		EAX,Prec
		DIV   	ECX   		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MinY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX		; reste 0
		MOV		EBX,EBP
		SUB		EBP,ECX		 ; [_MinY]-[YP1]
		JLE		SHORT %%PasAjYP1
		MOV		[YP1],EBX	 ; [YP1] = [_MinY]
		IMUL		EBP,EAX		 ; EBP = DeltaY*Pente
		MOV		EDX,EBP
		AND		EDX,(1 << Prec) - 1
		SHR		EBP,Prec
		ADD		[XP1],EBP
		MOV		ECX,[XP1]
		CMP		ECX,[_MaxX]
		JL 		SHORT %%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		SHORT %%Fin
%%PasPolyOut:
%%PasAjYP1:	; Ajustement de <YP2>  =>& XP2
		MOV		ECX,[YP2]
		MOV		EBP,[_MaxY]
		MOV		EBX,[YP1]
		CMP		ECX,EBP			  ;ECX= [YP2]>[_MaxY] ?
		CMOVG   ECX,EBP
		MOV		EDI,[XP1]
		SUB		ECX,EBX	  ; ECX= DeltaY
		ADD		EDX,(1<<Prec)	; Compteur debordement dans EDX
		ADD		EBX,[_OrgY]
%%BcClcCtDr2:
		DEC		ECX
		MOV		[_TPolyAdDeb+EBX*4],EDI
		JS		SHORT %%Fin
		SUB		EDX,EAX		 ; EDX-Pente
		JG 		SHORT %%NoDebord
		NEG     EDX
		MOV		EBP,EDX
		SHR		EBP,Prec
		AND     EDX,(1 << Prec) - 1
		INC		EBP
		SUB     EDX,(1 << Prec)
		ADD		EDI,EBP
		NEG     EDX
%%NoDebord:
        INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1<YP2
%macro 	@ClipContourGchX1Sup	0
		CMP		ECX,[_MaxY]	 ; [YP1]
		JG		NEAR %%Fin
		CMP		EBP,[_MinY]	 ; [YP2]
		MOV		EBX,[XP2]
		JL		NEAR %%Fin
		; Calcule la pente
		SUB		EAX,EBX		; [XP1]-[XP2]
		XOR    	EDX,EDX		; reste = 0
		NEG		ECX     ; -[YP1]
		ADD		ECX,EBP		; = YP2-YP1 compteur dans ECX
		SHL		EAX,Prec
		DIV		ECX		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MinY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX
		MOV		EBX,EBP
		SUB		EBP,ECX	  ; [_MinY]-[YP1]
		JLE		SHORT %%PasAjYP1
		IMUL	EBP,EAX
		MOV		[YP1],EBX
		MOV		EDX,EBP
		AND		EDX,(1 << Prec) - 1	 ; calcule reste
		SHR		EBP,Prec
		NEG		EDX
		SUB		[XP1],EBP
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		EBX,[YP2]
		MOV		EBP,[_MaxY]
		MOV     ECX,EBX
		SUB		EBX,EBP			; [YP2]-[_MaxY]
		JLE		SHORT %%PasAjYP2
		IMUL	EBX,EAX
		MOV		ECX,EBP
		SHR		EBX,Prec
		ADD		EBX,[XP2]
		CMP		EBX,[_MaxX]
		JL 		SHORT %%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		SHORT %%Fin
%%PasPolyOut:
%%PasAjYP2:
; Pente deja dans EAX
		MOV		EBX,[YP1]
		MOV		EDI,[XP1]
		SUB		ECX,EBX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		ADD		EBX,[_OrgY]
%%BcClcCtDr2:
		DEC		ECX
		MOV		[_TPolyAdDeb+EBX*4],EDI
		JS		SHORT %%Fin
		SUB		EDX,EAX
		JG 		SHORT %%NoDebord
		NEG     EDX
		MOV		EBP,EDX
		SHR		EBP,Prec
		AND     EDX,(1 << Prec) - 1
		INC		EBP
		SUB     EDX,(1 << Prec)
		SUB		EDI,EBP
		NEG     EDX
%%NoDebord:
		INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2
%macro 	@ClipContourDrtX2Sup	0
		CMP		ECX,[_MinY]
		JL			NEAR %%Fin
		CMP		EBP,[_MaxY]
		MOV		EBX,[XP2]
		JG			NEAR %%Fin
		; Calcule la pente
		NEG		EAX		; -[XP1]
		SUB		ECX,EBP     ; [YP1]-[YP2]
		ADD		EAX,EBX       ; EAX = XP2-XP1
		XOR    	EDX,EDX
		SHL		EAX,Prec
        DIV		ECX	   		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		ECX,[YP1]
		MOV		EBP,[_MaxY]
		XOR		EDX,EDX
		SUB		ECX,EBP	 ; [YP1]-[_MaxY]
		JLE		SHORT %%PasAjYP1
		IMUL	ECX,EAX
		MOV		[YP1],EBP
		MOV		EDX,ECX
		AND		EDX,(1 << Prec) - 1
		SHR		ECX,Prec
		NEG		EDX
		ADD		[XP1],ECX
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		EBP,[_MinY]
		MOV		ECX,[YP2]
		MOV		EBX,EBP
		MOV		EDI,[XP2]
		SUB		EBP,ECX
		JLE		SHORT %%PasAjYP2
		IMUL	EBP,EAX
		MOV		ECX,EBX
		SHR		EBP,Prec
		SUB		EDI,EBP
		CMP		EDI,[_MinX]
		JG 		SHORT %%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		SHORT %%Fin
%%PasPolyOut:
%%PasAjYP2:
		; Pente deja en EAX
		MOV		EBX,ECX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		NEG		ECX
		ADD		EBX,[_OrgY]
		ADD		ECX,[YP1]
%%BcClcCtDr2:
		DEC		ECX
		MOV		[_TPolyAdFin+EBX*4],EDI
		JS		SHORT %%Fin
		SUB		EDX,EAX
		JG 		SHORT %%NoDebord
		NEG     EDX
		MOV		EBP,EDX
		SHR		EBP,Prec
		AND     EDX, (1 << Prec) - 1
		INC		EBP
		SUB     EDX,(1 << Prec)
		SUB		EDI,EBP
		NEG     EDX
%%NoDebord:
		INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1>YP2
%macro 	@ClipContourDrtX1Sup	0
		CMP		ECX,[_MinY]  ; [YP1]
		JL			NEAR %%Fin
		CMP		EBP,[_MaxY]
		JG 		NEAR %%Fin

		; Calcule la pente
		SUB		EAX,[XP2]		; [XP1]-[XP2]
		XOR    	EDX,EDX
		SUB		ECX,[YP2]		; [YP1]-[YP2]
		SHL		EAX,Prec
		DIV   	ECX	   		; Pente dans EAX
		; Ajustement de <YP1>  =>& XP1
		MOV		EBP,[_MaxY]
		MOV		ECX,[YP1]
		XOR		EDX,EDX
		SUB		ECX,EBP		   	;[YP1]-[_MaxY]
		JLE		SHORT %%PasAjYP1
		IMUL	ECX,EAX
		MOV		[YP1],EBP
		MOV		EDX,ECX
		AND		EDX,(1 << Prec) - 1
		SHR		ECX,Prec
		SUB		[XP1],ECX
		MOV		ECX,[XP1]
		CMP		ECX,[_MinX]
		JG 		SHORT %%PasPolyOut
		MOV		DWORD [DebYPoly],-1
		JMP		SHORT %%Fin
%%PasPolyOut:
%%PasAjYP1:		; Ajustement de <YP2>  =>& XP2
		MOV		EBP,[_MinY]
		MOV		ECX,[YP2]
		MOV		EBX,EBP
		MOV		EDI,[XP2]
		SUB		EBP,ECX
		JLE		SHORT %%PasAjYP2
		IMUL	EBP,EAX
		MOV		ECX,EBX
		SHR		EBP,Prec
		ADD		EDI,EBP
%%PasAjYP2:
		; Pente deja dans EAX
		;MOV		ECX,[YP2]
		MOV		EBX,ECX
		ADD		EDX,1 << Prec	; Compteur debordement dans EDX
		NEG		ECX
		ADD		EBX,[_OrgY]
		ADD		ECX,[YP1]
%%BcClcCtDr2:
		DEC		ECX
		MOV		[_TPolyAdFin+EBX*4],EDI
		JS		SHORT %%Fin
		SUB		EDX,EAX
		JG 		SHORT %%NoDebord
		NEG     EDX
		MOV		EBP,EDX
		SHR		EBP,Prec
		AND     EDX,(1 << Prec) - 1
		INC		EBP
		SUB     EDX,(1 << Prec)
		ADD		EDI,EBP
		NEG     EDX
%%NoDebord:
		INC		EBX
		JMP		SHORT %%BcClcCtDr2
%%Fin:
%endmacro
;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************

;calcule du contour du polygone lorsqu'il a une partie qui est hors de l'ecran
%macro	@ClipCalculerContour	0
;ALIGN 4
%%ClipBcCalCont:
		MOV		EBP,[YP2]
		MOV		ECX,[YP1]
		MOVD	xmm2,EDX     ; save EDX counter
		CMP		ECX,EBP
		JE		NEAR %%DYZero
		MOV		EAX,[XP1]
		JG		NEAR %%ContDrt; si YP1<YP2 alors drt sinon gch
		CMP		EAX,[XP2]
		JG		NEAR %%CntGchX1Sup
		@ClipContourGchX2Sup		; YP1<YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntGchX1Sup:	@ClipContourGchX1Sup		; YP1<YP2  &&  XP1>XP2
		JMP		%%FinContr
%%ContDrt:
		CMP		EAX,[XP2]
		JG		NEAR %%CntDrtX1Sup
		@ClipContourDrtX2Sup		; YP1>YP2  &&  XP1<XP2
		JMP		%%FinContr
%%CntDrtX1Sup:	@ClipContourDrtX1Sup		; YP1>YP2  &&  XP1>XP2
%%DYZero:
%%FinContr:
		CMP		DWORD [DebYPoly],-1
		JE		%%FinCalcContr
		MOVD	EDX,xmm2     ; restaure le compteur EDX
		DEC		EDX
		JS		NEAR %%FinCalcContr ; EDX < 0
		;MOV		ESI,[PPtrListPt]     ; ESI = PtrListPt
		MOV		EAX,[ESI+EDX*4]	; EAX=PtrPt[EDX]
		MOVQ   	[XP1],xmm4  ; last xp2,yp2 in XP1 YP1
		MOVQ   	xmm4,[EAX] ; XP2 | YP2
		MOVQ   	[XP2],xmm4
		JMP		%%ClipBcCalCont
%%FinCalcContr:
%endmacro


; calcule la position debut et fin dans le texture lorsque le poly est In
%macro	@InCalcTextCntMM	0
		MOV			ESI,[PPtrListPt]
		MOV			EDX,[NbPPoly]
		MOV			EBX,[ESI]
		DEC			EDX
		MOVQ		xmm2,[EBX+12] ; XT1 | YT1
		MOV			ECX,[EBX+4] ; YP(n-1)
		MOV			EBX,[ESI+EDX*4]
		MOV			[YP1],ECX
		; EAX EBP ECX XT2 YT2 YP2
		MOVQ		xmm5,[EBX+12] ; XT2 | YT2
		MOV			ECX,[EBX+4] ; YP(n-1)
		MOVQ		xmm7,xmm5 ; xmm7 =  XT2 | YT2
		MOV			[YP2],ECX
%%BcClTxtCnt:
		PSUBD		xmm5,xmm2 ; DXT | DYT

		SUB			ECX,[YP1]
		JZ			NEAR %%PasClCrLn
		JNS			%%PosDYP
		NEG			ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
        MOVD        xmm3,ECX
		PSLLD       xmm5,Prec
		PUNPCKLDQ   xmm3,xmm3

		CVTDQ2PS    xmm5,xmm5
		CVTDQ2PS    xmm3,xmm3
		INC			ECX
		DIVPS       xmm5,xmm3
		MOV			EDI,[YP1]
		XOR			EBX,EBX
		CMP			EDI,[YP2]
		CVTPS2DQ    xmm5,xmm5
		PEXTRD      EAX,xmm5,1 ; EAX = [PntPlusY]
		JG			%%CntTxtFin    ; YP1>YP2

		;--- adjust Cpt Dbrd X et Y for SAR
		OR			EAX,EAX
		MOVD		EDI,xmm5 ; [PntPlusX]
		SETL		BL
		MOV         EBP,[YP1]
		PINSRD      xmm3,[PntInitCPTDbrd+EBX*4],1 ; Cpt Dbr Y
		OR			EDI,EDI
		SETL		BL
		ADD			EBP,[_OrgY]
		PINSRD		xmm3,[PntInitCPTDbrd+EBX*4],0 ; Cpt Dbr X
		LEA			EAX,[_TexXDeb+EBP*4]
		LEA			EDI,[_TexYDeb+EBP*4]
;ALIGN 4
%%BcCntTxtDeb:
		MOVQ		xmm6,xmm3 ; cpt Dbrd X | Cpt Dbr Y
		MOVQ		xmm4,xmm2 ; XT1 | YT1
		PSRAD		xmm6,Prec
		DEC			ECX
		PADDD		xmm4,xmm6
		PADDD		xmm3,xmm5
		MOVD		[EAX],xmm4
		PEXTRD		[EDI],xmm4,1
		LEA			EAX,[EAX+4]
		LEA			EDI,[EDI+4]
		JNZ			SHORT %%BcCntTxtDeb
		JMP			%%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
		OR			EAX,EAX  ; EAX already contains [PntPlusY]
		MOVD		EDI,xmm5 ; [PntPlusX]
		SETG		BL
		MOV			EBP,[YP2]
		PINSRD      xmm3,[PntInitCPTDbrd+EBX*4],1 ; Cpt Dbr Y
		OR			EDI,EDI
		SETG		BL
		ADD			EBP,[_OrgY]
		PINSRD		xmm3,[PntInitCPTDbrd+EBX*4],0 ; Cpt Dbr X
		MOVQ		xmm2,xmm7 ; mm2 = XT2, YT2
		LEA			EDI,[_TexYFin+EBP*4]
		LEA			EAX,[_TexXFin+EBP*4]
;ALIGN 4
%%BcCntTxtFin:
		MOVQ		xmm6,xmm3
		MOVQ		xmm4,xmm2
		PSRAD		xmm6,Prec
		DEC			ECX
		PADDD		xmm4,xmm6
		PSUBD		xmm3,xmm5
		MOVD		[EAX],xmm4
		PEXTRD      [EDI],xmm4,1
		LEA			EAX,[EAX+4]
		LEA			EDI,[EDI+4]
		JNZ			SHORT %%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:
		DEC			EDX
		JS			SHORT %%FinClTxtCnt

		MOVQ		xmm2,xmm7 ; old XT2 | YT2 will be new XT1 | YT1
		MOV			ECX,[YP2]
		MOV			EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOV			[YP1],ECX
		MOVQ		xmm5,[EBX+12]  ; new XT2 | YT2
		MOV			ECX,[EBX+4]   ; YP
		MOVQ		xmm7,xmm5 ; = XT2 | YT2
		MOV			[YP2],ECX

		JMP		%%BcClTxtCnt
%%FinClTxtCnt:

%endmacro


;calcule la position debut et fin dans le texture lorsque le poly est Clipper
%macro	@ClipCalcTextCntMM	0
		MOV		    ESI,[PPtrListPt]
		MOV		    EDX,[NbPPoly]
		MOV		    EBX,[ESI]
		DEC		    EDX
		MOVQ    	xmm2,[EBX+12] ; XT1 | YT1 ;MOV		EAX,[EBX+12] ; XT1

		MOV		    ECX,[ESI+EDX*4]

		MOV     	EAX,[EBX+4] ; -
		MOVQ    	xmm4,[ECX+12] ; XT2 | YT2
		;MOVQ    	[XT1],xmm2
		MOV     	[YP1],EAX ; -
		MOV     	ECX,[ECX+4]
		MOVQ		xmm7,xmm4 ; xmm7 = XT2 | YT2
		MOV     	[YP2],ECX
%%BcClTxtCnt:
		SUB		    ECX,[YP1]
		PSUBD		xmm4,xmm2 ; = XT2 - XT1 | YT2 - YT1
		MOVD		xmm0,EDX
		MOVD		xmm1,ESI
		JZ			NEAR %%PasClCrLn
		PSLLD       xmm4,Prec
		JNS		    %%PosDYP
		NEG		    ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
		MOVD		EAX,xmm4
		MOVQ        xmm5,xmm4
		CDQ
		IDIV		ECX
		MOVD	    xmm4,EAX

		PEXTRD		EAX,xmm5,1
		CDQ
		IDIV		ECX
		XOR		    EBP,EBP        ; compteur debordement Y
		PINSRD	    xmm4,EAX,1 ; xmm4 = PntPlusX | PntPlusY

		MOV		    EAX,[YP1]
		XOR		    EDX,EDX        ; compteur debordement X
		CMP		    EAX,[YP2]

		JG			NEAR %%CntTxtFin
;**** Deb Aj Deb **********************
		MOV		    ESI,[YP2]
		CMP		    EAX,[_MaxY]
		JG			NEAR %%PasClCrLn
		CMP		    ESI,[_MinY]
		JL			NEAR %%PasClCrLn
		CMP		    EAX,[_MinY]
		JGE		    %%PasAjYP1   ; YP1 >= _MinY
		MOV		    EDI,[_MinY]  ; EDI = _MinY
		MOVD	    EDX,xmm4; [PntPlusX]
		SUB		    EDI,EAX      ; EDI = _MinY - YP1
		IMUL		EDX,EDI
		PEXTRD	    EBP,xmm4,1 ; [PntPlusY]
		IMUL		EBP,EDI
		MOV		    EAX,[_MinY]
%%PasAjYP1:
		CMP		    ESI,[_MaxY]  ; YP2 <= _MaxY
		JLE		    %%PasAjYP2
		MOV		    ESI,[_MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
		;--- ajuste Cpt Dbrd X et Y pour SAR
		PEXTRD		ECX,xmm4,1 ;[PntPlusY]
		XOR			EBX,EBX
		OR			ECX,ECX
		SETL		BL
		MOVD		EDI,xmm4 ; [PntPlusX]
		ADD			EBP,[PntInitCPTDbrd+EBX*4]

		OR			EDI,EDI
		SETL		BL
		MOV			ECX,ESI     ; ECX = YP2
		ADD			EDX,[PntInitCPTDbrd+EBX*4]
	;-----------------------------------
		MOV			EDI,_TexYDeb
		MOV			EBX,EAX     ; = YP1
		MOVD		xmm3,EDX
		MOV			ESI,_TexXDeb
		SUB			ECX,EAX     ; ECX = YP2-YP1
		PINSRD		xmm3,EBP,1
		ADD			EBX,[_OrgY]
;ALIGN 4
%%BcCntTxtDeb:
		MOVQ		xmm5,xmm3
		PSRAD		xmm5,Prec
		PADDD		xmm5,xmm2
		PADDD		xmm3,xmm4
		MOVD		[ESI+EBX*4],xmm5
		PEXTRD		[EDI+EBX*4],xmm5,1
		DEC		    ECX
		LEA		    EBX,[EBX+1]
		JNS		    %%BcCntTxtDeb
		JMP		    %%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
;**** Deb Aj Fin **********************
		XOR		    EDI,EDI
		MOV		    EAX,[YP2]
		MOV		    ESI,[YP1]
		CMP		    EAX,[_MaxY]
		JG			NEAR %%PasClCrLn
		CMP		    ESI,[_MinY]
		JL			NEAR %%PasClCrLn
		CMP		    EAX,[_MinY]
		JGE		    %%FPasAjYP2   ; YP2 >= _MinY
		MOV		    EDI,EAX  ; EDI = YP2
		MOVD	    EDX,xmm4 ; [PntPlusX]
		SUB		    EDI,[_MinY]      ; EDI = YP2 - _MinY
		PEXTRD	    EBP,xmm4,1 ; [PntPlusY]
		IMUL		EDX,EDI
		MOV		    EAX,[_MinY]
		IMUL		EBP,EDI
%%FPasAjYP2:
		CMP		    ESI,[_MaxY]   ; YP1 <= _MaxY
		JLE		    %%FPasAjYP1
		MOV		    ESI,[_MaxY]
%%FPasAjYP1:
;**** Fin Aj Fin **********************
		;--- ajuste Cpt Dbrd X et Y pour SAR
		PEXTRD		ECX,xmm4,1 ; [PntPlusY]
		XOR			EBX,EBX
		OR			ECX,ECX
		SETG		BL
		MOVD		EDI,xmm4 ;[PntPlusX]
		ADD			EBP,[PntInitCPTDbrd+EBX*4]

		OR			EDI,EDI
		SETG		BL
		MOVQ		xmm2,xmm7 ; mm2 = XT2, YT2
		ADD			EDX,[PntInitCPTDbrd+EBX*4]
		MOV			ECX,ESI  ; ECX = YP1
;-----------------------------------
		MOV			EBX,EAX  ; = YP2
		MOV			EDI,_TexYFin
		MOVD		xmm3,EDX
		MOV			ESI,_TexXFin
		SUB			ECX,EAX  ; ECX = YP1 - YP2
		PINSRD		xmm3,EBP,1
		ADD			EBX,[_OrgY]
;ALIGN 4
%%BcCntTxtFin:
		MOVQ		xmm5,xmm3
		PSRAD		xmm5,Prec
		PADDD		xmm5,xmm2
		PSUBD		xmm3,xmm4
		MOVD		[ESI+EBX*4],xmm5
		PEXTRD		[EDI+EBX*4],xmm5,1
		DEC    	    ECX
		LEA		    EBX,[EBX+1]
		JNS		    %%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:
		MOVD		EDX,xmm0
		MOVD		ESI,xmm1
		DEC		    EDX
		JS		    %%FinClTxtCnt

		MOV		    EBX,[ESI+EDX*4]	; EBX=PtrPt[EDX]
		MOVQ		xmm2,xmm7 ; old XT2 | YT2 will be the new XT1 | YT1
		MOV		    EAX,[YP2]
		MOVQ		xmm4,[EBX+12] ; new XT2 | YT2
		MOV		    [YP1],EAX
		MOV		    ECX,[EBX+4]   ; YP
		MOVQ		xmm7,xmm4
		MOV		    [YP2],ECX

		JMP		%%BcClTxtCnt

%%FinClTxtCnt:
%endmacro

%macro @InCalcTextCnt	0
		;CALL		InCalcTextCntPRC
		@InCalcTextCntMM
%endmacro

;ALIGN 32
;InCalcTextCntPRC:
;		@InCalcTextCntMM
;		RET

%macro @ClipCalcTextCnt	0
		CALL		ClipCalcTextCntPRC
%endmacro

ALIGN 32
ClipCalcTextCntPRC:
		@ClipCalcTextCntMM
		RET

