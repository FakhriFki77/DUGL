/*	Dust Ultimate Game Library (DUGL)
    Copyright (C) 2022	Fakhri Feki

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    contact: libdugl@hotmail.com    */

#ifndef DMOUSE_H_INCLUDED
#define DMOUSE_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// Mouse Support ============================================

//***** Mouse event
typedef struct
{       int		MsX,
                        MsY,
                        MsZ;
        unsigned int    MsButton,
                        MsEvents;
} MouseEvent;

// Mouse Button

#define MS_LEFT_BUTT 	1
#define MS_RIGHT_BUTT 	2
#define MS_MID_BUTT 	4

// Mouse events
#define MS_EVNT_MOUSE_MOVE  1
#define MS_EVNT_LBUTT_PRES  2
#define MS_EVNT_LBUTT_RELS  4
#define MS_EVNT_RBUTT_PRES  8
#define MS_EVNT_RBUTT_RELS  16
#define MS_EVNT_MBUTT_PRES  32
#define MS_EVNT_MBUTT_RELS  64
#define MS_EVNT_WHEEL_MOVE  128


extern int MsX, MsY, MsZ, MsButton, MsSpeedHz, MsSpeedVt, MsAccel;
extern unsigned char MsInWindow;

int  InstallMouse();
void UninstallMouse();
int IsMouseWheelSupported(); // return 1 if mouse wheel supported
void SetMouseRView(DgView *V);
void GetMouseRView(DgView *V);
void SetMouseOrg(int MsOrgX,int MsOrgY);
void EnableMsEvntsStack();
void DisableMsEvntsStack();
void ClearMsEvntsStack();
int GetMsEvent(MouseEvent *MsEvnt);
void PushMsEvent(unsigned int eventID);

#ifdef __cplusplus
		}  // extern "C" {
#endif

#endif // DMOUSE_H_INCLUDED

