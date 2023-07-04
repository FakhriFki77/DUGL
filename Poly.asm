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


;**CLIP*****************************************************
;GLOB DebYPoly : MinY_temporaire, MaxY : MaxY_temporaire
;     DebYPoly = -1 : Poly hors de l'ecran
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; calcule X debut et X fin du contour

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1, EBP : YP2
; condition XP1<XP2 && YP1<YP2
%macro  @ClipContourGchX2Sup    0
        ; Calcule la pente
        NEG     EAX     ; -[XP1]
        NEG     ECX     ; -[YP1]
        ADD     EAX,[XP2]
        XOR     EDX,EDX
        ;INC     EAX
        ADD     ECX,EBP         ; ECX = YP2-YP1
        SHL     EAX,Prec
        DIV     ECX         ; Pente dans EAX
        ; Adjust <YP1>  =>& XP1
        MOV     EBP,EDI ; = [MinY]
        MOV     ECX,[YP1]
        XOR     EDX,EDX     ; EDX = CptDbrd
        SUB     EBP,ECX      ; [MinY]-[YP1]
        JLE     SHORT %%PasAjYP1
        IMUL    EBP,EAX      ; EBP = DeltaY*Pente
        MOV     [YP1],EDI    ; [YP1] = [MinY]
        MOV     EDX,EBP
        AND     EDX,(1 << Prec) - 1
        SHR     EBP, Prec
        ADD     EBP,[XP1]
        CMP     EBP,[MaxX]
        MOV     [XP1],EBP
        JL      SHORT %%PasPolyOut
        MOV     DWORD [DebYPoly],-1
        JMP     SHORT %%Fin
%%PasPolyOut:
%%PasAjYP1: ; Ajustement de <YP2>  =>& XP2
        MOV     EBP,EBX ; [MaxY]
        MOV     ECX,[YP2]
        MOV     EBX,[YP1]
        CMP     ECX,EBP           ;ECX= [YP2]>[MaxY] ?
        CMOVG   ECX,EBP
        MOV     EDI,[XP1]
        SUB     ECX,EBX   ; ECX= DeltaY
        XOR     EBP,EBP
        ADD     EBX,[OrgY]
%%BcClcCtDr2:
        ADD     EBP,EDI
        DEC     ECX
        MOV     [TPolyAdDeb+EBX*4],EBP
        JS      SHORT %%Fin
        XOR     EBP,EBP
        ADD     EDX,EAX
        INC     EBX
        SHLD    EBP,EDX,32-Prec ; EBP = EDX >> Prec
        JMP     SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1<YP2
%macro  @ClipContourGchX1Sup    0
        ; Calcule la pente
        SUB     EAX,[XP2]    ; [XP1]-[XP2]
        XOR     EDX,EDX     ; reste = 0
        NEG     ECX     ; -[YP1]
        ;INC     EAX
        ADD     ECX,EBP     ; = YP2-YP1 compteur dans ECX
        SHL     EAX,Prec
        DIV     ECX     ; Pente dans EAX
        ; Ajustement de <YP1>  =>& XP1
        MOV     EBP,EDI ; = [MinY]
        MOV     ECX,[YP1]
        XOR     EDX,EDX
        SUB     EBP,ECX   ; [MinY]-[YP1]
        JLE     SHORT %%PasAjYP1
        IMUL    EBP,EAX
        MOV     [YP1],EDI ; = [MinY]
        ADD     EDX,EBP
        MOV     EBP,EDX
        AND     EDX,(1 << Prec) - 1  ; calcule reste
        SHR     EBP,Prec
        SUB     [XP1],EBP
%%PasAjYP1:     ; Ajustement de <YP2>  =>& XP2
        MOV     EBP,EBX ; =[MaxY]
        MOV     EBX,[YP2]
        MOV     ECX,EBX
        SUB     EBX,EBP         ; [YP2]-[MaxY]
        JLE     SHORT %%PasAjYP2
        IMUL    EBX,EAX
        MOV     ECX,EBP
        SHR     EBX,Prec
        ADD     EBX,[XP2]
        CMP     EBX,[MaxX]
        JL      SHORT %%PasPolyOut
        MOV     DWORD [DebYPoly],-1
        JMP     SHORT %%Fin
%%PasPolyOut:
%%PasAjYP2:
; Pente deja dans EAX
        MOV     EBX,[YP1]
        MOV     EDI,[XP1]
        SUB     ECX,EBX
        XOR     EBP,EBP
        ADD     EBX,[OrgY]
%%BcClcCtDr2:
        ADD     EBP,EDI
        DEC     ECX
        MOV     [TPolyAdDeb+EBX*4],EBP
        JS      SHORT %%Fin
        XOR     EBP,EBP
        ADD     EDX,EAX
        SHLD    EBP,EDX,32-Prec ; EBP = EDX >> Prec
        INC     EBX
        NEG     EBP
        JMP     SHORT %%BcClcCtDr2
%%Fin:
%endmacro

; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1<XP2 && YP1>YP2
%macro  @ClipContourDrtX2Sup    0
        ; Calcule la pente
        NEG     EAX     ; -[XP1]
        SUB     ECX,EBP     ; [YP1]-[YP2]
        ADD     EAX,[XP2]   ; EAX = XP2-XP1
        ;INC     EAX
        XOR     EDX,EDX
        SHL     EAX,Prec
        DIV     ECX         ; Pente dans EAX
        ; Adjust <YP1>  =>& XP1
        MOV     ECX,[YP1]
        XOR     EDX,EDX
        SUB     ECX,EBX  ; [YP1]-[MaxY]
        JLE     SHORT %%PasAjYP1
        IMUL    ECX,EAX
        MOV     [YP1],EBX
        MOV     EDX,ECX
        AND     EDX,(1 << Prec) - 1
        SHR     ECX,Prec
        ADD     [XP1],ECX
%%PasAjYP1:     ; Ajustement de <YP2>  =>& XP2
        MOV     EBP,EDI ; = [MinY]
        MOV     ECX,[YP2]
        MOV     EBX,EBP
        MOV     EDI,[XP2]
        SUB     EBP,ECX
        JLE     SHORT %%PasAjYP2
        IMUL    EBP,EAX
        MOV     ECX,EBX
        SHR     EBP,Prec
        SUB     EDI,EBP
        CMP     EDI,[MinX]
        JG      SHORT %%PasPolyOut
        MOV     DWORD [DebYPoly],-1
        JMP     SHORT %%Fin
%%PasPolyOut:
%%PasAjYP2:
        ; Pente deja en EAX
        MOV     EBX,ECX ; ECX = [YP2]
        XOR     EBP,EBP
        NEG     ECX
        ADD     EBX,[OrgY]
        ADD     ECX,[YP1]
%%BcClcCtDr2:
        ADD     EBP,EDI
        DEC     ECX
        MOV     [TPolyAdFin+EBX*4],EBP
        JS      SHORT %%Fin
        XOR     EBP,EBP
        ADD     EDX,EAX
        SHLD    EBP,EDX,32-Prec ; EBP = EDX >> Prec
        INC     EBX
        NEG     EBP
        JMP     SHORT %%BcClcCtDr2
%%Fin:
%endmacro
; IN : XP1, YP1, XP2, YP2, EAX : XP1, ECX : YP1
; condition XP1>XP2 && YP1>YP2
%macro  @ClipContourDrtX1Sup    0
        ; Calcule la pente
        SUB     EAX,[XP2]       ; [XP1]-[XP2]
        ;INC     EAX
        XOR     EDX,EDX
        SUB     ECX,EBP       ; [YP1]-[YP2]
        SHL     EAX,Prec
        DIV     ECX         ; Pente dans EAX
        ; Ajustement de <YP1>  =>& XP1
        MOV     ECX,[YP1]
        XOR     EDX,EDX
        SUB     ECX,EBX         ;[YP1]-[MaxY]
        JLE     SHORT %%PasAjYP1
        IMUL    ECX,EAX
        MOV     [YP1],EBX ; = [MaxY]
        SHR     ECX,Prec
        SUB     [XP1],ECX
        MOV     ECX,[XP1]
        CMP     ECX,[MinX]
        JG      SHORT %%PasPolyOut
        MOV     DWORD [DebYPoly],-1
        JMP     SHORT %%Fin
%%PasPolyOut:
%%PasAjYP1:     ; Ajdust <YP2>  =>& XP2
        MOV     EBP,EDI ; [MinY]
        MOV     ECX,[YP2]
        MOV     EBX,EBP
        MOV     EDI,[XP2]
        SUB     EBP,ECX
        JLE     SHORT %%PasAjYP2
        IMUL    EBP,EAX
        MOV     EDX,EBP
        MOV     ECX,EBX
        SHR     EBP,Prec
        AND     EDX,(1 << Prec) - 1
        ADD     EDI,EBP
%%PasAjYP2:
        ; Pnt in EAX
        MOV     EBX,ECX ; ECX = [YP2]
        XOR     EBP,EBP
        NEG     ECX
        ADD     EBX,[OrgY]
        ADD     ECX,[YP1]
%%BcClcCtDr2:
        ADD     EBP,EDI
        DEC     ECX
        MOV     [TPolyAdFin+EBX*4],EBP
        JS      SHORT %%Fin
        XOR     EBP,EBP
        ADD     EDX,EAX
        INC     EBX
        SHLD    EBP,EDX,32-Prec ; EBP = EDX >> Prec
        JMP     SHORT %%BcClcCtDr2
%%Fin:
%endmacro
;**************************
;MACRO DE CALCUL DE CONTOUR
;**************************

;calcule du contour du polygone lorsqu'il a une partie qui est hors de l'ecran
%macro  @ClipCalculerContour    0
;ALIGN 4
%%ClipBcCalCont:
        MOV     EBP,[YP2]
        MOV     ECX,[YP1]
        MOV     EDI,[MinY]
        MOV     EBX,[MaxY]
        MOVD    mm2,EDX     ; save EDX counter
        CMP     ECX,EBP
        JE      %%DYZero
        MOV     EAX,[XP1]
        JG      %%ContDrt; si YP1<YP2 alors drt sinon gch
        CMP     ECX,EBX  ; [YP1]
        JG      %%FinContr
        CMP     EBP,EDI  ; [YP2]
        JL      %%FinContr
        CMP     EAX,[XP2]
        JG      %%CntGchX1Sup
        @ClipContourGchX2Sup        ; YP1<YP2  &&  XP1<XP2
        JMP     %%FinContr
%%CntGchX1Sup:
        @ClipContourGchX1Sup        ; YP1<YP2  &&  XP1>XP2
        JMP     %%FinContr
%%ContDrt:
        CMP     ECX,EDI
        JL      %%FinContr
        CMP     EBP,EBX
        JG      %%FinContr
        CMP     EAX,[XP2]
        JG      %%CntDrtX1Sup
        @ClipContourDrtX2Sup        ; YP1>YP2  &&  XP1<XP2
        JMP     %%FinContr
%%CntDrtX1Sup:
        @ClipContourDrtX1Sup        ; YP1>YP2  &&  XP1>XP2
%%DYZero:
%%FinContr:
        CMP     DWORD [DebYPoly],-1
        JE      %%FinCalcContr
        MOVD    EDX,mm2     ; restaure le compteur EDX
        DEC     EDX
        JS      %%FinCalcContr ; EDX < 0
        ;MOV        ESI,[PPtrListPt]     ; ESI = PtrListPt
        MOVQ    xmm3,xmm4
        MOV     EAX,[ESI+EDX*4] ; EAX=PtrPt[EDX]
        MOVQ    [XP1],xmm3  ; last xp2,yp2 in XP1 YP1
        MOVQ    xmm4,[EAX] ; XP2 | YP2
        MOVQ    [XP2],xmm4
        JMP     %%ClipBcCalCont
%%FinCalcContr:
%endmacro

; Compute HLines (U,V) or (XT, YT) ************************************************

%macro  @InComputeUVLines       0
                MOVD            EDX,mm5 ; [NbPPoly]-1
                MOVDQA          xmm7,[DGDQ0_1_2_3]
                MOVDQA          xmm6,[DGDQInitCPTDbrd]
                MOVD            ESI,mm6 ; [PPtrListPt]
                MOV             EBX,[ESI] ; Ptr P(1)
                MOV             EDI,[ESI+EDX*4] ; Ptr P(N-1)
                MOVQ            xmm1,[EBX+12] ; XT1 | YT1 (U|V)
                MOVQ            xmm2,[EDI+12] ; XT2 | YT2
                MOVD            mm1,[EBX+4] ; = YP1
                MOVD            mm2,[EDI+4] ; = YP2
                MOVD            mm3,[OrgY]
%%InLoopUVHLines:
                MOVD            mm7,EDX     ; save EDX counter
                MOVD            ECX,mm1   ;  = [YP1]
                MOVD            EBP,mm2   ;  = [YP2]
                XOR             EDX,EDX
                CMP             ECX,EBP  ; YP2
                MOVD            EBX,mm3  ; = [OrgY]
                JE              %%EndHLine ; DY = 0, skip this line
; handle U *****
                MOV             ESI,TexXFin ; default end/right
                MOVD            EAX,xmm1 ; = [U1]
                MOVD            EDI,xmm2 ; = [U2]
                JG              SHORT %%HRightU ; if YP1<YP2 then right else left
%%HLeftU:
                ; swap P1, P2 and change Adress of writing into ESI
                MOV             ESI,TexXDeb ; revert to start/left
                XCHG            ECX,EBP
                XCHG            EAX,EDI
%%HRightU:
                LEA             EBX,[EBX+EBP] ; EBX = [YP2]+[OrgY] : Index
                SUB             EAX,EDI ; D(U/V)
                LEA             EBX,[ESI+EBX*4] ; final dest adress
                CALL            InHLineUVCompute

; handle V *****
                MOVD            ECX,mm1   ;  = [YP1]
                MOVD            EBP,mm2   ;  = [YP2]
                MOVD            EBX,mm3   ;  = [OrgY]
                XOR             EDX,EDX
                CMP             ECX,EBP  ; YP2
                MOV             ESI,TexYFin ; default end/right
                PEXTRD          EAX,xmm1,1 ; = [V1]
                PEXTRD          EDI,xmm2,1 ; = [V2]
                JG              SHORT %%HRightV ; if YP1<YP2 then right else left
                ; swap P1, P2 and change Adress of writing into ESI
                XCHG            EAX,EDI
                MOV             ESI,TexYDeb ; revert to start/left
                XCHG            ECX,EBP
%%HRightV:
                LEA             EBX,[EBX+EBP] ; EBX = [YP2]+[OrgY] : Index
                SUB             EAX,EDI ; D(U/V)
                LEA             EBX,[ESI+EBX*4] ; final dest adress
                CALL            InHLineUVCompute
%%EndHLine:
                MOVD            EDX,mm7     ; restore EDX counter
                MOVD            ESI,mm6     ; ESI = PtrListPt
                DEC             EDX
                JS              SHORT %%EndInUVHLines ; EDX < 0
                MOV             EAX,[ESI+EDX*4] ; EAX=PtrPt[EDX]
                MOVQ            mm1,mm2 ; [XP2] ; old YP2 will be new  YP1
                MOVDQA          xmm1,xmm2 ; Old XT2|YT2 become new XT1|YT1
                MOVQ            mm2,[EAX+4] ; new YP2
                MOVQ            xmm2,[EAX+12] ; new XT2|YT2

                JMP             %%InLoopUVHLines
%%EndInUVHLines:
%endmacro

;calcule la position debut et fin dans le texture lorsque le poly est Clipper
%macro  @ClipCalcTextCntMM  0
        MOVD        ESI,mm6 ; [PPtrListPt]
        MOV         EDX,[NbPPoly]
        MOV         EBX,[ESI]
        DEC         EDX
        MOVQ        xmm2,[EBX+12] ; XT1 | YT1 ;MOV      EAX,[EBX+12] ; XT1

        MOV         ECX,[ESI+EDX*4]

        MOV         EAX,[EBX+4] ; -
        MOVQ        xmm4,[ECX+12] ; XT2 | YT2
        ;MOVQ       [XT1],xmm2
        MOV         [YP1],EAX ; -
        MOV         ECX,[ECX+4]
        MOVQ        xmm7,xmm4 ; xmm7 = XT2 | YT2
        MOV         [YP2],ECX
%%BcClTxtCnt:
        SUB         ECX,[YP1]
        PSUBD       xmm4,xmm2 ; = XT2 - XT1 | YT2 - YT1
        MOVD        xmm0,EDX
        MOVD        xmm1,ESI
        JZ          NEAR %%PasClCrLn
        PSLLD       xmm4,Prec
        JNS         %%PosDYP
        NEG         ECX  ; DeltaYP <0 => ECX = | DYP |
%%PosDYP:
        MOVD        EAX,xmm4
        MOVQ        xmm5,xmm4
        CDQ
        IDIV        ECX
        MOVD        xmm4,EAX

        PEXTRD      EAX,xmm5,1
        CDQ
        IDIV        ECX
        XOR         EBP,EBP        ; compteur debordement Y
        PINSRD      xmm4,EAX,1 ; xmm4 = PntPlusX | PntPlusY

        MOV         EAX,[YP1]
        XOR         EDX,EDX        ; compteur debordement X
        CMP         EAX,[YP2]

        JG          NEAR %%CntTxtFin
;**** Deb Aj Deb **********************
        MOV         ESI,[YP2]
        CMP         EAX,[MaxY]
        JG          NEAR %%PasClCrLn
        CMP         ESI,[MinY]
        JL          NEAR %%PasClCrLn
        CMP         EAX,[MinY]
        JGE         %%PasAjYP1   ; YP1 >= MinY
        MOV         EDI,[MinY]  ; EDI = MinY
        MOVD        EDX,xmm4; [PntPlusX]
        SUB         EDI,EAX      ; EDI = MinY - YP1
        IMUL        EDX,EDI
        PEXTRD      EBP,xmm4,1 ; [PntPlusY]
        IMUL        EBP,EDI
        MOV         EAX,[MinY]
%%PasAjYP1:
        CMP         ESI,[MaxY]  ; YP2 <= MaxY
        JLE         %%PasAjYP2
        MOV         ESI,[MaxY]
%%PasAjYP2:
;**** Fin Aj Deb **********************
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        PEXTRD      ECX,xmm4,1 ;[PntPlusY]
        XOR         EBX,EBX
        OR          ECX,ECX
        SETL        BL
        MOVD        EDI,xmm4 ; [PntPlusX]
        ADD         EBP,[PntInitCPTDbrd+EBX*4]

        OR          EDI,EDI
        SETL        BL
        MOV         ECX,ESI     ; ECX = YP2
        ADD         EDX,[PntInitCPTDbrd+EBX*4]
    ;-----------------------------------
        MOV         EDI,TexYDeb
        MOV         EBX,EAX     ; = YP1
        MOVD        xmm3,EDX
        MOV         ESI,TexXDeb
        SUB         ECX,EAX     ; ECX = YP2-YP1
        PINSRD      xmm3,EBP,1
        ADD         EBX,[OrgY]
;ALIGN 4
%%BcCntTxtDeb:
        MOVQ        xmm5,xmm3
        PSRAD       xmm5,Prec
        PADDD       xmm5,xmm2
        PADDD       xmm3,xmm4
        MOVD        [ESI+EBX*4],xmm5
        PEXTRD      [EDI+EBX*4],xmm5,1
        DEC         ECX
        LEA         EBX,[EBX+1]
        JNS         %%BcCntTxtDeb
        JMP         %%FinCntTxtFin
%%FnCntTxtDeb:
%%CntTxtFin:
;**** Deb Aj Fin **********************
        XOR         EDI,EDI
        MOV         EAX,[YP2]
        MOV         ESI,[YP1]
        CMP         EAX,[MaxY]
        JG          NEAR %%PasClCrLn
        CMP         ESI,[MinY]
        JL          NEAR %%PasClCrLn
        CMP         EAX,[MinY]
        JGE         %%FPasAjYP2   ; YP2 >= MinY
        MOV         EDI,EAX  ; EDI = YP2
        MOVD        EDX,xmm4 ; [PntPlusX]
        SUB         EDI,[MinY]      ; EDI = YP2 - MinY
        PEXTRD      EBP,xmm4,1 ; [PntPlusY]
        IMUL        EDX,EDI
        MOV         EAX,[MinY]
        IMUL        EBP,EDI
%%FPasAjYP2:
        CMP         ESI,[MaxY]   ; YP1 <= MaxY
        JLE         %%FPasAjYP1
        MOV         ESI,[MaxY]
%%FPasAjYP1:
;**** Fin Aj Fin **********************
        ;--- ajuste Cpt Dbrd X et Y pour SAR
        PEXTRD      ECX,xmm4,1 ; [PntPlusY]
        XOR         EBX,EBX
        OR          ECX,ECX
        SETG        BL
        MOVD        EDI,xmm4 ;[PntPlusX]
        ADD         EBP,[PntInitCPTDbrd+EBX*4]

        OR          EDI,EDI
        SETG        BL
        MOVQ        xmm2,xmm7 ; mm2 = XT2, YT2
        ADD         EDX,[PntInitCPTDbrd+EBX*4]
        MOV         ECX,ESI  ; ECX = YP1
;-----------------------------------
        MOV         EBX,EAX  ; = YP2
        MOV         EDI,TexYFin
        MOVD        xmm3,EDX
        MOV         ESI,TexXFin
        SUB         ECX,EAX  ; ECX = YP1 - YP2
        PINSRD      xmm3,EBP,1
        ADD         EBX,[OrgY]
;ALIGN 4
%%BcCntTxtFin:
        MOVQ        xmm5,xmm3
        PSRAD       xmm5,Prec
        PADDD       xmm5,xmm2
        PSUBD       xmm3,xmm4
        MOVD        [ESI+EBX*4],xmm5
        PEXTRD      [EDI+EBX*4],xmm5,1
        DEC         ECX
        LEA         EBX,[EBX+1]
        JNS         %%BcCntTxtFin
%%FinCntTxtFin:
%%PasClCrLn:
        MOVD        EDX,xmm0
        MOVD        ESI,xmm1
        DEC         EDX
        JS          %%FinClTxtCnt

        MOV         EBX,[ESI+EDX*4] ; EBX=PtrPt[EDX]
        MOVQ        xmm2,xmm7 ; old XT2 | YT2 will be the new XT1 | YT1
        MOV         EAX,[YP2]
        MOVQ        xmm4,[EBX+12] ; new XT2 | YT2
        MOV         [YP1],EAX
        MOV         ECX,[EBX+4]   ; YP
        MOVQ        xmm7,xmm4
        MOV         [YP2],ECX

        JMP     %%BcClTxtCnt

%%FinClTxtCnt:
%endmacro

%macro @InCalcTextCnt   0
        ;CALL       InCalcTextCntPRC
        @InCalcTextCntMM
%endmacro

;ALIGN 32
;InCalcTextCntPRC:
;       @InCalcTextCntMM
;       RET

%macro @ClipCalcTextCnt 0
        CALL        ClipCalcTextCntPRC
%endmacro

ALIGN 32
ClipCalcTextCntPRC:
        @ClipCalcTextCntMM
        RET

