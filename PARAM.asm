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

%macro	ARG	2-*
	%assign i	8

	%rep	%0 / 2
		%assign %1  i
		%assign i	i+%2
		%rotate 	2
	%endrep

	PUSH		EBP
	MOV		EBP,ESP
%endmacro

%macro RETURN	0
	POP		EBP
	RET
%endmacro

%macro	FARG 	2-*
	%assign i	4

	%rep	%0 / 2
		%assign %1  i
		%assign i	i+%2
		%rotate 	2
	%endrep

%endmacro

%macro FRETURN  0
	RET
%endmacro
