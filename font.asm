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
GLOBAL  SetFONT, GetFONT, OutText16, WidthText, WidthPosText, PosWidthText

; GLOBAL Variables
GLOBAL  CurFONT, FntPtr, FntHaut, FntDistLgn, FntLowPos, FntHighPos
GLOBAL  FntSens, FntTab, FntX, FntY, FntCol


; EXTERN GLOBAL VARS
EXTERN  vlfb,rlfb,ResH,ResV, MaxX, MaxY, MinX, MinY, OrgY, OrgX, SizeSurf,OffVMem
EXTERN  BitsPixel, ScanLine,Mask,NegScanLine
EXTERN  QBlue16Mask, QGreen16Mask, QRed16Mask, WBGR16Mask
EXTERN  PntInitCPTDbrd
EXTERN  MaskB_RGB16, MaskG_RGB16, MaskR_RGB16, RGB16_PntNeg, Mask2B_RGB16, Mask2G_RGB16, Mask2R_RGB16
EXTERN  RGBDebMask_GGG, RGBDebMask_IGG, RGBDebMask_GIG, RGBDebMask_IIG, RGBDebMask_GGI, RGBDebMask_IGI, RGBDebMask_GII, RGBDebMask_III
EXTERN  RGBFinMask_GGG, RGBFinMask_IGG, RGBFinMask_GIG, RGBFinMask_IIG, RGBFinMask_GGI, RGBFinMask_IGI, RGBFinMask_GII, RGBFinMask_III


BITS 32

SECTION .text  ALIGN=32


;===========================
;=================== FONT ==

SetFONT:
    ARG SF, 4

            MOV         EAX,[EBP+SF]
            MOVDQU      xmm0,[EAX]
            MOVDQU      xmm1,[EAX+16]
            MOVDQA      [CurFONT],xmm0
            MOVDQA      [CurFONT+16],xmm1

    RETURN

GetFONT:
    ARG CF, 4

            MOV         EAX,[EBP+CF]
            MOVDQA      xmm0,[CurFONT]
            MOVDQA      xmm1,[CurFONT+16]
            MOVDQU      [EAX],xmm0
            MOVDQU      [EAX+16],xmm1

    RETURN

WidthText:
    ARG LStr, 4
            PUSH        EBX
            PUSH        ESI

            MOV         EBX,[FntPtr]
            XOR         ECX,ECX
            OR          EBX,EBX
            JZ          .FinLargText
            MOV         ESI,[EBP+LStr]
            XOR         EAX,EAX
.BcCalcLarg:
            LODSB
            OR          AL,AL
            JZ          .FinLargText
            CMP         AL,13
            JZ          .FinLargText
            CMP         AL,10
            JZ          .FinLargText
            CMP         AL,9     ; Tab
            JNE         .PasTrtTab
            MOV         AL,32
            MOVSX       EDX,BYTE [EBX+EAX*8+4] ; space
            XOR         EAX,EAX
            MOV         AL,[FntTab]
            IMUL        EDX,EAX
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.PasTrtTab:
            MOVSX       EDX,BYTE [EBX+EAX*8+4]
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.FinLargText:
            OR          ECX,ECX
            JNS         .Positiv
            NEG         ECX
.Positiv:
            MOV         EAX,ECX
            OR          EAX,EAX
            JZ          .ZeroRien
            DEC         EAX
.ZeroRien:
            POP         ESI
            POP         EBX
    RETURN

WidthPosText:
    ARG LPStr, 4, LPPos, 4

            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EBX,[FntPtr]
            XOR         ECX,ECX
            OR          EBX,EBX
            JZ          .FinLargText
            MOV         ESI,[EBP+LPStr]
            MOV         EDI,[EBP+LPPos]
            XOR         EAX,EAX
            OR          EDI,EDI
            JZ          .FinLargText
            ADD         EDI,ESI
.BcCalcLarg:
            XOR         EAX,EAX
            CMP         EDI,ESI
            JBE         .FinLargText
            LODSB
            OR          AL,AL
            JZ          .FinLargText
            CMP         AL,13
            JE          .FinLargText
            CMP         AL,10
            JE          .FinLargText
            CMP         AL,9     ; Tab
            JNE         .PasTrtTab
            MOV         AL,32
            MOVSX       EDX,BYTE [EBX+EAX*8+4] ; space
            XOR         EAX,EAX
            MOV         AL,[FntTab]
            IMUL        EDX,EAX
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.PasTrtTab:
            MOVSX       EDX,BYTE [EBX+EAX*8+4]
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.FinLargText:
            OR          ECX,ECX
            JNS         .Positiv
            NEG         ECX
.Positiv:
            MOV         EAX,ECX
            OR          EAX,EAX
            JZ          .ZeroRien
            DEC         EAX
.ZeroRien:

            POP         ESI
            POP         EDI
            POP         EBX
    RETURN

PosWidthText:
    ARG PLStr, 4, PLLarg, 4
            PUSH        EBX
            PUSH        EDI
            PUSH        ESI

            MOV         EBX,[FntPtr]
            XOR         ECX,ECX
            OR          EBX,EBX
            JZ          .FinPosLargText
            MOV         ESI,[EBP+PLStr]
            XOR         EDI,EDI
.BcCalcLarg:
            XOR         EAX,EAX
            CMP         ECX,[EBP+PLLarg]
            JAE         .FinPosLargText
            LODSB
            INC         EDI
            OR          AL,AL
            JZ          .FinPosLargText
            CMP         AL,13
            JE          .FinPosLargText
            CMP         AL,10
            JE          .FinPosLargText
            CMP         AL,9     ; Tab
            JNE         .PasTrtTab
            MOV         AL,32
            MOVSX       EDX,BYTE [EBX+EAX*8+4] ; space
            XOR         EAX,EAX
            MOV         AL,[FntTab]
            IMUL        EDX,EAX
            OR          EDX,EDX
            JS          .NegTab
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.NegTab:
            SUB         ECX,EDX
            JMP         SHORT .BcCalcLarg
.PasTrtTab:
            MOVSX       EDX,BYTE [EBX+EAX*8+4]
            OR          EDX,EDX
            JS          .NegNorm
            ADD         ECX,EDX
            JMP         SHORT .BcCalcLarg
.NegNorm:
            SUB         ECX,EDX
            JMP         SHORT .BcCalcLarg

.FinPosLargText:
            OR          EDI,EDI
            JZ          .PosZero
            DEC         EDI
.PosZero:
            MOV         EAX,EDI

            POP         ESI
            POP         EDI
            POP         EBX
    RETURN


ALIGN 32
OutText16:
    ARG Str16, 4
            PUSH        ESI
            PUSH        EBX
            PUSH        EDI

            MOV         ESI,[EBP+Str16]
            XOR         EAX,EAX
            MOV         EBX,[FntPtr]
.BcOutChar:
            OR          AL,[ESI]
            JZ          .FinOutText
            INC         ESI
            PUSH        EBX
            PUSH        ESI
;**************** Affichage et traitement **********************************
;***************************************************************************
            CMP         AL,13    ;** Debut Cas Special
            MOVSX       ESI,BYTE [EBX+EAX*8+4] ; PlusX
            JE          .DebLigne
            XOR         EDX,EDX
            CMP         AL,10
            MOV         DL,[EBX+EAX*8+7] ;Largeur
            JE          .DebNextLigne
            XOR         ECX,ECX
            CMP         AL,9
            MOV         CL,[EBX+EAX*8+6] ; Haut
            JE          .TabCar  ;** Fin   Cas Special
            MOVSX       EDI,BYTE [EBX+EAX*8+5] ; PlusLgn
            MOV         [ChLarg],EDX
            MOV         [ChPlusX],ESI
            MOVD        xmm6,[EBX+EAX*8]        ; PtrDat
            OR          ESI,ESI
            MOV         [ChPlusLgn],EDI
            MOV         [ChHaut],ECX
            JNS         .GauchDroit
            JZ          SHORT .RienZero1
            LEA         EAX,[ESI+1]
            ADD         [FntX],EAX
.GauchDroit:
.RienZero1:
            MOV         EBP,[FntX]  ; MinX
            ADD         EDI,[FntY]  ; MinY
            LEA         EBX,[EBP+EDX-1] ; MaxX: EBX=MinX+Larg-1
            LEA         ESI,[EDI+ECX-1] ; MaxY: ESI=MinY+Haut-1

            CMP         EBX,[MaxX]
            JG          .CharClip
            CMP         ESI,[MaxY]
            JG          .CharClip
            CMP         EBP,[MinX]
            JL          .CharClip
            CMP         EDI,[MinY]
            JL          .CharClip
;****** trace caractere IN *****************************
.CharIn:
            MOV         ECX,[ScanLine]
            MOV         EBP,EDX ;Largeur
            IMUL        EDI,ECX
            LEA         ECX,[ECX+EDX*2]
            NEG         EDI
            MOV         [ChPlus],ECX
            ADD         EDI,[FntX]
            ADD         EDI,[FntX]
            MOV         EDX,[ChHaut]
            ADD         EDI,[vlfb]
            XOR         EAX,EAX
            MOVD        ESI,xmm6
            MOV         EAX,[FntCol]
.LdNext:
            MOV         EBX,[ESI]
            MOV         CL,32
            ADD         ESI,BYTE 4
;ALIGN 4
.BcDrCarHline:
            BT          EBX,0
            JNC         SHORT .PasDrPixel
            MOV         [EDI],AX
.PasDrPixel:
            SHR         EBX,1
            DEC         EBP
            LEA         EDI,[EDI+2]
            JZ          SHORT .FinDrCarHline
            DEC         CL
            JNZ         SHORT .BcDrCarHline
            JZ          .LdNext
;ALIGN 4
.FinDrCarHline:
            MOV         EBX,[ESI]
            SUB         EDI,[ChPlus]
            MOV         CL,32
            LEA         ESI,[ESI+4]
            DEC         DL
            MOV         EBP,[ChLarg]
            JNZ         .BcDrCarHline
            JMP         .FinDrChar
;****** Trace Caractere Clip ***************************
.CharClip:
            CMP         EBX,[MinX]
            JL          .FinDrChar
            CMP         ESI,[MinY]
            JL          .FinDrChar
            CMP         EBP,[MaxX]
            JG          .FinDrChar
            CMP         EDI,[MaxY]
            JG          .FinDrChar
            ; traitement MaxX********************************************
            CMP         EBX,[MaxX] ; MaxX>MaxX
            MOV         EAX,EBX
            JLE         .PasApPlus
            SUB         EAX,[MaxX] ; DXAp = EAX = MaxX-MaxX
            SUB         EDX,EAX   ; EDX = Larg-DXAp
            CMP         EAX,BYTE 32
            JL          SHORT .PasApPlus
            MOV         DWORD [ChApPlus],4
            JMP         SHORT .ApPlus
.PasApPlus:
            XOR         EAX,EAX
            MOV         [ChApPlus],EAX
.ApPlus:
            ; traitement MinX********************************************
            MOV         EAX,[MinX]
            SUB         EAX,EBP
            JLE         .PasAvPlus
            SUB         EDX,EAX

            CMP         EAX,BYTE 32
            JL          .PasAvPlus2
            MOV         DWORD [ChAvPlus],4
            SUB         AL,32
            MOV         AH,32
            MOV         [ChAvDecal],AL
            SUB         AH,AL
            MOV         [ChNbBitDat],AH
            JMP         SHORT .AvPlus
.PasAvPlus2:
            MOV         AH,32
            MOV         [ChAvDecal],AL
            SUB         AH,AL
            MOV         [ChNbBitDat],AH
            XOR         EAX,EAX
            MOV         [ChAvPlus],EAX
            JMP         SHORT .AvPlus
.PasAvPlus:
            XOR         EAX,EAX
            MOV         BYTE [ChNbBitDat],32
            MOV         [ChAvPlus],EAX
            MOV         [ChAvDecal],AL
.AvPlus:
    ; handling MaxY********************************************
            CMP         ESI,[MaxY] ; MaxY>MaxY
            MOV         EAX,ESI
            JLE         .PasSupMaxY
            SUB         EAX,[MaxY] ; DY = EAX = MaxY-MaxY
            SUB         ECX,EAX   ; ECX = Haut-DY
.PasSupMaxY:
    ; handling MinY********************************************
            MOV         EAX,[MinY]
            SUB         EAX,EDI
            JLE         .PasInfMinY
            SUB         ECX,EAX
            MOV         EDI,[MinY]
            CMP         DWORD [ChLarg],BYTE 32
            JLE         .Larg1DD
.Larg2DD:
            IMUL        EAX,BYTE 8
            MOVD        xmm7,EAX
            PADDD       xmm6,xmm7
            JMP         SHORT .PasInfMinY
.Larg1DD:
            IMUL        EAX,BYTE 4
            MOVD        xmm7,EAX
            PADDD       xmm6,xmm7
.PasInfMinY:
            MOV         [ChHaut],ECX
            MOV         [ChLarg],EDX
;************************************************
            MOV         ECX,[ScanLine]
            MOV         EBP,EDX ;Largeur
            IMUL        EDI,ECX
            XOR         EAX,EAX
            LEA         ECX,[ECX+EDX*2] ;
            MOV         AL,[ChAvDecal]
            NEG         EDI
            MOV         [ChPlus],ECX
            ADD         EDI,[FntX]
            ADD         EDI,[FntX]  ; 2*FntX 16bpp
            LEA         EDI,[EDI+EAX*2]      ; EDI +=2*ChAvDecal
            MOV         EDX,[ChHaut]
            ADD         EDI,[vlfb]
            MOVD        ESI,xmm6

            MOV         EAX,[FntCol]  ;*************
            ADD         ESI,[ChAvPlus]
            MOV         EBX,[ESI]
            MOV         CL,[ChAvDecal]
            MOV         CH,[ChNbBitDat]
            ADD         ESI,BYTE 4
            SHR         EBX,CL
            JMP         SHORT .CBcDrCarHline

.CLdNext:
            MOV         EBX,[ESI]
            MOV         CH,32
            ADD         ESI,BYTE 4
;ALIGN 4
.CBcDrCarHline:
            BT          EBX,0
            JNC         SHORT .CPasDrPixel
            MOV         [EDI],AX
.CPasDrPixel:
            SHR         EBX,1
            DEC         EBP
            LEA         EDI,[EDI+2]
            JZ          SHORT .CFinDrCarHline
            DEC         CH
            JNZ         SHORT .CBcDrCarHline
            JZ          SHORT .CLdNext
;ALIGN 4
.CFinDrCarHline:
            ADD         ESI,[ChApPlus]
            SUB         EDI,[ChPlus]
            ADD         ESI,[ChAvPlus]
            MOV         CL,[ChAvDecal]
            MOV         EBX,[ESI]
            MOV         CH,[ChNbBitDat]
            SHR         EBX,CL
            LEA         ESI,[ESI+4]
            DEC         DL
            MOV         EBP,[ChLarg]
            JNZ         .CBcDrCarHline

.FinDrChar:;********************************************
            MOV         ESI,[ChPlusX]
            OR          ESI,ESI
            JS          SHORT .DroitGauch
            JZ          SHORT .RienZero2
            ADD         [FntX],ESI
.DroitGauch:
.RienZero2:
            OR          ESI,ESI
            JNS         SHORT .GauchDroit2
            JZ          .RienZero3
            MOV         EAX,[FntX]
            DEC         EAX
            MOV         [FntX],EAX
.GauchDroit2:
.RienZero3:
            JMP         SHORT .Norm

.DebNextLigne:
            MOVZX       EAX,BYTE [FntDistLgn] ;***debut trait Cas sp
            MOV         EBX,[FntY]
            SUB         EBX,EAX
            MOV         [FntY],EBX
.DebLigne:
            CMP         BYTE [FntSens], 0
            JE          SHORT .GchDrt
            MOV         EBX,[MaxX]
            JMP         SHORT .DrtGch
.GchDrt:
            MOV         EBX,[MinX]
.DrtGch:
            MOV         [FntX],EBX
            JMP         SHORT .Norm
.TabCar:
            MOV         AL,32      ; TAB
            MOV         ESI,[FntX]
            MOVZX       ECX,BYTE [FntTab]
            MOVSX       EAX,BYTE [EBX+EAX*8+4] ; PlusX
            IMUL        ECX,EAX
            ADD         ESI,ECX
            MOV         [FntX],ESI ;***********fin trait Cas sp
.Norm:
            XOR         EAX,EAX
            POP         ESI
            POP         EBX
            JMP         .BcOutChar
.FinOutText:
            POP         EDI
            POP         EBX
            POP         ESI
    RETURN





SECTION .bss   ALIGN=32

CurFONT:
FntPtr            RESD  1
FntHaut           RESB  1
FntDistLgn        RESB  1
FntLowPos         RESB  1
FntHighPos        RESB  1
FntSens           RESB  1
FntTab            RESB  3 ; 2 DB reserved
FntX              RESD  1
FntY              RESD  1
FntCol            RESD  1
FntResv           RESD  2 ;---------------------
ChHaut            RESD  1
ChLarg            RESD  1
ChPlus            RESD  1
ChPlusX           RESD  1
ChPlusLgn         RESD  1
ChAvPlus          RESD  1
ChApPlus          RESD  1
ChAvDecal         RESB  1
ChNbBitDat        RESB  1
ChResvW           RESW  1;-----------------------
clr               RESD  1


