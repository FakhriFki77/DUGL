%include "PARAM.asm"

; enable windows/linux win32/elf32 building
%pragma elf32 gprefix
%pragma win32 gprefix   _


; GLOBAL Function*************************************************************
;***
GLOBAL RightShiftLine, LeftShiftLine

; GLOBAL DATA*****************************************************************
;***

SECTION .text  ALIGN=32
[BITS 32]
;***

RightShiftLine:
	ARG	DD0PtrR, 4, DD1PtrR, 4
		MOVD		xmm0,ESI
		MOVD		xmm1,EDI
		MOVD		xmm2,EBX

		MOV		    ESI,[EBP+DD0PtrR]
		MOV		    EDI,[EBP+DD1PtrR]
		MOV		    EAX,[ESI]
		MOV		    EBX,[EDI]
		SHLD		EBX,EAX,1
		SHL		    EAX,1
		MOV		    [EDI],EBX
		MOV		    [ESI],EAX

		MOVD		ESI,xmm0
		MOVD		EDI,xmm1
		MOVD		EBX,xmm2
		RETURN

LeftShiftLine:
	ARG	DD0PtrL, 4, DD1PtrL, 4
		MOVD		xmm0,ESI
		MOVD		xmm1,EDI
		MOVD		xmm2,EBX

		MOV		    ESI,[EBP+DD0PtrL]
		MOV		    EDI,[EBP+DD1PtrL]
		MOV		    EAX,[ESI]
		MOV		    EBX,[EDI]
		SHRD		EAX,EBX,1
		SHR		    EBX,1
		MOV		    [ESI],EAX
		MOV		    [EDI],EBX

		MOVD		ESI,xmm0
		MOVD		EDI,xmm1
		MOVD		EBX,xmm2
		RETURN

;SECTION	.data  ALIGN 32
;*** data


