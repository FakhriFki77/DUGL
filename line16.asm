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

ALIGN 32
line16:
    ARG     LX16P1, 4, LY16P1, 4, LX16P2, 4, LY16P2, 4, lnCol16, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EAX,[EBP+LX16P1]
            MOV         ECX,[EBP+lnCol16]
            MOV         EBX,[EBP+LX16P2]
            MOV         EDI,[EBP+LY16P2]
            MOV         ESI,[EBP+LY16P1]

            MOV         [XP1],EAX
            MOV         [clr],ECX
            MOV         [XP2],EBX
            MOV         [YP2],EDI
            MOV         [YP1],ESI
            JMP         SHORT Line16.DoLine16

ALIGN 32
Line16:
    ARG     Ptr16P1, 4, Ptr16P2, 4, Col16, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EAX,[EBP+Col16]
            MOV         ECX,[EBP+Ptr16P1]
            MOV         [clr],EAX
            MOV         EDX,[EBP+Ptr16P2]
            MOV         EAX,[ECX]   ; X1
            MOV         EBX,[EDX]   ; X2
            MOV         EDI,[EDX+4] ; Y2
            MOV         ESI,[ECX+4] ; Y1
            MOV         [XP1],EAX   ; X1
            MOV         [XP2],EBX   ; X2
            MOV         [YP2],EDI   ; Y2
            MOV         [YP1],ESI   ; Y1
.DoLine16:
            ;MOV        EAX,[XP1]   ; ligne en dehors de la fenetre ?
            ;MOV        EBX,[XP2]
            MOV         EDX,EAX
            CMP         EAX,EBX
            JL          .VMaxX
            XCHG        EAX,EBX
.VMaxX:    CMP          EAX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
            SUB         EBX,EAX
            MOV         ESI,EBX    ;calcul de abs(x2-x1)

            MOV         EAX,[YP1]
            MOV         EBX,EDI ; [YP2]
            MOV         ECX,EAX
            CMP         EAX,EBX
            JL          .VMaxY
            XCHG        EAX,EBX
.VMaxY:    CMP          EAX,[MaxY]
            JG          .FinLine
            CMP         EBX,[MinY]
            JL          .FinLine       ; fin du test
            SUB         EBX,EAX
            MOV         EDI,EBX        ;  abs(y2-y1)

            OR          EDI,EDI
            JZ          .cas4
.PasNegEDI:
            OR          ESI,ESI
            JZ          .cas2

            INC         ESI           ; abs(x2-x1)+1
            INC         EDI           ; abs(y2-y1)+1
            MOV         EAX,EDX         ; EDX = [XP1]
            MOV         EBX,[XP2]    ; cas 1 et cas 2
            CMP         EAX,EBX
            JL          .ClipMaxX
            XCHG        EAX,EBX
.ClipMaxX:  CMP         EAX,[MinX]
            JL          .Aj_1_2
            CMP         EBX,[MaxX]
            JG          .Aj_1_2
            MOV         EAX,ECX         ; ECX = [YP1]
            MOV         EBX,[YP2]
            CMP         EAX,EBX
            JL          .ClipMaxY
            XCHG        EAX,EBX
.ClipMaxY:  CMP         EAX,[MinY]
            JL          .Aj_1_2
            CMP         EBX,[MaxY]
            JG          .Aj_1_2
            JMP         .PasAj_1_2
.Aj_1_2:
            MOV         EBX,EDX         ; EDX = [XP1]
            MOV         ESI,[XP2]
            MOV         EDI,[YP2]
            CMP         EBX,ESI
            JL          .MaxAj1_2X
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
            CMP         EBX,[MinX]
            JNL         .PasAjX12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,[MinX]
            SUB         EAX,EBX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EBX,[MinX]
            ADD         ECX,EAX
.PasAjX12:  CMP         ESI,[MaxX]
            JNG         .PasAjM12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            OR          ESI,ESI
            JZ          .FinLine
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,ESI
            SUB         EAX,[MaxX]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ESI,[MaxX]
            SUB         EDI,EAX
.PasAjM12:  CMP         ECX,EDI
            JL          .MaxAj1_2Y
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2Y: CMP         ECX,[MaxY]
            JG          .FinLine
            CMP         EDI,[MinY]
            JL          .FinLine
;*********Ajustement des Y
            CMP         ECX,[MinY]
            JNL         .PasAjY12
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP
            MOV         EDX,EAX
            MOV         EAX,[MinY]
            SUB         EAX,ECX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ECX,[MinY]
            ADD         EBX,EAX
            CMP         EBX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
.PasAjY12:  CMP         EDI,[MaxY]
            JNG         .PasAjY12X
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP
            MOV         EDX,EAX
            MOV         EAX,EDI
            SUB         EAX,[MaxY]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EDI,[MaxY]
            SUB         ESI,EAX
.PasAjY12X:
            MOV         [XP1],EBX
            MOV         [YP1],ECX
            MOV         [XP2],ESI
            MOV         [YP2],EDI
            SUB         ESI,EBX
            SUB         EDI,ECX
            OR          ESI,ESI

            JZ          .cas2
            JNS         .PasNegESI2
            NEG         ESI
.PasNegESI2:
            OR          EDI,EDI
            JZ          .cas4
            JNS         .PasNegEDI2
            NEG         EDI
.PasNegEDI2:
.PasAj_1_2:
            CMP         ESI,EDI
            JB          .cas2

;*********CAS 1:  (DX > DY)***************************************************
.cas1:
            MOV         EAX,[XP1]
            MOV         EBP,[ScanLine] ; plus
            CMP         EAX,[XP2]
            JL          SHORT .PasSwap1
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap1:
            MOV         ESI,[XP2]
            MOV         EAX,[YP2]
            MOV         EDI,[NegScanLine] ; // Y Axis  ascendent
            SUB         ESI,[XP1]
            SUB         EAX,[YP1]
            JNS         SHORT .pstvDyCas1
            NEG         EAX ; abs(deltay)
            JMP         SHORT .ngtvDyCas1
.pstvDyCas1:
            NEG         EBP ; = -[ScanLine] as ascendent y Axis
.ngtvDyCas1:
            INC         EAX
            MOV         EBX,1 << Prec ; EBX = cpt Dbrd
            SHL         EAX,Prec
            INC         ESI ; deltaX + 1
            CDQ
            IDIV        ESI
            MOV         ECX,ESI ; ECX = deltaX = number pixels
            IMUL        EDI,[YP1]
            MOV         ESI,[XP1]
            MOV         EDX,EAX ; EDX = pnt
            LEA         EDI,[EDI+ESI*2] ; 2 time cause 16bpp
            MOV         EAX,[clr]
            ADD         EDI,[vlfb]
            MOV         ESI,1 << Prec
ALIGN 4
.lp_line1:
            SUB         EBX,EDX
            MOV         [EDI],AX
            JA          SHORT .no_debor1 ; EDI >0
            ADD         EBX,ESI ; +  (1 << Prec)
            ADD         EDI,EBP  ; EDI + = directional ScanLine
.no_debor1:
            DEC         ECX
            LEA         EDI,[EDI+2] ; EDI + 2
            JNZ         SHORT .lp_line1

            JMP         .FinLine
;*********CAS 2:  (DY > DX)***************************************************
.cas2:
            OR          EDI,EDI
            MOV         EAX,[YP1]
            JZ          .cas5
            CMP         EAX,[YP2]
            JL          SHORT .PasSwap2
            MOV         EAX,[YP2]
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap2:
            OR          ESI,ESI
            MOV         EBX,[YP2]
            JNZ         SHORT .noClipVert
            ; clip (YP1, YP2) with (MinY, MaxY)
            CMP         EAX,[MinY]
            JGE         SHORT .NoClipMinX
            MOV         EAX,[MinY]
.NoClipMinX:
            CMP         EBX,[MaxY]
            JLE         SHORT .NoClipMaxX
            MOV         EBX,[MaxY]
.NoClipMaxX:
            MOV         [YP1],EAX
            MOV         [YP2],EBX
.noClipVert:
            MOV         EAX,[XP2]
            MOV         ESI,EBX
            SUB         EAX,[XP1]
            JNS         SHORT .pstvDxCas2
            DEC         EAX
            JMP         SHORT .ngtvDxCas2
.pstvDxCas2:
            INC         EAX
.ngtvDxCas2:
            SUB         ESI,[YP1]
            SHL         EAX,Prec
            MOV         EBP,[NegScanLine]
            INC         ESI
            MOV         EDI,[YP1]
            CDQ
            IMUL        EDI,EBP ; * ScanLine
            IDIV        ESI
            MOV         ECX,ESI ; ECX = deltaY = number pixels
            MOV         EDX,EAX ; pente in EDX
            MOV         ESI,[XP1]

            ; start adress
            ADD         EDI,[vlfb]
            XOR         EBX,EBX ; accum in EBX
            OR          EDX,EDX
            LEA         EDI,[EDI+ESI*2] ; add xp1 2 times as 16 bpp
            MOV         EAX,[clr] ; draw color
            JNS         SHORT .line2_pstvPnt
            MOV         EBX,((1<<Prec)-1)
.line2_pstvPnt:
ALIGN 4
.lp_line2:
            MOV         ESI,EBX
            SAR         ESI,Prec
            ADD         EBX,EDX ; + pnt
            MOV         [EDI+ESI*2],AX
            DEC         ECX
            LEA         EDI,[EDI+EBP]     ;  Axe Y Montant -ResH
            JNZ         SHORT .lp_line2

            JMP         .FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:
            MOV         EAX,[XP1]
            MOV         ECX,ESI
            CMP         EAX,[XP2]
            JL          SHORT .PasSwap4
            ;MOV            EAX,[XP1]
            MOV         EBX,[XP2]
            MOV         [XP2],EAX
            MOV         [XP1],EBX
.PasSwap4:
            MOV         EAX,[MinX]
            CMP         EAX,[XP1]
            JLE         SHORT .sava41
            MOV         [XP1],EAX
.sava41:
            MOV         EAX,[MaxX]
            CMP         EAX,[XP2]
            JGE         SHORT .sava42
            MOV         [XP2],EAX
.sava42:
            MOV         EBP,[XP1]
            MOV         EDX,[XP2]
            SUB         EDX,EBP
            ;OR         ESI,ESI
            JZ          .cas5
            MOV         EDI,[YP1]
            INC         EDX
            IMUL        EDI,[NegScanLine]
            PSHUFLW     xmm0,[clr],0
            ADD         EDI,[vlfb]
            PUNPCKLQDQ  xmm0,xmm0
            LEA         EDI,[EDI+EBP*2]
            XOR         ECX,ECX
            MOVD        EAX,xmm0
            @SolidHLineSSE16
            JMP         SHORT .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
            MOV         EDI,[NegScanLine]
            MOV         EDX,[XP1]
            IMUL        EDI,[YP1]
            MOV         EAX,[clr]
            ADD         EDI,[vlfb]
            MOV         [EDI+EDX*2],AX
.FinLine:
            POP         ESI
            POP         EDI
            POP         EBX

    RETURN

ALIGN 32
linemap16:
    ARG     LMX16P1, 4, LMY16P1, 4, LMX16P2, 4, LMY16P2, 4, lnMCol16, 4, LM16Map, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EAX,[EBP+LMX16P1]
            MOV         EBX,[EBP+LMX16P2]
            MOV         ECX,[EBP+LMY16P1]
            MOV         EDX,[EBP+LMY16P2]
            MOV         ESI,[EBP+lnMCol16]
            MOV         EDI,[EBP+LM16Map]

            MOV         [XP1],EAX
            MOV         [XP2],EBX
            MOV         [YP1],ECX
            MOV         [YP2],EDX
            MOV         [clr],ESI
            MOV         [Plus2],EDI
            JMP         SHORT LineMap16.DoLine16

ALIGN 32
LineMap16:
    ARG     Map16PtrP1, 4, Map16PtrP2, 4, Map16Col, 4, Line16Map, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EDX,[EBP+Map16PtrP1]
            MOV         ECX,[EBP+Map16PtrP2]

            MOV         EAX,[EDX]   ; X1
            MOV         EBX,[ECX]   ; X2
            MOV         ESI,[EDX+4] ; Y1
            MOV         EDI,[ECX+4] ; Y2
            MOV         [XP1],EAX   ; X1
            MOV         [XP2],EBX   ; X2
            MOV         [YP1],ESI   ; Y1
            MOV         EAX,[EBP+Map16Col]
            MOV         [YP2],EDI   ; Y2
            MOV         EBX,[EBP+Line16Map]
            MOV         [clr],EAX
            MOV         [Plus2],EBX
.DoLine16:
            MOV         EDX,EAX
            CMP         EAX,EBX
            JL          .VMaxX
            XCHG        EAX,EBX
.VMaxX:     CMP         EAX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
            SUB         EBX,EAX
            MOV         ESI,EBX    ; abs(x2-x1)

            MOV         EAX,[YP1]
            MOV         EBX,[YP2]
            MOV         ECX,EAX
            CMP         EAX,EBX
            JL          .VMaxY
            XCHG        EAX,EBX
.VMaxY:     CMP         EAX,[MaxY]
            JG          .FinLine
            CMP         EBX,[MinY]
            JL          .FinLine       ; fin du test
            SUB         EBX,EAX
            MOV         EDI,EBX        ;  abs(y2-y1)

            OR          EDI,EDI
            JZ          .cas4
.PasNegEDI: OR          ESI,ESI
            JZ          .cas2

            INC         ESI           ; abs(x2-x1)+1
            INC         EDI           ; abs(y2-y1)+1
            MOV         EAX,EDX         ; EDX = [XP1]
            MOV         EBX,[XP2]    ; cas 1 et cas 2
            CMP         EAX,EBX
            JL          .ClipMaxX
            XCHG        EAX,EBX
.ClipMaxX:  CMP         EAX,[MinX]
            JL          .Aj_1_2
            CMP         EBX,[MaxX]
            JG          .Aj_1_2
            MOV         EAX,ECX         ; ECX = [YP1]
            MOV         EBX,[YP2]
            CMP         EAX,EBX
            JL          .ClipMaxY
            XCHG        EAX,EBX
.ClipMaxY:  CMP         EAX,[MinY]
            JL          .Aj_1_2
            CMP         EBX,[MaxY]
            JG          .Aj_1_2
            JMP         .PasAj_1_2
.Aj_1_2:    MOV         EBX,EDX         ; EDX = [XP1]
            MOV         ESI,[XP2]
            MOV         EDI,[YP2]
            CMP         EBX,ESI
            JL          .MaxAj1_2X
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
            CMP         EBX,[MinX]
            JNL         .PasAjX12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,[MinX]
            SUB         EAX,EBX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EBX,[MinX]
            ADD         ECX,EAX
.PasAjX12:  CMP         ESI,[MaxX]
            JNG         .PasAjM12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            OR          ESI,ESI
            JZ          .FinLine
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,ESI
            SUB         EAX,[MaxX]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ESI,[MaxX]
            SUB         EDI,EAX
.PasAjM12:  CMP         ECX,EDI
            JL          .MaxAj1_2Y
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2Y: CMP         ECX,[MaxY]
            JG          .FinLine
            CMP         EDI,[MinY]
            JL          .FinLine
    ;*********Ajustement des Y
            CMP         ECX,[MinY]
            JNL         .PasAjY12
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI ; sauve ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP ; rest ESI
            MOV         EDX,EAX
            MOV         EAX,[MinY]
            SUB         EAX,ECX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ECX,[MinY]
            ADD         EBX,EAX
            CMP         EBX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
.PasAjY12:  CMP         EDI,[MaxY]
            JNG         .PasAjY12X
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI ; sauve ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP ; rest ESI
            MOV         EDX,EAX
            MOV         EAX,EDI
            SUB         EAX,[MaxY]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EDI,[MaxY]
            SUB         ESI,EAX
.PasAjY12X:
            MOV         [XP1],EBX
            MOV         [YP1],ECX
            MOV         [XP2],ESI
            MOV         [YP2],EDI
            SUB         ESI,EBX
            SUB         EDI,ECX
            OR          ESI,ESI

            JZ          .cas2
            JNS         .PasNegESI2
            NEG         ESI
.PasNegESI2:
            OR          EDI,EDI
            JZ          .cas4
            JNS         .PasNegEDI2
            NEG         EDI
.PasNegEDI2:
.PasAj_1_2: CMP         ESI,EDI
            JB          .cas2

;*********CAS 1:  (DX > DY)***************************************************
.cas1:
            MOV         EAX,[XP1]
            MOV         EBP,[ScanLine] ; plus
            CMP         EAX,[XP2]
            JL          .PasSwap1
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap1:
            MOV         ESI,[XP2]
            MOV         EAX,[YP2]
            SUB         ESI,[XP1]
            SUB         EAX,[YP1]
            MOV         EDI,[NegScanLine]
            JNS         .pstvDyCas1
            NEG         EAX ; abs(deltay)
            JMP         SHORT .ngtvDyCas1
.pstvDyCas1:
            NEG         EBP ; = -[ScanLine] as ascendent y Axis
.ngtvDyCas1:
            INC         EAX
            MOV         EBX,[Plus2]  ; Line MAP
            SHL         EAX,Prec
            INC         ESI ; deltaX + 1
            CDQ
            IDIV        ESI
            MOV         ECX,[XP1]
            IMUL        EDI,[YP1]
            MOV         EDX,EAX ; EDX = pnt
            LEA         EDI,[EDI+ECX*2] ; += XP1 * 2  (as 16bpp)
            MOV         EAX,[clr]
            MOV         ECX,ESI ; ECX = deltaX = number pixels
            ADD         EDI,[vlfb]
            MOV         ESI,1 << Prec ; EBX = cpt Dbrd
ALIGN 4
.lp_line1:
            BT          EBX,0
            JNC         SHORT .PasDrl1
            MOV         [EDI],AX
.PasDrl1:
            SUB         ESI,EDX
            JA          .no_debor1 ; EDI >0
            ADD         ESI,(1 << Prec)
            ADD         EDI,EBP  ; EDI + = directional ScanLine
.no_debor1:
            ROR         EBX,1
            DEC         ECX
            LEA         EDI,[EDI+2] ; EDI + 2
            JNZ         .lp_line1

            JMP         .FinLine
;*********CAS 2:  (DY > DX)*************************************************
.cas2:
            OR          EDI,EDI
            MOV         EAX,[YP1]
            JZ          .cas5
            CMP         EAX,[YP2]
            JL          .PasSwap2
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap2:
            OR          ESI,ESI
            JNZ         .noClipVert
            MOV         EAX,[MinY]
            MOV         EBX,[MaxY]
            CMP         EAX,[YP1]
            JLE         SHORT .sava21
            MOV         [YP1],EAX
.sava21:
            CMP         EBX,[YP2]
            JGE         SHORT .sava22
            MOV         [YP2],EBX
.sava22:
.noClipVert:
            MOV         EAX,[XP2]
            MOV         ESI,[YP2]
            SUB         EAX,[XP1]
            JNS         .pstvDxCas2
            DEC         EAX
            JMP         SHORT .ngtvDxCas2
.pstvDxCas2:
            INC         EAX
.ngtvDxCas2:
            SUB         ESI,[YP1]
            SHL         EAX,Prec
            INC         ESI
            CDQ
            MOV         EBP,[XP1]
            IDIV        ESI
            MOV         EDI,[YP1]
            MOV         ECX,ESI ; ECX = deltaY = number pixels
            IMUL        EDI,[NegScanLine]; *= -(ScanLine)
            MOV         EDX,EAX ; pente in EDX

            ; start adress
            LEA         EDI,[EDI+EBP*2]
            XOR         EBX,EBX ; accum in EBX
            ADD         EDI,[vlfb]
            OR          EDX,EDX
            JNS         .line2_pstvPnt
            MOV         EBX,((1<<Prec)-1)
.line2_pstvPnt:
            ; draw color
            MOV         EBP,[clr]
            MOV         EAX,[Plus2] ; Line Map
ALIGN 4
.lp_line2:
            MOV         ESI,EBX
            SAR         ESI,Prec
            ADD         EBX,EDX ; + pnt
            BT          EAX,0
            JNC         SHORT .PasDrPx2
            MOV         [EDI+ESI*2],BP
.PasDrPx2:
            ROR         EAX,1
            SUB         EDI,[ScanLine]   ;  Axe Y Montant -ResH
            DEC         ECX
            JNZ         SHORT .lp_line2

            JMP         .FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:
            MOV         EAX,[XP1]
            MOV         ECX,ESI
            CMP         EAX,[XP2]
            JL          .PasSwap4
            ;MOV        EAX,[XP1]
            MOV         EBX,[XP2]
            MOV         [XP2],EAX
            MOV         [XP1],EBX
.PasSwap4:
            MOV         EAX,[MinX]
            CMP         EAX,[XP1]
            JLE         .sava41
            MOV         [XP1],EAX
.sava41:
            MOV         EAX,[MaxX]
            CMP         EAX,[XP2]
            JGE         .sava42
            MOV         [XP2],EAX
.sava42:
            MOV         ESI,[XP2]
            SUB         ESI,[XP1]
            JZ          .cas5
            INC         ESI
            MOV         EDI,[YP1]
            MOV         EBP,[XP1]
            MOV         ECX,[Plus2] ; Line Map
            IMUL        EDI,[NegScanLine]
            MOV         EAX,[clr]
            ADD         EDI,[vlfb]
            LEA         EDI,[EDI+EBP*2]
.lp4:
            BT          ECX,0
            JNC         SHORT .PasDrl4
            MOV         [EDI],AX
.PasDrl4:
            ROR         ECX,1
            DEC         ESI
            LEA         EDI,[EDI+2] ; + 2 : 16 bpp
            JNZ         .lp4

            JMP         SHORT .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
            TEST        BYTE [Plus2],1
            JZ          .FinLine

            MOV         EAX,[NegScanLine]
            MOV         ECX,[XP1]
            IMUL        EAX,[YP1]
            MOV         EDX,[clr]
            ADD         EAX,[vlfb]
            MOV         [EAX+ECX*2],DX
.FinLine:
            POP         ESI
            POP         EDI
            POP         EBX

    RETURN


ALIGN 32
lineblnd16:
    ARG     LBX16P1, 4, LBY16P1, 4, LBX16P2, 4, LBY16P2, 4, lnBCol16, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EAX,[EBP+LBX16P1]
            MOV         EBX,[EBP+LBX16P2]
            MOV         ESI,[EBP+LBY16P1]
            MOV         EDI,[EBP+LBY16P2]

            MOV         [XP1],EAX
            MOV         [XP2],EBX
            MOV         [YP1],ESI
            MOV         EAX,[EBP+lnBCol16]
            MOV         [YP2],EDI
            ;OV         [clr],ESI
            JMP         SHORT LineBlnd16.DoLine16

ALIGN 32
LineBlnd16:
    ARG     PBlnd16P1, 4, PBlnd16P2, 4, BlndCol16, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EDX,[EBP+PBlnd16P1]
            MOV         ECX,[EBP+PBlnd16P2]

            MOV         EAX,[EDX]   ; X1
            MOV         EBX,[ECX]   ; X2
            MOV         ESI,[EDX+4] ; Y1
            MOV         EDI,[ECX+4] ; Y2
            MOV         [XP1],EAX   ; X1
            MOV         [XP2],EBX   ; X2
            MOV         [YP1],ESI   ; Y1
            MOV         EAX,[EBP+BlndCol16]
            MOV         [YP2],EDI   ; Y2
            ;MOV        [clr],EAX
        ; blend precomputing-------------
.DoLine16:
            MOV         EBX,EAX ;
            MOV         ECX,EAX ;
            MOV         EDX,EAX ;
            AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
            SHR         EAX,24
            AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
            AND         AL,BlendMask ; remove any ineeded bits
            JZ          .FinLine ; nothing 0 is the source
            AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
            XOR         AL,BlendMask ; 31-blendsrc
            MOV         BP,AX
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

            PUNPCKLQDQ  xmm3,xmm3
            PUNPCKLQDQ  xmm4,xmm4
            PUNPCKLQDQ  xmm5,xmm5
            PUNPCKLQDQ  xmm7,xmm7
            ;- end blend prepare-------------

            MOV         EAX,[XP1]   ; ligne en dehors de la fenetre ?
            MOV         EBX,[XP2]
            MOV         EDX,EAX
            CMP         EAX,EBX
            JL          .VMaxX
            XCHG        EAX,EBX
.VMaxX:     CMP         EAX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
            SUB         EBX,EAX
            MOV         ESI,EBX    ;calcul de abs(x2-x1)

            MOV         EAX,[YP1]
            MOV         EBX,EDI; [YP2]
            MOV         ECX,EAX
            CMP         EAX,EBX
            JL          .VMaxY
            XCHG        EAX,EBX
.VMaxY:     CMP         EAX,[MaxY]
            JG          .FinLine
            CMP         EBX,[MinY]
            JL          .FinLine       ; fin du test
            SUB         EBX,EAX
            MOV         EDI,EBX        ;  abs(y2-y1)

            OR          EDI,EDI
            JZ          .cas4
.PasNegEDI: OR          ESI,ESI
            JZ          .cas2

            INC         ESI           ; abs(x2-x1)+1
            INC         EDI           ; abs(y2-y1)+1
            MOV         EAX,EDX         ; EDX = [XP1]
            MOV         EBX,[XP2]    ; cas 1 et cas 2
            CMP         EAX,EBX
            JL          .ClipMaxX
            XCHG        EAX,EBX
.ClipMaxX:  CMP         EAX,[MinX]
            JL          .Aj_1_2
            CMP         EBX,[MaxX]
            JG          .Aj_1_2
            MOV         EAX,ECX         ; ECX = [YP1]
            MOV         EBX,[YP2]
            CMP         EAX,EBX
            JL          .ClipMaxY
            XCHG        EAX,EBX
.ClipMaxY:  CMP         EAX,[MinY]
            JL          .Aj_1_2
            CMP         EBX,[MaxY]
            JG          .Aj_1_2
            JMP         .PasAj_1_2
.Aj_1_2:    MOV         EBX,EDX         ; EDX = [XP1]
            MOV         ESI,[XP2]
            MOV         EDI,[YP2]
            CMP         EBX,ESI
            JL          .MaxAj1_2X
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
            CMP         EBX,[MinX]
            JNL         .PasAjX12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,[MinX]
            SUB         EAX,EBX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EBX,[MinX]
            ADD         ECX,EAX
.PasAjX12:  CMP         ESI,[MaxX]
            JNG         .PasAjM12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            OR          ESI,ESI
            JZ          .FinLine
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,ESI
            SUB         EAX,[MaxX]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ESI,[MaxX]
            SUB         EDI,EAX
.PasAjM12:  CMP         ECX,EDI
            JL          .MaxAj1_2Y
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2Y: CMP         ECX,[MaxY]
            JG          .FinLine
            CMP         EDI,[MinY]
            JL          .FinLine
    ;*********Ajustement des Y
            CMP         ECX,[MinY]
            JNL         .PasAjY12
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP
            MOV         EDX,EAX
            MOV         EAX,[MinY]
            SUB         EAX,ECX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ECX,[MinY]
            ADD         EBX,EAX
            CMP         EBX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
.PasAjY12:  CMP         EDI,[MaxY]
            JNG         .PasAjY12X
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP
            MOV         EDX,EAX
            MOV         EAX,EDI
            SUB         EAX,[MaxY]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EDI,[MaxY]
            SUB         ESI,EAX
.PasAjY12X:
            MOV         [XP1],EBX
            MOV         [YP1],ECX
            MOV         [XP2],ESI
            MOV         [YP2],EDI
            SUB         ESI,EBX
            SUB         EDI,ECX
            OR          ESI,ESI

            JZ          .cas2
            JNS         .PasNegESI2
            NEG         ESI
.PasNegESI2:
            OR              EDI,EDI
            JZ          .cas4
            JNS         .PasNegEDI2
            NEG         EDI
.PasNegEDI2:
.PasAj_1_2: CMP         ESI,EDI
            JB          .cas2
;*********CAS 1:  (DX > DY)***************************************************
.cas1:
            MOV         EAX,[XP1]
            MOV         EBP,[ScanLine] ; plus
            CMP         EAX,[XP2]
            JL          .PasSwap1
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap1:
            MOV         ESI,[XP2]
            MOV         EAX,[YP2]
            SUB         ESI,[XP1]
            SUB         EAX,[YP1]
            MOV         EDI,EBP  ;[ScanLine]
            JNS         .pstvDyCas1
            NEG         EAX ; abs(deltay)
            JMP         SHORT .ngtvDyCas1
.pstvDyCas1:
            NEG         EBP ; = -[ScanLine] as ascendent y Axis
.ngtvDyCas1:
            INC         EAX
            MOV         EBX,1 << Prec ; EBX = cpt Dbrd
            SHL         EAX,Prec
            INC         ESI ; deltaX + 1
            CDQ
            IDIV        ESI
            IMUL        EDI,[YP1]
            MOV         ECX,ESI ; ECX = deltaX = number pixels
            NEG         EDI    ; // Y Axis  ascendent
            MOV         ESI,[XP1]
            MOV         EDX,EAX ; EDX = pnt
            LEA         EDI,[EDI+ESI*2] ; 2 time cause 16bpp
            ;MOV        EAX,[clr]
            ADD         EDI,[vlfb]
            MOV         ESI,1 << Prec
ALIGN 4
.lp_line1:

            PINSRW      xmm0,[EDI],0
            SUB         EBX,EDX
            MOVDQA      xmm1,xmm0 ; B
            MOVDQA      xmm2,xmm0  ; R
            @SolidBlndQ
            PEXTRW      [EDI],xmm0,0
            JA          .no_debor1 ; EDI >0
            ADD         EBX,ESI ; +  (1 << Prec)
            ADD         EDI,EBP  ; EDI + = directional ScanLine
.no_debor1:
            DEC         ECX
            LEA         EDI,[EDI+2] ; EDI + 2
            JNZ         .lp_line1

            JMP         .FinLine
;*********CAS 2:  (DY > DX)***************************************************
.cas2:
            OR          EDI,EDI
            MOV         EAX,[YP1]
            JZ          .cas5
            CMP         EAX,[YP2]
            JL          .PasSwap2
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap2:
            OR          ESI,ESI
            JNZ         .noClipVert
            MOV         EAX,[MinY]
            MOV         EBX,[MaxY]
            CMP         EAX,[YP1]
            JLE         .sava21
            MOV         [YP1],EAX
.sava21:
            CMP         EBX,[YP2]
            JGE         .sava22
            MOV         [YP2],EBX
.sava22:
.noClipVert:
            MOV         EAX,[XP2]
            MOV         ESI,[YP2]
            SUB         EAX,[XP1]
            JNS         .pstvDxCas2
            DEC         EAX
            JMP         SHORT .ngtvDxCas2
.pstvDxCas2:
            INC         EAX
.ngtvDxCas2:
            SUB         ESI,[YP1]
            SHL         EAX,Prec
            INC         ESI
            MOV         EDI,[YP1]
            CDQ
            IMUL        EDI,[NegScanLine] ; * -ScanLine
            IDIV        ESI
            MOV         EBP,[XP1]
            MOV         ECX,ESI ; ECX = deltaY = number pixels
            MOV         EDX,EAX ; pente in EDX

        ; start adress
            LEA         EDI,[EDI+EBP*2] ; ; add xp1 2 times as 16 bpp
            XOR         EBX,EBX ; accum in EBX
            ADD         EDI,[vlfb]
            OR          EDX,EDX
            MOV         EBP,[NegScanLine]
            ;MOV        EAX,[clr] ; draw color
            JNS         SHORT .line2_pstvPnt
            MOV         EBX,((1<<Prec)-1)
.line2_pstvPnt:
ALIGN 4
.lp_line2:
            MOV         ESI,EBX
            SAR         ESI,Prec
            ADD         EBX,EDX ; + pnt
            PINSRW      xmm0,[EDI+ESI*2],0 ; B
            MOVDQA      xmm1,xmm0 ; G
            MOVDQA      xmm2,xmm0  ; R
            @SolidBlndQ
            PEXTRW      [EDI+ESI*2],xmm0,0
            DEC         ECX
            LEA         EDI,[EDI+EBP]     ;  Axe Y Montant -ResH
            JNZ         SHORT .lp_line2

            JMP         .FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:
            MOV         ECX,ESI
            MOV         EAX,[XP1]
            CMP         EAX,[XP2]
            JL          .PasSwap4
            ;MOV        EAX,[XP1]
            MOV         EBX,[XP2]
            MOV         [XP1],EBX
            MOV         [XP2],EAX
.PasSwap4:
            MOV         EAX,[MinX]
            CMP         EAX,[XP1]
            JLE         .sava41
            MOV         [XP1],EAX
.sava41:
            MOV         EAX,[MaxX]
            CMP         EAX,[XP2]
            JGE         .sava42
            MOV         [XP2],EAX
.sava42:
            MOV         ESI,[XP2]
            SUB         ESI,[XP1]
            OR          ESI,ESI
            JZ          .cas5
            MOV         EDI,[YP1]
            INC         ESI
            IMUL        EDI,[NegScanLine]
            MOV         EBP,[XP1]
            ADD         EDI,[vlfb]
            XOR         ECX,ECX
            LEA         EDI,[EDI+EBP*2]
            @SolidBlndHLine16
            JMP         .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
            MOV         EDI,[NegScanLine]
            IMUL        EDI,[YP1]
            MOV         EDX,[XP1]
            ADD         EDI,[vlfb]
            PINSRW      xmm0,[EDI+EDX*2],0 ; B
            MOVDQA      xmm1,xmm0 ; G
            MOVDQA      xmm2,xmm0  ; R
            @SolidBlndQ
            PEXTRW      [EDI+EDX*2],xmm0,0

.FinLine:
            POP         ESI
            POP         EDI
            POP         EBX

    RETURN


ALIGN 32
linemapblnd16:
    ARG     LMBX16P1, 4, LMBY16P1, 4, LMBX16P2, 4, LMBY16P2, 4, lnMBCol16, 4, LMB16Map, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EAX,[EBP+LMBX16P1]
            MOV         EBX,[EBP+LMBX16P2]
            MOV         ESI,[EBP+LMBY16P1]
            MOV         EDI,[EBP+LMBY16P2]
            MOV         ECX,[EBP+LMB16Map]

            MOV         [XP1],EAX
            MOV         [XP2],EBX
            MOV         [YP1],ESI
            MOV         EAX,[EBP+lnMBCol16]
            MOV         [YP2],EDI
            ;MOV        [clr],ESI
            MOV         [Plus2],ECX
            JMP         SHORT LineMapBlnd16.DoLine16

ALIGN 32
LineMapBlnd16:
    ARG     MapB16PtrP1, 4, MapB16PtrP2, 4, MapB16Col, 4, LineB16Map, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EDX,[EBP+MapB16PtrP1]
            MOV         ECX,[EBP+MapB16PtrP2]

            MOV         EAX,[EDX]   ; X1
            MOV         EBX,[ECX]   ; X2
            MOV         ESI,[EDX+4] ; Y1
            MOV         EDI,[ECX+4] ; Y2
            MOV         [XP1],EAX   ; X1
            MOV         [XP2],EBX   ; X2
            MOV         [YP1],ESI   ; Y1
            MOV         EAX,[EBP+MapB16Col]
            MOV         [YP2],EDI   ; Y2
            MOV         EBX,[EBP+LineB16Map]
            ;MOV        [clr],EAX
            MOV         [Plus2],EBX
            ; blend precomputing-------------
            ;MOV        EAX,[clr] ;
.DoLine16:  MOV         EBX,EAX ;
            MOV         ECX,EAX ;
            MOV         EDX,EAX ;
            AND         EBX,[QBlue16Mask] ; EBX = Bclr16 | Bclr16
            SHR         EAX,24
            AND         ECX,[QGreen16Mask] ; ECX = Gclr16 | Gclr16
            AND         AL,BlendMask ; remove any ineeded bits
            JZ          .FinLine ; nothing 0 is the source
            AND         EDX,[QRed16Mask] ; EDX = Rclr16 | Rclr16
            XOR         AL,BlendMask ; 31-blendsrc
            MOV         BP,AX
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
            MOVD        xmm7,EBP
            PSHUFLW     xmm5,xmm5,0
            PSHUFLW     xmm7,xmm7,0
            PUNPCKLQDQ  xmm3,xmm3
            PUNPCKLQDQ  xmm4,xmm4
            PUNPCKLQDQ  xmm5,xmm5
            PUNPCKLQDQ  xmm7,xmm7
            ;- end blend prepare-------------

            MOV         EAX,[XP1]   ; ligne en dehors de la fenetre ?
            MOV         EBX,[XP2]
            MOV         EDX,EAX
            CMP         EAX,EBX
            JL          .VMaxX
            XCHG        EAX,EBX
.VMaxX:     CMP         EAX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
            SUB         EBX,EAX
            MOV         ESI,EBX    ;calcul de abs(x2-x1)

            MOV         EAX,[YP1]
            MOV         EBX,EDI; [YP2]
            MOV         ECX,EAX
            CMP         EAX,EBX
            JL          SHORT .VMaxY
            XCHG        EAX,EBX
.VMaxY:     CMP         EAX,[MaxY]
            JG          .FinLine
            CMP         EBX,[MinY]
            JL          .FinLine       ; fin du test
            SUB         EBX,EAX
            MOV         EDI,EBX        ;  abs(y2-y1)

            OR          EDI,EDI
            JZ          .cas4
.PasNegEDI: OR          ESI,ESI
            JZ          .cas2

            INC         ESI           ; abs(x2-x1)+1
            INC         EDI           ; abs(y2-y1)+1
            MOV         EAX,EDX         ; EDX = [XP1]
            MOV         EBX,[XP2]    ; cas 1 et cas 2
            CMP         EAX,EBX
            JL          SHORT .ClipMaxX
            XCHG        EAX,EBX
.ClipMaxX:  CMP         EAX,[MinX]
            JL          SHORT .Aj_1_2
            CMP         EBX,[MaxX]
            JG          SHORT .Aj_1_2
            MOV         EAX,ECX         ; ECX = [YP1]
            MOV         EBX,[YP2]
            CMP         EAX,EBX
            JL          SHORT .ClipMaxY
            XCHG        EAX,EBX
.ClipMaxY:  CMP         EAX,[MinY]
            JL          SHORT .Aj_1_2
            CMP         EBX,[MaxY]
            JG          SHORT .Aj_1_2
            JMP         .PasAj_1_2
.Aj_1_2:    MOV         EBX,EDX         ; EDX = [XP1]
            MOV         ESI,[XP2]
            MOV         EDI,[YP2]
            CMP         EBX,ESI
            JL          SHORT .MaxAj1_2X
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2X:
;*********Ajustement des X
            CMP         EBX,[MinX]
            JNL         SHORT .PasAjX12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,[MinX]
            SUB         EAX,EBX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EBX,[MinX]
            ADD         ECX,EAX
.PasAjX12:  CMP         ESI,[MaxX]
            JNG         SHORT .PasAjM12
            MOV         EAX,EDI
            SUB         EAX,ECX
            SAL         EAX,Prec
            SUB         ESI,EBX
            OR          ESI,ESI
            JZ          .FinLine
            CDQ
            IDIV        ESI
            ADD         ESI,EBX
            MOV         EDX,EAX
            MOV         EAX,ESI
            SUB         EAX,[MaxX]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ESI,[MaxX]
            SUB         EDI,EAX
.PasAjM12:  CMP         ECX,EDI
            JL          SHORT .MaxAj1_2Y
            XCHG        EBX,ESI
            XCHG        ECX,EDI
.MaxAj1_2Y: CMP         ECX,[MaxY]
            JG          .FinLine
            CMP         EDI,[MinY]
            JL          .FinLine
;*********Ajustement des Y
            CMP         ECX,[MinY]
            JNL         SHORT .PasAjY12
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI ; sauve ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP ; rest ESI
            MOV         EDX,EAX
            MOV         EAX,[MinY]
            SUB         EAX,ECX
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         ECX,[MinY]
            ADD         EBX,EAX
            CMP         EBX,[MaxX]
            JG          .FinLine
            CMP         EBX,[MinX]
            JL          .FinLine
.PasAjY12:  CMP         EDI,[MaxY]
            JNG         SHORT .PasAjY12X
            MOV         EAX,ESI
            SUB         EAX,EBX
            MOV         EBP,ESI ; sauve ESI
            SAL         EAX,Prec
            MOV         ESI,EDI
            SUB         ESI,ECX
            CDQ
            IDIV        ESI
            MOV         ESI,EBP ; rest ESI
            MOV         EDX,EAX
            MOV         EAX,EDI
            SUB         EAX,[MaxY]
            IMUL        EAX,EDX
            SAR         EAX,Prec
            MOV         EDI,[MaxY]
            SUB         ESI,EAX
.PasAjY12X:
            MOV         [XP1],EBX
            MOV         [YP1],ECX
            MOV         [XP2],ESI
            MOV         [YP2],EDI
            SUB         ESI,EBX
            SUB         EDI,ECX
            OR          ESI,ESI

            JZ          .cas2
            JNS         SHORT .PasNegESI2
            NEG         ESI
.PasNegESI2:
            OR          EDI,EDI
            JZ          .cas4
            JNS         SHORT .PasNegEDI2
            NEG         EDI
.PasNegEDI2:
.PasAj_1_2: CMP         ESI,EDI
            JB          .cas2

;*********CAS 1:  (DX > DY)***************************************************
.cas1:
            MOV         EAX,[XP1]
            MOV         EBP,[ScanLine] ; plus
            CMP         EAX,[XP2]
            JL          SHORT .PasSwap1
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap1:
            MOV         ESI,[XP2]
            MOV         EAX,[YP2]
            SUB         ESI,[XP1]
            SUB         EAX,[YP1]
            MOV         EDI,[NegScanLine]
            JNS         SHORT .pstvDyCas1
            NEG         EAX ; abs(deltay)
            JMP         SHORT .ngtvDyCas1
.pstvDyCas1:
            NEG         EBP ; = -[ScanLine] as ascendent y Axis
.ngtvDyCas1:
            INC         EAX
            MOV         EBX,[Plus2]  ; Line MAP
            SHL         EAX,Prec
            INC         ESI ; deltaX + 1
            CDQ
            IDIV        ESI
            MOV         ECX,[XP1]
            IMUL        EDI,[YP1]
            MOV         EDX,EAX ; EDX = pnt
            LEA         EDI,[EDI+ECX*2] ; += 2*XP1 as 16bpp
            ;MOV        EAX,[clr]
            MOV         ECX,ESI ; ECX = deltaX = number pixels
            ADD         EDI,[vlfb]
            MOV         ESI,1 << Prec ; EBX = cpt Dbrd
ALIGN 4
.lp_line1:
            TEST        BL,1
            JZ          SHORT .PasDrl1
            MOV         AX,[EDI]
            MOVD        xmm0,EAX ; B
            MOVD        xmm1,EAX ; G
            MOVD        xmm2,EAX  ; R
            @SolidBlndQ
            MOVD        EAX,xmm0
            MOV         [EDI],AX
.PasDrl1:
            SUB         ESI,EDX
            JA          SHORT .no_debor1 ; EDI >0
            ADD         ESI,(1 << Prec)
            ADD         EDI,EBP  ; EDI + = directional ScanLine
.no_debor1:
            ROR         EBX,1
            DEC         ECX
            LEA         EDI,[EDI+2] ; EDI + 2
            JNZ         .lp_line1

            JMP         .FinLine
;*********CAS 2:  (DY > DX)*************************************************
.cas2:
            OR          EDI,EDI
            MOV         EAX,[YP1]
            JZ          .cas5
            CMP         EAX,[YP2]
            JL          SHORT .PasSwap2
            PSHUFD      xmm0,[XP1],(1<<6) | (0<<4) | (3<<2) | (2) ; swap (XP1, YP1) and (XP2, YP2)
            MOVDQA      [XP1],xmm0
.PasSwap2:
            OR          ESI,ESI
            JNZ         SHORT .noClipVert
            MOV         EAX,[MinY]
            MOV         EBX,[MaxY]
            CMP         EAX,[YP1]
            JLE         SHORT .sava21
            MOV         [YP1],EAX
.sava21:
            CMP         EBX,[YP2]
            JGE         SHORT .sava22
            MOV         [YP2],EBX
.sava22:
.noClipVert:
            MOV         EAX,[XP2]
            MOV         ESI,[YP2]
            SUB         EAX,[XP1]
            JNS         SHORT .pstvDxCas2
            DEC         EAX
            JMP         SHORT .ngtvDxCas2
.pstvDxCas2:
            INC         EAX
.ngtvDxCas2:
            SUB         ESI,[YP1]
            SHL         EAX,Prec
            INC         ESI
            CDQ
            IDIV        ESI
            MOV         ECX,ESI ; ECX = deltaY = number pixels
            MOV         EBP,[XP1]

            ; start adress
            MOV         EDI,[YP1]
            MOV         EDX,EAX ; pente in EDX
            IMUL        EDI,[NegScanLine] ; * -ScanLine
            LEA         EDI,[EDI+EBP * 2] ; += XP1 * 2 as 16bpp
            XOR         EBP,EBP ; accum in EBX
            ADD         EDI,[vlfb]
            OR          EDX,EDX
            JNS         SHORT .line2_pstvPnt
            MOV         EBP,((1<<Prec)-1)
.line2_pstvPnt:
            ; draw color
            ;MOV        EBP,[clr]
            MOV         EBX,[Plus2] ; Line Map
ALIGN 4
.lp_line2:  MOV         ESI,EBP
            SAR         ESI,Prec
            ADD         EBP,EDX ; + pnt
            TEST        BL,1
            JZ          SHORT .PasDrPx2
            MOV         AX,[EDI+ESI*2]
            MOVD        xmm0,EAX ; B
            MOVD        xmm1,EAX ; G
            MOVD        xmm2,EAX  ; R
            @SolidBlndQ
            MOVD        EAX,xmm0
            MOV         [EDI+ESI*2],AX
.PasDrPx2:
            ROR         EBX,1
            ADD         EDI,[NegScanLine]    ;  Axe Y Montant -ResH
            DEC         ECX
            JNZ         .lp_line2

            JMP         .FinLine
;*******CAS 3 :  (DX=0)*****************************************************
;*******CAS 4 :  (DY=0)*****************************************************
.cas4:      MOV         ECX,ESI
            MOV         EAX,[XP1]
            CMP         EAX,[XP2]
            JL          .PasSwap4
            MOV         EAX,[XP1]
            MOV         EBX,[XP2]
            MOV         [XP1],EBX
            MOV         [XP2],EAX
.PasSwap4:  MOV         EAX,[MinX]
            CMP         EAX,[XP1]
            JLE         SHORT .sava41
            MOV         [XP1],EAX
.sava41:    MOV         EAX,[MaxX]
            CMP         EAX,[XP2]
            JGE         SHORT .sava42
            MOV         [XP2],EAX
.sava42:
            MOV         ESI,[XP2]
            SUB         ESI,[XP1]
            ;OR         ESI,ESI
            JZ          .cas5
            INC         ESI
            MOV         EDI,[YP1]
            MOV         ECX,[Plus2] ; Line Map
            IMUL        EDI,[NegScanLine]
            MOV         EBP,[XP1]
            ADD         EDI,[vlfb]
            MOV         EAX,[clr]
            LEA         EDI,[EDI+EBP*2]
.lp4:       TEST        CL,1
            JZ          SHORT .PasDrl4
            MOV         AX,[EDI]
            MOVD        xmm0,EAX ; B
            MOVD        xmm1,EAX ; G
            MOVD        xmm2,EAX  ; R
            @SolidBlndQ
            MOVD        EAX,xmm0
            MOV         [EDI],AX
.PasDrl4:
            ROR         ECX,1
            DEC         ESI
            LEA         EDI,[EDI+2] ; + 2 : 16 bpp
            JNZ         SHORT .lp4

            JMP     .FinLine
;********CAS 5 : (DX=0, DY=0)***********************************************
.cas5:
            TEST        BYTE [Plus2],1
            JZ          .FinLine

            MOV         EDI,[NegScanLine]
            MOV         ECX,[XP1]
            IMUL        EDI,[YP1]
            MOV         EDX,[clr]
            ADD         EDI,[vlfb]
            MOV         AX,[EDI+ECX*2]
            MOVD        xmm0,EAX ; B
            MOVD        xmm1,EAX ; G
            MOVD        xmm2,EAX  ; R
            @SolidBlndQ
            MOVD        EAX,xmm0
            MOV         [EDI+ECX*2],AX
.FinLine:
            POP         ESI
            POP         EDI
            POP         EBX
        RETURN

