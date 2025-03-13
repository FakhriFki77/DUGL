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


;compute clipped polygone HLines ******************************

; in EDX = [NbPPoly]-1; mm6 = PPtrListPt
%macro  @ClipComputeHLines16    0
                MOVDQA          xmm7,[DGDQ0_1_2_3]
                MOVD            ESI,mm6 ; [PPtrListPt]
                MOV             EBX,[ESI] ; Ptr P(1)
                MOV             EDI,[ESI+EDX*4] ; Ptr P(N-1)
                MOVQ            xmm1,[EBX] ; X1 | Y1
                MOVQ            xmm2,[EDI] ; X2 | Y2
                MOVD            mm3,[OrgY]
%%ClipLoopHLines:
                MOVD            mm7,EDX     ; save EDX counter
                PXOR            mm1,mm1 ; mm1 = Steps, default zero
                PEXTRD          ECX,xmm1,1   ;  = [Y1]
                PEXTRD          EBP,xmm2,1   ;  = [Y2]
                ;XOR             EDX,EDX
                CMP             ECX,EBP  ; YP2
                MOVD            EBX,mm3  ; = [OrgY]
                JE              %%EndHLine ; DY = 0, skip this line
                MOV             ESI,TPolyAdFin ; default end/right

                MOVD            EAX,xmm1 ; = [X1]
                MOVD            EDI,xmm2 ; = [X2]
                JG              %%HRightCompute ; if YP1<YP2 then right else left
%%HLeft:
                ; swap P1, P2 and change Adress of writing into ESI
                MOV             ESI,TPolyAdDeb ; revert to start/left
                XCHG            ECX,EBP
                XCHG            EAX,EDI
; ---- End/Right computing clipping ----or Start/Left if %%HLeft not jumped !------
%%HRightCompute:
                ; DX Zero case
                SUB             EAX,EDI ; DX = X1-X2
                JZ              %%DXZ
                ; check completely out line
                CMP             ECX,[MinY]
                JL              %%EndHLine
                CMP             EBP,[MaxY]
                JG              %%EndHLine
                ; check clipped
                CMP             ECX,[MaxY]
                JG              %%Clip
                CMP             EBP,[MinY]
                JL              %%Clip
%%InRight:       ; in line
                SHL             EAX,Prec
                SUB             ECX,EBP ; DY = Y1-Y2
                CDQ
                IDIV            ECX
                OR              EAX,EAX
                JMP             %%HRight
%%Clip:         ; clipped line
                MOVD            mm2,ESI ; save dest array
                MOV             ESI,ECX ; save Y1
                SHL             EAX,Prec
                SUB             ECX,EBP ; Y1 - Y2
                CDQ
                IDIV            ECX
                ; clip Y2
                MOV             EDX,EBP ; save Y2
                SUB             EBP,[MinY]
                JGE             %%NoClipY2
                NEG             EBP
                MOV             EDX,[MinY] ; new Y2
                MOVD            mm1,EBP ; steps
%%NoClipY2:
                ; clip Y1
                CMP             ESI,[MaxY]
                MOV             EBP,EDX  ; new Y2 if any
                CMOVG           ESI,[MaxY]
                SUB             ESI,EBP ; new DY
                MOV             ECX,ESI ; new delta
                OR              EAX,EAX ; sign of PntX
                MOVD            ESI,mm2 ; restore dest array
%%HRight:
                LEA             EBX,[EBX+EBP] ; EBX = [YP2]+[OrgY] : Index
                LEA             EBX,[ESI+EBX*4] ; final dest adress
                CALL            ClipHLineXCompute
                JMP             %%EndHLine
%%DXZ:
                ; clip Y1, Y2 inside [MinY, MaxY]
                CMP             EBP,[MinY]
                CMOVL           EBP,[MinY]
                CMP             ECX,[MaxY]
                CMOVG           ECX,[MaxY]

                LEA             EBX,[EBX+EBP] ; EBX = [YP2]+[OrgY] : Index
                SUB             ECX,EBP
                LEA             EBX,[ESI+EBX*4] ; final dest adress
                OR              EAX,EAX ; PntX zero and to enable DXZ in HLine computing
                CALL            ClipHLineXCompute
%%EndHLine:
                MOVD            EDX,mm7     ; restore EDX counter
                MOVD            ESI,mm6     ; ESI = PtrListPt
                DEC             EDX
                JS              SHORT %%endClipHLines ; EDX < 0
                MOV             EAX,[ESI+EDX*4] ; EAX=PtrPt[EDX]
                MOVDQA          xmm1,xmm2 ; Old X2|Y2 become new X1|Y1
                MOVQ            xmm2,[EAX] ; new X2|Y2

                JMP             %%ClipLoopHLines
%%endClipHLines:
%endmacro
; In Compute HLines (U,V) or (XT, YT) ************************************************

%macro  @InComputeUVLines       0
                MOVD            EDX,mm5 ; [NbPPoly]-1
                MOVDQA          xmm7,[DGDQ0_1_2_3]
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
                ;XOR             EDX,EDX
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
                ;XOR             EDX,EDX
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

; Clip Compute HLines (U,V) or (XT, YT) ************************************************

; in EDX = [NbPPoly]-1; mm6 = PPtrListPt
%macro  @ClipComputeUVHLines16    0
                MOVD            EDX,mm5
                MOVD            ESI,mm6 ; [PPtrListPt]
                MOVDQA          xmm7,[DGDQ0_1_2_3]
                MOV             EBX,[ESI] ; Ptr P(1)
                MOV             EDI,[ESI+EDX*4] ; Ptr P(N-1)
                MOVQ            xmm1,[EBX+12] ; XT1 | YT1
                MOVQ            xmm2,[EDI+12] ; XT2 | YT2
                PINSRD          xmm1,[EBX+4],2 ;  Y1
                PINSRD          xmm2,[EDI+4],2 ;  Y2
                MOVD            mm3,[OrgY]
%%ClipLoopHLines:
                MOVD            mm7,EDX     ; save EDX counter
                PXOR            mm1,mm1 ; mm1 = Steps, default zero
                PEXTRD          ECX,xmm1,2   ;  = [Y1]
                PEXTRD          EBP,xmm2,2   ;  = [Y2]
                ;XOR             EDX,EDX
                CMP             ECX,EBP  ; YP2
                MOVD            EBX,mm3  ; = [OrgY]
                JE              %%EndHLine ; DY = 0, skip this line
                MOV             ESI,TexXFin ; default end/right
                MOVDQA          xmm6,xmm2  ; = XT2 | YT2
                PEXTRD          EDX,xmm1,1 ; = [YT1]
                MOVD            EAX,xmm1 ; = [XT1]
                PINSRD          xmm6,EDX,0 ; = YT1 | YT2
                MOVD            EDI,xmm2 ; = [XT2]
                PUNPCKLQDQ      xmm6,[AdrPolyTexFinDeb] ; YT1 | YT2 | TexYFin | TexYDeb
                JG              %%HRightCompute ; if YP1<YP2 then right else left
%%HLeft:
                ; swap XT1|XT2 and change Adress of writing into ESI, and swap YT1|YT2 and start adress into xmm6
                MOV             ESI,TexXDeb ; revert to start/left
                XCHG            ECX,EBP
                XCHG            EAX,EDI
                PSHUFD          xmm6,xmm6, (2<<6) | (3<<4) | (0<<2) | (1) ; = YT2 | YT1 | TexYDeb | TexYFin
; ---- End/Right computing clipping --------------
%%HRightCompute:
                SUB             EAX,EDI ; DX = XT1-XT2
                ; check completely out line
                CMP             ECX,[PolyMinY]
                JL              %%EndHLine
                CMP             EBP,[PolyMaxY]
                JG              %%EndHLine
                ; check clipped
                CMP             ECX,[PolyMaxY]
                JG              %%Clip
                CMP             EBP,[PolyMinY]
                JL              %%Clip
%%InRight:       ; in line --------------------
                SHL             EAX,Prec
                SUB             ECX,EBP ; DY = Y1-Y2
                CDQ
                IDIV            ECX
                MOVD            mm0,ECX
                OR              EAX,EAX
                JMP             %%HRight
%%Clip:         ; clipped line ----------------
                MOVD            mm2,ESI ; save dest array
                MOV             ESI,ECX ; save Y1
                SHL             EAX,Prec
                SUB             ECX,EBP ; Y1 - Y2
                CDQ
                IDIV            ECX
                MOVD            mm0,ECX
                ; clip Y2
                MOV             EDX,EBP ; save Y2
                SUB             EBP,[PolyMinY]
                JGE             %%NoClipY2
                NEG             EBP
                MOV             EDX,[PolyMinY] ; new Y2
                MOVD            mm1,EBP ; steps
%%NoClipY2:
                ; clip Y1
                CMP             ESI,[PolyMaxY]
                MOV             EBP,EDX  ; new Y2 if any
                CMOVG           ESI,[PolyMaxY]
                SUB             ESI,EBP ; new DY
                MOV             ECX,ESI ; new delta
                OR              EAX,EAX ; sign of PntX
                MOVD            ESI,mm2 ; restore dest array
%%HRight:
                ; do U or XT hline ---------------------------
                MOVD            mm2,ECX ; save delta Y
                ADD             EBP,EBX ; EBP = [YP2]+[OrgY] : Index
                OR              EAX,EAX
                LEA             EBX,[ESI+EBP*4] ; final dest adress
                CALL            ClipHLineXCompute
                ; do V or YT hline ---------------------------
                MOVD            EAX,xmm6 ; = YT1
                PEXTRD          EDI,xmm6,1 ; = YT2
                PEXTRD          ESI,xmm6,2 ; = startAddress
                ; compute PntV
                SUB             EAX,EDI
                LEA             EBX,[ESI+EBP*4] ; final dest adress
                JZ              SHORT %%DYTZ
                MOVD            ECX,mm0
                SHL             EAX,Prec
                CDQ
                IDIV            ECX
                OR              EAX,EAX
%%DYTZ:
                MOVD            ECX,mm2 ; restore DeltaY
                CALL            ClipHLineXCompute
%%EndHLine:
                MOVD            EDX,mm7     ; restore EDX counter
                MOVD            ESI,mm6     ; ESI = PtrListPt
                DEC             EDX
                JS              SHORT %%endClipHLines ; EDX < 0
                MOV             EAX,[ESI+EDX*4] ; EAX=PtrPt[EDX]
                MOVDQA          xmm1,xmm2 ; Old XT2|YT2|Y2 become new XT1|YT1|Y1
                MOVQ            xmm2,[EAX+12] ; new XT2|YT2
                PINSRD          xmm2,[EAX+4],2 ;  new Y2
                JMP             %%ClipLoopHLines
%%endClipHLines:
%endmacro


%macro @ClipCalcTextCnt 0
        CALL        ClipCalcTextCntPRC
%endmacro

ClipCalcTextCntPRC:
        @ClipComputeUVHLines16
        RET

