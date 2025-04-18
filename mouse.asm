;   Dust Ultimate Game Library (DUGL)
;   Copyright (C) 2025  Fakhri Feki
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
GLOBAL iSetMouseRView, GetMouseRView, iSetMouseOrg, iSetMousePos
GLOBAL iEnableMsEvntsStack, iDisableMsEvntsStack, iClearMsEvntsStack, iGetMsEvent, iPushMsEvent

; GLOBAL DATA*****************************************************************
GLOBAL MsX,MsY,MsZ,MsButton,MsSpeedHz,MsSpeedVt,MsAccel


; Mouse Event Structure **************************
        struc MouseEvent
.MsX        resd    1
.MsY        resd    1
.MsZ        resd    1
.MsButton   resd    1
.MsEvents   resd    1
.Size
        endstruc

SECTION .text
ALIGN 32
[BITS 32]

iSetMouseRView:
    ARG V1, 4

        PUSH    EDI
        PUSH    ESI
        PUSH    EBX

        MOV     ESI,[EBP+V1]
        MOV     EDI,MsOrgX
        MOV     ECX,6
        REP     MOVSD
        MOV     EAX,[MsX]
        MOV     EBX,[MsY]
        MOV     ECX,[MsMaxX]
        MOV     EDX,[MsMaxY]
        CMP     EAX,ECX
        JLE     .MsPasSupMxX
        MOV     EAX,ECX
.MsPasSupMxX:
        CMP     EBX,EDX
        JLE     .MsPasSupMxY
        MOV     EBX,EDX
.MsPasSupMxY:
        MOV     ECX,[MsMinX]
        MOV     EDX,[MsMinY]
        CMP     EAX,ECX
        JGE     .MsPasInfMnX
        MOV     EAX,ECX
.MsPasInfMnX:
        CMP     EBX,EDX
        JGE     .MsPasInfMnY
        MOV     EBX,EDX
.MsPasInfMnY:
        MOV     [MsY],EBX
        MOV     [MsX],EAX

        POP     EBX
        POP     ESI
        POP     EDI
    RETURN

GetMouseRView:
    ARG V2, 4
        PUSH        ESI
        PUSH        EDI

        MOV         ECX,6
        MOV         ESI,MsOrgX
        MOV         EDI,[EBP+V2]
        REP         MOVSD

        POP         EDI
        POP         ESI
    RETURN

iSetMouseOrg:
    ARG MsXOrg, 4, MsYOrg, 4

        MOV         EAX,[EBP+MsXOrg]
        MOV         ECX,[EBP+MsYOrg]
        MOV         EDX,EAX
        MOV         EBP,ECX

        SUB         EAX,[MsOrgX] ; DX
        SUB         ECX,[MsOrgY] ; DY
        SUB         [MsMaxX],EAX
        SUB         [MsMinX],EAX
        SUB         [MsMaxY],ECX
        SUB         [MsMinY],ECX
        MOV         [MsOrgX],EDX
        MOV         [MsOrgY],EBP

    RETURN

iSetMousePos:
    ARG MouseX, 4, MouseY, 4

        MOV     EAX,[EBP+MouseX]
        MOV     ECX,[MsMaxY]
        SUB     ECX,[EBP+MouseY]
        SUB     EAX,[MsOrgX]

        CMP     EAX,[MsMaxX]
        JLE     .MsPasSupMxX
        MOV     EAX,[MsMaxX]
.MsPasSupMxX:
        CMP     ECX,[MsMaxY]
        JLE     .MsPasSupMxY
        MOV     ECX,[MsMaxY]
.MsPasSupMxY:
        CMP     EAX,[MsMinX]
        JGE     .MsPasInfMnX
        MOV     EAX,[MsMinX]
.MsPasInfMnX:
        CMP     ECX,[MsMinY]
        JGE     .MsPasInfMnY
        MOV     ECX,[MsMinY]
.MsPasInfMnY:
        MOV     [MsX],EAX
        MOV     [MsY],ECX

    RETURN

iPushMsEvent:
    ARG MsEventID, 4

        PUSH    EDI
        PUSH    ESI
        PUSH    EBX

        MOV     EAX,[MsStackEnable]
        OR      EAX,EAX
        JZ      .EndMs  ; Mouse Evt Stack Disabled
        MOV     ECX,[MsStackNbElt]
        CMP     ECX,256
        JGE     .EndMs ; Mouse Evt Stack Full
        ADD     ECX,[MsStackStart]
        AND     ECX,0xFF ; rotate value 256->0
        IMUL    ECX,MouseEvent.Size
        LEA     EDI,[MsEventsStack+ECX] ; EDI point to the new Evt Elmnt
        MOV     EAX,[MsX]
        MOV     EBX,[MsY]
        MOV     ECX,[MsZ]

        MOV     EDX,[MsButton]
        MOV     [EDI+MouseEvent.MsX],EAX
        MOV     [EDI+MouseEvent.MsY],EBX
        MOV     [EDI+MouseEvent.MsZ],ECX
        MOV     [EDI+MouseEvent.MsButton],EDX
        MOV     EAX,[EBP+MsEventID] ; event
        INC     DWORD [MsStackNbElt]
        MOV     [EDI+MouseEvent.MsEvents],EAX

.EndMs:

        POP     EBX
        POP     ESI
        POP     EDI

    RETURN


; mouse event stack function
iEnableMsEvntsStack:
        XOR     EAX,EAX
        MOV     [MsStackNbElt],EAX
        MOV     [MsStackStart],EAX
        OR      AL,1
        MOV     [MsStackEnable],EAX
    RET

iDisableMsEvntsStack:
        XOR     EAX,EAX
        MOV     [MsStackEnable],EAX
        MOV     [MsStackNbElt],EAX
        MOV     [MsStackStart],EAX
        RET

iClearMsEvntsStack:
        XOR     EAX,EAX
        MOV     [MsStackNbElt],EAX
        MOV     [MsStackStart],EAX
    RET

iGetMsEvent:
        ARG MsEvnt, 4

        MOV     EAX,[MsStackNbElt]
        OR      EAX,EAX
        JZ      .finNoMsEvt

        PUSH    EDI
        DEC     EAX ; _MsStackNbElt-1
        PUSH    ESI
        MOV     EDX,[MsStackStart]
        MOV     [MsStackNbElt],EAX
        MOV     ECX,EDX ; MsStackSart
        PUSH    EBX
        IMUL    EDX,MouseEvent.Size
        INC     ECX
        ADD     EDX,MsEventsStack
        AND     ECX,0xFF ; rotate value 255->0
        MOV     EDI,[EBP+MsEvnt]
        MOV     [MsStackStart],ECX
        MOV     ESI,EDX
        MOV     EBX,[ESI+4] ; Y
        MOV     ECX,[ESI+8] ; Z
        MOV     EDX,[ESI+12] ; Button
        MOV     EAX,[ESI] ; X
        MOV     [EDI+4],EBX
        MOV     [EDI+8],ECX
        MOV     [EDI+12],EDX
        MOV     EBX,[ESI+16] ; Ms Evnt
        MOV     [EDI],EAX
        MOV     [EDI+16],EBX ; Ms Evnt
        MOV     AL,1 ; return true

.finGetMs:
        POP     EBX
        POP     ESI
        POP     EDI
.finNoMsEvt:

    RETURN



SECTION .bss   ALIGN=32

MsX             RESD    1
MsY             RESD    1
MsZ             RESD    1
MsButton        RESD    1
MsSpeedHz       RESD    1
MsSpeedVt       RESD    1
MsAccel         RESD    1
MsMickeyX       RESD    1
MsMickeyY       RESD    1
MsRestMickeyX   RESD    1
MsRestMickeyY   RESD    1
MsFirstInt      RESD    1
MsOrgX          RESD    1
MsOrgY          RESD    1
MsMaxX          RESD    1
MsMaxY          RESD    1
MsMinX          RESD    1
MsMinY          RESD    1
MsEventsStack   RESB    MouseEvent.Size*256
MsStackStart    RESD    1
MsStackNbElt    RESD    1
MsStackEnable   RESD    1
MsWheelSupp     RESD    1
