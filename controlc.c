/*  Dust Ultimate Game Library (DUGL)
    Copyright (C) 2023  Fakhri Feki

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

    contact: libdugl(at)hotmail.com    */

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

/////////////////////////////////////
// Global events scan ///////////////
/////////////////////////////////////


unsigned char SDLKeybMap[256] = {

    0, //    SDL_SCANCODE_UNKNOWN = 0,
    0, //    1 - Not used
    0, //    2 - Not Used
    0, //    3 - Not used
    0x1e, //    SDL_SCANCODE_A = 4,
    0x30, //    SDL_SCANCODE_B = 5,
    0x2e, //    SDL_SCANCODE_C = 6,
    0x20, //    SDL_SCANCODE_D = 7,
    0x12, //    SDL_SCANCODE_E = 8,
    0x21, //    SDL_SCANCODE_F = 9,
    0x22, //    SDL_SCANCODE_G = 10,
    0x23, //    SDL_SCANCODE_H = 11,
    0x17, //    SDL_SCANCODE_I = 12,
    0x24, //    SDL_SCANCODE_J = 13,
    0x25, //    SDL_SCANCODE_K = 14,
    0x26, //    SDL_SCANCODE_L = 15,
    0x32, //    SDL_SCANCODE_M = 16,
    0x31, //    SDL_SCANCODE_N = 17,
    0x18, //    SDL_SCANCODE_O = 18,
    0x19, //    SDL_SCANCODE_P = 19,
    0x10, //    SDL_SCANCODE_Q = 20,
    0x13, //    SDL_SCANCODE_R = 21,
    0x1f, //    SDL_SCANCODE_S = 22,
    0x14, //    SDL_SCANCODE_T = 23,
    0x16, //    SDL_SCANCODE_U = 24,
    0x2f, //    SDL_SCANCODE_V = 25,
    0x11, //    SDL_SCANCODE_W = 26,
    0x2d, //   SDL_SCANCODE_X = 27,
    0x15, //   SDL_SCANCODE_Y = 28,
    0x2c, //   SDL_SCANCODE_Z = 29,

    0x02, //   SDL_SCANCODE_1 = 30,
    0x03, //   SDL_SCANCODE_2 = 31,
    0x04, //   SDL_SCANCODE_3 = 32,
    0x05, //   SDL_SCANCODE_4 = 33,
    0x06, //   SDL_SCANCODE_5 = 34,
    0x07, //   SDL_SCANCODE_6 = 35,
    0x08, //   SDL_SCANCODE_7 = 36,
    0x09, //   SDL_SCANCODE_8 = 37,
    0x0a, //   SDL_SCANCODE_9 = 38,
    0x0b, //   SDL_SCANCODE_0 = 39,

    0x1c, //   SDL_SCANCODE_RETURN = 40,
    0x01, //   SDL_SCANCODE_ESCAPE = 41,
    0x0e, //   SDL_SCANCODE_BACKSPACE = 42,
    0x0f, //   SDL_SCANCODE_TAB = 43,
    0x39, //   SDL_SCANCODE_SPACE = 44,
    0x0c, //   SDL_SCANCODE_MINUS = 45,
    0x0d, //   SDL_SCANCODE_EQUALS = 46,
    0x1a, //   SDL_SCANCODE_LEFTBRACKET = 47,
    0x1b, //   SDL_SCANCODE_RIGHTBRACKET = 48,
    0x2b, //   SDL_SCANCODE_BACKSLASH = 49,
    0, //   SDL_SCANCODE_NONUSHASH = 50,
    0x27, //   SDL_SCANCODE_SEMICOLON = 51,
    0x28, //   SDL_SCANCODE_APOSTROPHE = 52,
    0x29, //   SDL_SCANCODE_GRAVE = 53,
    0x33, //   SDL_SCANCODE_COMMA = 54,
    0x34, //   SDL_SCANCODE_PERIOD = 55,
    0x35, //   SDL_SCANCODE_SLASH = 56,
    0x3a, //   SDL_SCANCODE_CAPSLOCK = 57,

    0x3b, //   SDL_SCANCODE_F1 = 58,
    0x3c, //   SDL_SCANCODE_F2 = 59,
    0x3d, //   SDL_SCANCODE_F3 = 60,
    0x3e, //   SDL_SCANCODE_F4 = 61,
    0x3f, //   SDL_SCANCODE_F5 = 62,
    0x40, //   SDL_SCANCODE_F6 = 63,
    0x41, //   SDL_SCANCODE_F7 = 64,
    0x42, //   SDL_SCANCODE_F8 = 65,
    0x43, //   SDL_SCANCODE_F9 = 66,
    0x44, //   SDL_SCANCODE_F10 = 67,
    0x57, //   SDL_SCANCODE_F11 = 68,
    0x58, //   SDL_SCANCODE_F12 = 69,
    0xb7, //   SDL_SCANCODE_PRINTSCREEN = 70,
    0x46, //   SDL_SCANCODE_SCROLLLOCK = 71,
    0, //   SDL_SCANCODE_PAUSE = 72,
    0xd2, //   SDL_SCANCODE_INSERT = 73,
    0xc7, //   SDL_SCANCODE_HOME = 74,
    0xc9, //   SDL_SCANCODE_PAGEUP = 75,
    0xd3, //   SDL_SCANCODE_DELETE = 76,
    0xcf, //   SDL_SCANCODE_END = 77,
    0xd1, //   SDL_SCANCODE_PAGEDOWN = 78,
    0xcd, //   SDL_SCANCODE_RIGHT = 79,
    0xcb, //   SDL_SCANCODE_LEFT = 80,
    0xd0, //   SDL_SCANCODE_DOWN = 81,
    0xc8, //   SDL_SCANCODE_UP = 82,
    0x45, //   SDL_SCANCODE_NUMLOCKCLEAR = 83,
    0xb5, //   SDL_SCANCODE_KP_DIVIDE = 84,
    0x37, //   SDL_SCANCODE_KP_MULTIPLY = 85,
    0x4a, //   SDL_SCANCODE_KP_MINUS = 86,
    0x4e, //   SDL_SCANCODE_KP_PLUS = 87,
    0x9c, //   SDL_SCANCODE_KP_ENTER = 88,
    0x4f, //   SDL_SCANCODE_KP_1 = 89,
    0x50, //   SDL_SCANCODE_KP_2 = 90,
    0x51, //   SDL_SCANCODE_KP_3 = 91,
    0x4b, //   SDL_SCANCODE_KP_4 = 92,
    0x4c, //   SDL_SCANCODE_KP_5 = 93,
    0x4d, //   SDL_SCANCODE_KP_6 = 94,
    0x47,  //   SDL_SCANCODE_KP_7 = 95,
    0x48,  //   SDL_SCANCODE_KP_8 = 96,
    0x49,  //   SDL_SCANCODE_KP_9 = 97,
    0x52, //   SDL_SCANCODE_KP_0 = 98,
    0x53, //   SDL_SCANCODE_KP_PERIOD = 99,
    0x56, //   SDL_SCANCODE_NONUSBACKSLASH = 100,
    0, //   SDL_SCANCODE_APPLICATION = 101,
    0, //   SDL_SCANCODE_POWER = 102,
    0, //   SDL_SCANCODE_KP_EQUALS = 103,
    0, //   SDL_SCANCODE_F13 = 104,
    0, //   SDL_SCANCODE_F14 = 105,
    0, //   SDL_SCANCODE_F15 = 106,
    0, //   SDL_SCANCODE_F16 = 107,
    0, //   SDL_SCANCODE_F17 = 108,
    0, //   SDL_SCANCODE_F18 = 109,
    0, //   SDL_SCANCODE_F19 = 110,
    0, //   SDL_SCANCODE_F20 = 111,
    0, //   SDL_SCANCODE_F21 = 112,
    0, //   SDL_SCANCODE_F22 = 113,
    0, //   SDL_SCANCODE_F23 = 114,
    0, //   SDL_SCANCODE_F24 = 115,
    0, //   SDL_SCANCODE_EXECUTE = 116,
    0, //   SDL_SCANCODE_HELP = 117,
    0, //   SDL_SCANCODE_MENU = 118,
    0, //   SDL_SCANCODE_SELECT = 119,
    0, //   SDL_SCANCODE_STOP = 120,
    0, //   SDL_SCANCODE_AGAIN = 121,   /**< redo */
    0, //   SDL_SCANCODE_UNDO = 122,
    0, //   SDL_SCANCODE_CUT = 123,
    0, //   SDL_SCANCODE_COPY = 124,
    0, //   SDL_SCANCODE_PASTE = 125,
    0, //   SDL_SCANCODE_FIND = 126,
    0, //   SDL_SCANCODE_MUTE = 127,
    0, //   SDL_SCANCODE_VOLUMEUP = 128,
    0, //   SDL_SCANCODE_VOLUMEDOWN = 129,
    0, //   SDL_SCANCODE_LOCKINGCAPSLOCK = 130,
    0, //   SDL_SCANCODE_LOCKINGNUMLOCK = 131,
    0, //   SDL_SCANCODE_LOCKINGSCROLLLOCK = 132,
    0, //   SDL_SCANCODE_KP_COMMA = 133,
    0, //   SDL_SCANCODE_KP_EQUALSAS400 = 134,
    0, //   SDL_SCANCODE_INTERNATIONAL1 = 135,
    0, //   SDL_SCANCODE_INTERNATIONAL2 = 136,
    0, //   SDL_SCANCODE_INTERNATIONAL3 = 137, /**< Yen */
    0, //   SDL_SCANCODE_INTERNATIONAL4 = 138,
    0, //   SDL_SCANCODE_INTERNATIONAL5 = 139,
    0, //   SDL_SCANCODE_INTERNATIONAL6 = 140,
    0, //   SDL_SCANCODE_INTERNATIONAL7 = 141,
    0, //   SDL_SCANCODE_INTERNATIONAL8 = 142,
    0, //   SDL_SCANCODE_INTERNATIONAL9 = 143,
    0, //   SDL_SCANCODE_LANG1 = 144, /**< Hangul/English toggle */
    0, //   SDL_SCANCODE_LANG2 = 145, /**< Hanja conversion */
    0, //   SDL_SCANCODE_LANG3 = 146, /**< Katakana */
    0, //   SDL_SCANCODE_LANG4 = 147, /**< Hiragana */
    0, //   SDL_SCANCODE_LANG5 = 148, /**< Zenkaku/Hankaku */
    0, //   SDL_SCANCODE_LANG6 = 149, /**< reserved */
    0, //   SDL_SCANCODE_LANG7 = 150, /**< reserved */
    0, //   SDL_SCANCODE_LANG8 = 151, /**< reserved */
    0, //   SDL_SCANCODE_LANG9 = 152, /**< reserved */
    0, //   SDL_SCANCODE_ALTERASE = 153, /**< Erase-Eaze */
    0, //   SDL_SCANCODE_SYSREQ = 154,
    0, //   SDL_SCANCODE_CANCEL = 155,
    0, //   SDL_SCANCODE_CLEAR = 156,
    0, //   SDL_SCANCODE_PRIOR = 157,
    0, //   SDL_SCANCODE_RETURN2 = 158,
    0, //   SDL_SCANCODE_SEPARATOR = 159,
    0, //   SDL_SCANCODE_OUT = 160,
    0, //   SDL_SCANCODE_OPER = 161,
    0, //   SDL_SCANCODE_CLEARAGAIN = 162,
    0, //   SDL_SCANCODE_CRSEL = 163,
    0, //   SDL_SCANCODE_EXSEL = 164,
    0, //   165 - not used
    0, //   166 - not used
    0, //   167 - not used
    0, //   168 - not used
    0, //   169 - not used
    0, //   170 - not used
    0, //   171 - not used
    0, //   172 - not used
    0, //   173 - not used
    0, //   174 - not used
    0, //   175 - not used
    0, //   SDL_SCANCODE_KP_00 = 176,
    0, //   SDL_SCANCODE_KP_000 = 177,
    0, //   SDL_SCANCODE_THOUSANDSSEPARATOR = 178,
    0, //   SDL_SCANCODE_DECIMALSEPARATOR = 179,
    0, //   SDL_SCANCODE_CURRENCYUNIT = 180,
    0, //   SDL_SCANCODE_CURRENCYSUBUNIT = 181,
    0, //   SDL_SCANCODE_KP_LEFTPAREN = 182,
    0, //   SDL_SCANCODE_KP_RIGHTPAREN = 183,
    0, //   SDL_SCANCODE_KP_LEFTBRACE = 184,
    0, //   SDL_SCANCODE_KP_RIGHTBRACE = 185,
    0, //   SDL_SCANCODE_KP_TAB = 186,
    0, //   SDL_SCANCODE_KP_BACKSPACE = 187,
    0, //   SDL_SCANCODE_KP_A = 188,
    0, //   SDL_SCANCODE_KP_B = 189,
    0, //   SDL_SCANCODE_KP_C = 190,
    0, //   SDL_SCANCODE_KP_D = 191,
    0, //   SDL_SCANCODE_KP_E = 192,
    0, //   SDL_SCANCODE_KP_F = 193,
    0, //   SDL_SCANCODE_KP_XOR = 194,
    0, //   SDL_SCANCODE_KP_POWER = 195,
    0, //   SDL_SCANCODE_KP_PERCENT = 196,
    0, //   SDL_SCANCODE_KP_LESS = 197,
    0, //   SDL_SCANCODE_KP_GREATER = 198,
    0, //   SDL_SCANCODE_KP_AMPERSAND = 199,
    0, //   SDL_SCANCODE_KP_DBLAMPERSAND = 200,
    0, //   SDL_SCANCODE_KP_VERTICALBAR = 201,
    0, //   SDL_SCANCODE_KP_DBLVERTICALBAR = 202,
    0, //   SDL_SCANCODE_KP_COLON = 203,
    0, //   SDL_SCANCODE_KP_HASH = 204,
    0, //   SDL_SCANCODE_KP_SPACE = 205,
    0, //   SDL_SCANCODE_KP_AT = 206,
    0, //   SDL_SCANCODE_KP_EXCLAM = 207,
    0, //   SDL_SCANCODE_KP_MEMSTORE = 208,
    0, //   SDL_SCANCODE_KP_MEMRECALL = 209,
    0, //   SDL_SCANCODE_KP_MEMCLEAR = 210,
    0, //   SDL_SCANCODE_KP_MEMADD = 211,
    0, //   SDL_SCANCODE_KP_MEMSUBTRACT = 212,
    0, //   SDL_SCANCODE_KP_MEMMULTIPLY = 213,
    0, //   SDL_SCANCODE_KP_MEMDIVIDE = 214,
    0, //   SDL_SCANCODE_KP_PLUSMINUS = 215,
    0, //   SDL_SCANCODE_KP_CLEAR = 216,
    0, //   SDL_SCANCODE_KP_CLEARENTRY = 217,
    0, //   SDL_SCANCODE_KP_BINARY = 218,
    0, //   SDL_SCANCODE_KP_OCTAL = 219,
    0, //   SDL_SCANCODE_KP_DECIMAL = 220,
    0, //   SDL_SCANCODE_KP_HEXADECIMAL = 221,
    0, //   222 - not used
    0, //   223 - not used
    0x1d, //   SDL_SCANCODE_LCTRL = 224,
    0x2a, //   SDL_SCANCODE_LSHIFT = 225,
    0x38, //   SDL_SCANCODE_LALT = 226, /**< alt, option */
    0xdb, //   SDL_SCANCODE_LGUI = 227, /**< windows, command (apple), meta */
    0x9d, //   SDL_SCANCODE_RCTRL = 228,
    0x36, //   SDL_SCANCODE_RSHIFT = 229,
    0xb8, //   SDL_SCANCODE_RALT = 230, /**< alt gr, option */
    0xdc, //   SDL_SCANCODE_RGUI = 231, /**< windows, command (apple), meta */
    0, //   232 - Not used
    0, //   233 - Not used
    0, //   234 - Not used
    0, //   235 - Not used
    0, //   236 - Not used
    0, //   237 - Not used
    0, //   238 - Not used
    0, //   239 - Not used
    0, //   240 - Not used
    0, //   241 - Not used
    0, //   242 - Not used
    0, //   243 - Not used
    0, //   244 - Not used
    0, //   245 - Not used
    0, //   246 - Not used
    0, //   247 - Not used
    0, //   248 - Not used
    0, //   249 - Not used
    0, //   250 - Not used
    0, //   251 - Not used
    0, //   252 - Not used
    0, //   253 - Not used
    0, //   254 - Not used
    0 //   255 - Not used
};

int left_ctrlDown = 0;
unsigned int lastTime_left_ctrlDown = 0;
unsigned char DgWindowFocused = 0;
unsigned char DgWindowFocusLost = 0;

void DgScanEvents(SDL_Event *event) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        if (event->type == SDL_WINDOWEVENT) {
            switch (event->window.event) {
            case SDL_WINDOWEVENT_ENTER:
                MsInWindow = 1;
                if (MsScanEvents == 1) SDL_ShowCursor(SDL_DISABLE);
                break;
            case SDL_WINDOWEVENT_LEAVE:
                MsInWindow = 0;
                if (MsScanEvents == 1) SDL_ShowCursor(SDL_ENABLE);
                break;
            case SDL_WINDOWEVENT_SIZE_CHANGED:
                if (DgWindow != NULL) {
                    int w = 0, h = 0;
                    if (dgWindowPreResizeCallBack != NULL) {
                        dgWindowPreResizeCallBack(RendSurf->ResH, RendSurf->ResV);
                    }
                    if (dgResizeWinMutex != NULL) {
                        if (dgRequestResizeWinMutex == NULL) {
                            LockDMutex(dgResizeWinMutex);
                        } else {
                            if(!TryLockDMutex(dgResizeWinMutex)) {
                                // the Delay inside the loop is required to ensure the other thread will be able to modify the bool to false
                                for ((*dgRequestResizeWinMutex) = true; (*dgRequestResizeWinMutex) == true;) DelayMs(1);
                                LockDMutex(dgResizeWinMutex);
                            }
                        }
                    }
                    DgGetMainWindowSize(&w, &h);
                    DgResizeRendSurf(w, h);
                    // update mouse View
                    if (MsScanEvents == 1) {
                        DgView defaultMsView;
                        GetSurfView(RendSurf, &defaultMsView);
                        SetMouseRView(&defaultMsView);
                    }
                    if (dgWindowResizeCallBack != NULL) {
                        dgWindowResizeCallBack(w, h);
                    }
                    if (dgResizeWinMutex != NULL)
                        UnlockDMutex(dgResizeWinMutex);
                }
                break;
            case SDL_WINDOWEVENT_FOCUS_GAINED:
                if (KbScanEvents == 1) UpdateCAPS_NUMKbFLAG();
                DgWindowFocused = 1;
                break;
            case SDL_WINDOWEVENT_FOCUS_LOST:
                if (KbScanEvents == 1) UpdateCAPS_NUMKbFLAG();
                DgWindowFocused = 0;
                DgWindowFocusLost = 1;

                break;
            }
        }

        if (KbScanEvents == 1) {
            unsigned int realKeyCode = 0;
            switch(event->type) {
            case SDL_KEYDOWN:
                // handle the special case of  right alt e6 (alt gr) and left ctrl e0
                if (event->key.keysym.scancode == 0xe6 || event->key.keysym.scancode == 0xe0) {
                    if (event->key.keysym.scancode == 0xe0) { // left Ctrl
                        iPushKbDownEvent((unsigned int)SDLKeybMap[0xe0]);
                        left_ctrlDown = 1;
                        lastTime_left_ctrlDown = event->key.timestamp;
                    } else if  (event->key.keysym.scancode == 0xe6) {
                        // cancel left Ctrl if delta time between last right alt is below 4 ms ?
                        if (left_ctrlDown == 1 && (event->key.timestamp - lastTime_left_ctrlDown) < 4)
                            iPushKbReleaseEvent((unsigned int)SDLKeybMap[0xe0]);
                        iPushKbDownEvent((unsigned int)SDLKeybMap[0xe6]);
                    }
                } else
                    realKeyCode = (event->key.keysym.scancode <= 0xFF) ? (unsigned int)SDLKeybMap[event->key.keysym.scancode] : 0;
                if (realKeyCode > 0) {
                    // try to update CAPS and NUM
                    if (realKeyCode != 0x3a && realKeyCode != 0x45)
                        UpdateCAPS_NUMKbFLAG();

                    iPushKbDownEvent(realKeyCode);
                }

                break;
            case SDL_KEYUP:
                if (event->key.keysym.scancode == 0xe0) { // left Ctrl
                    left_ctrlDown = 0;
                    lastTime_left_ctrlDown = 0;
                }

                realKeyCode = (event->key.keysym.scancode <= 0xFF) ? (unsigned int)SDLKeybMap[event->key.keysym.scancode] : 0;
                if (realKeyCode > 0)
                    iPushKbReleaseEvent(realKeyCode);
                break;
            default:
                break;
            }
        }

        if (MsScanEvents == 1) {
            unsigned int msButtonEventID = 0;
            switch(event->type) {
            case SDL_MOUSEMOTION:
                iSetMousePos(event->motion.x, event->motion.y);
                iPushMsEvent(MS_EVNT_MOUSE_MOVE);
                break;
            case SDL_MOUSEBUTTONDOWN:
                UpdateMouseButtonsState();
                if( event->button.button == SDL_BUTTON_RIGHT)
                    msButtonEventID = MS_EVNT_RBUTT_PRES;
                else if ( event->button.button == SDL_BUTTON_LEFT)
                    msButtonEventID = MS_EVNT_LBUTT_PRES;
                else if ( event->button.button == SDL_BUTTON_MIDDLE)
                    msButtonEventID = MS_EVNT_MBUTT_PRES;
                iPushMsEvent(msButtonEventID);
                break;
            case SDL_MOUSEBUTTONUP:
                UpdateMouseButtonsState();
                if( event->button.button == SDL_BUTTON_RIGHT)
                    msButtonEventID = MS_EVNT_RBUTT_RELS;
                else if ( event->button.button == SDL_BUTTON_LEFT)
                    msButtonEventID = MS_EVNT_LBUTT_RELS;
                else if ( event->button.button == SDL_BUTTON_MIDDLE)
                    msButtonEventID = MS_EVNT_MBUTT_RELS;
                iPushMsEvent(msButtonEventID);
                break;
            case SDL_MOUSEWHEEL:
                MsZ += event->wheel.y;
                iPushMsEvent(MS_EVNT_WHEEL_MOVE);
                break;
            default:
                break;
            }
        }

        SDL_UnlockMutex(mutexEvents);
    }
}

void UpdateMouseButtonsState() {
    Uint32 buttonsMask = SDL_GetMouseState(NULL, NULL);
    MsButton = 0;
    if (buttonsMask & SDL_BUTTON(SDL_BUTTON_RIGHT))
        MsButton |= MS_RIGHT_BUTT;
    if (buttonsMask & SDL_BUTTON(SDL_BUTTON_LEFT))
        MsButton |= MS_LEFT_BUTT;
    if (buttonsMask & SDL_BUTTON(SDL_BUTTON_MIDDLE))
        MsButton |= MS_MID_BUTT;
}

///////////////////////////////////////
// Timer //////////////////////////////


SDL_TimerID sdl_timer_id = 0;

unsigned int DgTime = 0;
unsigned int DgTimerInterval = 0;
int DgTimerFreq = 0;
Uint64 lastPerformanceCounterValue = 0;
Uint64 lastPerformanceCounterRest = 0;
Uint64 DgPerformanceCounterFreq = 0;
Uint64 newPerfCounter = 0;
Uint64 deltaPerfCounter = 0;

const int MinTimerFreq = 20;
const int MaxTimerFreq = 1000;
const int DefaultTimerFreq = 200;
const int TimeFreqsCount = 10;

const int TimeFreqs[10] = { 20, 25, 40, 50, 100, 125, 200, 250, 500, 1000};

Uint32 DgTimeHandler(Uint32 interval, void *param);

void DgInstallTimer(int Freq) {
    int nIdx = 0;
    SDL_Log("Installing Timer: requested frequency %i\n\n", Freq);
    printf("Installing Timer: requested frequency %i\n\n", Freq);
    if (sdl_timer_id != 0) {
        SDL_RemoveTimer(sdl_timer_id);
        sdl_timer_id = 0;
    }

    // verify validity
    if (Freq < MinTimerFreq || Freq > MaxTimerFreq) {
        DgInstallTimer(DefaultTimerFreq);
        return;
    }
    // reset Time Values
    DgTime = 0;
    DgTimerFreq = 0;
    // search equal or highest bound
    for (nIdx = 0; nIdx < TimeFreqsCount; nIdx++) {
        if (TimeFreqs[nIdx] == Freq)
            break;
        else if (TimeFreqs[nIdx] > Freq) // choose always the higher bound
            break;
    }
    // fail ?
    if (nIdx >= TimeFreqsCount)
        return;
    // install new timer
    DgTimerInterval = 1000/TimeFreqs[nIdx];
    DgTime = 0;
    DgPerformanceCounterFreq = SDL_GetPerformanceFrequency();
    lastPerformanceCounterValue = SDL_GetPerformanceCounter();
    lastPerformanceCounterRest = 0;
    DgTimerFreq = TimeFreqs[nIdx];
    sdl_timer_id = SDL_AddTimer(DgTimerInterval, DgTimeHandler, NULL);
    if (sdl_timer_id == 0) // failed ?
        DgTimerFreq = 0;
}

Uint32 DgTimeHandler(Uint32 interval, void *param) {
    if (DgTimerFreq>0) {
        newPerfCounter = SDL_GetPerformanceCounter();
        deltaPerfCounter = (newPerfCounter - lastPerformanceCounterValue + lastPerformanceCounterRest) * (Uint64)(DgTimerFreq);
        lastPerformanceCounterRest = (deltaPerfCounter % DgPerformanceCounterFreq)/(Uint64)(DgTimerFreq);
        DgTime += (unsigned int)(deltaPerfCounter / DgPerformanceCounterFreq);

        lastPerformanceCounterValue = newPerfCounter;
    }
    return interval;
}

void DgUninstallTimer() {
    if (sdl_timer_id != 0) {
        SDL_RemoveTimer(sdl_timer_id);
        sdl_timer_id = 0;
        DgTime = 0;
        DgTimerFreq = 0;
        DgTimerInterval = 0;
    }
}

// time Synch

int  InitSynch(void *SynchBuff,int *Pos,float Freq) {
    SynchTime *ST;
    if (!DgTimerFreq) return 0;
    // start Sync
    StartSynch(SynchBuff,Pos);
    // save parameters
    ST=((SynchTime*)(SynchBuff));
    ST->Freq=Freq;
    return 1;
}

void InsertTime(SynchTime *ST, unsigned int TimeValue) {
    ST->LastTimeValue = TimeValue;
    // Add a new time value
    if (ST->hstNbItems < SYNCH_HST_SIZE) { // time table not yet full ?
        ST->hstIdxFin = (ST->hstIdxDeb+ST->hstNbItems)&(SYNCH_HST_SIZE-1);
        ST->hstNbItems++;
    } else {
        // time table full
        ST->hstIdxDeb =(ST->hstIdxDeb+1)&(SYNCH_HST_SIZE-1);
        ST->hstIdxFin = (ST->hstIdxDeb+SYNCH_HST_SIZE-1)&(SYNCH_HST_SIZE-1);
    }
    ST->TimeHst[ST->hstIdxFin] = ST->LastTimeValue;
    if(ST->hstIdxFin == 0) {
        ST->LastNbNullSynch = ST->NbNullSynch;
        ST->NbNullSynch = 0;
    }
}

int  Synch(void *SynchBuff,int *Pos) {
    SynchTime *ST;
    int ipos;
    unsigned int timeToHandle = DgTime;
    unsigned int lastTimeInserted = 0;

    if (DgTimerFreq==0 || SynchBuff==NULL) return 0;
    ST=((SynchTime*)(SynchBuff));
    ST->LastSynchNull=0;
    lastTimeInserted = ST->LastTimeValue;

    // continu only if time changed
    if (lastTimeInserted == timeToHandle) {
        if (Pos!=NULL)
            *Pos = ST->LastPos;
        ST->NbNullSynch++;
        ST->LastSynchNull=1;
        return 0; // delta Synch 0
    }
    // Time counter reached max value
    if (timeToHandle < lastTimeInserted)
        StartSynch(SynchBuff, Pos);

    InsertTime(ST, timeToHandle);
    ipos = ST->LastPos;
    // increase the pos
    ST->LastPos += ((float)(timeToHandle - lastTimeInserted) / (float) DgTimerFreq) * ST->Freq;
    if (Pos != NULL)
        *Pos = ST->LastPos;

    return (int)(ST->LastPos)-ipos;
}

void StartSynch(void *SynchBuff,int *Pos) {
    SynchTime *ST;

    if (DgTimerFreq==0 || SynchBuff==NULL) return;
    ST=((SynchTime*)(SynchBuff));
    // start Sync
    ST->LastPos = 0.0;
    ST->FirstTimeValue = DgTime;
    ST->LastTimeValue = ST->FirstTimeValue;
    SDL_memset4(&ST->TimeHst[0], 0, SYNCH_HST_SIZE);
    ST->TimeHst[0] = ST->FirstTimeValue;
    ST->hstIdxDeb = 0;
    ST->hstIdxFin = 1;
    ST->hstNbItems = 1;
    ST->LastSynchNull = 0;
    ST->NbNullSynch = 0;
    ST->LastNbNullSynch = 0;

    if (Pos!=NULL)
        *Pos=0;
}

float SynchAccTime(void *SynchBuff) {
    SynchTime *ST;

    if (DgTimerFreq==0 || SynchBuff==NULL)
        return 0;
    ST = ((SynchTime*)(SynchBuff));
    return (float)(DgTime-ST->FirstTimeValue)/(float)(DgTimerFreq);
}

float SynchAverageTime(void *SynchBuff) {
    SynchTime *ST;
    unsigned int i, idxDeb, idxFin;
    unsigned int SumSyncTime=0;

    ST=((SynchTime*)(SynchBuff));
    if (DgTimerFreq == 0 || ST == NULL || ST->hstNbItems < 2)
        return 0.0;
    for (i=0; i < ST->hstNbItems-1; i++) {
        idxDeb = (ST->hstIdxDeb+i)&(SYNCH_HST_SIZE-1);
        idxFin = (ST->hstIdxDeb+i+1)&(SYNCH_HST_SIZE-1);
        SumSyncTime+=(ST->TimeHst[idxFin]-ST->TimeHst[idxDeb]);
    }
    return (float)(SumSyncTime)/(float)((ST->hstNbItems-1+((ST->LastNbNullSynch)))*DgTimerFreq);
}

float SynchLastTime(void *SynchBuff) {
    SynchTime *ST;
    unsigned int idxDeb, idxAFin;
    unsigned int SumSyncTime;

    ST=((SynchTime*)(SynchBuff));
    if (DgTimerFreq == 0 || ST == NULL || ST->hstNbItems < 2 || ST->LastSynchNull)
        return 0.0;
    idxDeb = (ST->hstIdxDeb+ST->hstNbItems-2)&(SYNCH_HST_SIZE-1);
    idxAFin = (ST->hstIdxDeb+ST->hstNbItems-1)&(SYNCH_HST_SIZE-1);
    SumSyncTime = ST->TimeHst[idxAFin]-ST->TimeHst[idxDeb];

    return (float)(SumSyncTime)/(float)(DgTimerFreq);
}

int  WaitSynch(void *SynchBuff,int *Pos) {
    SynchTime *ST;
    int curIPos = 0;
    int lastIPos = 0;
    float lastPos = 0.0f;
    unsigned int timeToHandle = 0;

    ST=((SynchTime*)(SynchBuff));

    if (DgTimerFreq==0 || ST==NULL) return 0;

    curIPos = (int)ST->LastPos;
    lastIPos = (int)ST->LastPos;
    for (;;) {
        timeToHandle = DgTime;
        if (timeToHandle == ST->LastTimeValue) {
            SDL_Delay(1);
            continue;
        }
        lastPos = ST->LastPos + ((float)(timeToHandle - ST->LastTimeValue) / (float) DgTimerFreq) * ST->Freq;
        lastIPos = (int)(lastPos);
        if (lastIPos > curIPos) {
            InsertTime(ST, timeToHandle);
            ST->LastPos = lastPos;
            break;
        }
        SDL_Delay(1);
    }
    if (Pos != NULL)
        *Pos = ST->LastPos;
    return (lastIPos - curIPos);
}

void DelayMs(unsigned int delayInMs) {
#define bigDelay 10
    const Uint64 timeout = SDL_GetTicks64() + delayInMs;
    Uint64 curTick64 = 0;
    while ((curTick64 = SDL_GetTicks64()) < timeout) {
        if (curTick64 + bigDelay <= timeout) {
            SDL_Delay(bigDelay);
        } else {
            SDL_Delay(1);
        }
    }
}

///////////////////////////////////////
// Keyboard ///////////////////////////

int  InstallKeyboard() {
    if (KbScanEvents == 1)
        return 1;
    iClearKeyCircBuff();
    iClearAsciiCircBuff();

    KbFLAG = 0;
    KbApp[0] = KbApp[1] = KbApp[2] = KbApp[3] = KbApp[4] = KbApp[5] = KbApp[6] = KbApp[7] = 0;
    LastKey = 0;
    LastAscii = 0;
    // update KbFLAG
    UpdateCAPS_NUMKbFLAG();

    KbScanEvents = 1;

    return 1;
}

void UpdateCAPS_NUMKbFLAG() {
    int tempflags = SDL_GetModState();

    if (tempflags & KMOD_CAPS) // CAPS
        KbFLAG |= KB_CAPS_ACT;
    else {
        if (KbFLAG & KB_CAPS_ACT) // DELETE ?
            KbFLAG ^= KB_CAPS_ACT;
    }
    if (tempflags & KMOD_NUM) // NUM
        KbFLAG |= KB_NUM_ACT;
    else {
        if (KbFLAG & KB_NUM_ACT) // DELETE ?
            KbFLAG ^= KB_NUM_ACT;
    }
}

void UninstallKeyboard() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iUninstallKeyboard();
        SDL_UnlockMutex(mutexEvents);
    }
}


void PushKbDownEvent(unsigned int KeyCode) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iPushKbDownEvent(KeyCode);
        SDL_UnlockMutex(mutexEvents);
    }
}

void PushKbReleaseEvent(unsigned int KeyCode) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iPushKbReleaseEvent(KeyCode);
        SDL_UnlockMutex(mutexEvents);
    }
}


void SetKbMAP(KbMAP *KM) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iSetKbMAP(KM);
        SDL_UnlockMutex(mutexEvents);
    }
}

void DisableCurKbMAP() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iDisableCurKbMAP();
        SDL_UnlockMutex(mutexEvents);
    }
}


void GetKey(unsigned char *Key,unsigned int *KeyFLAG) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iGetKey(Key, KeyFLAG);
        SDL_UnlockMutex(mutexEvents);
    }
}

void WaitKeyPressed() {
    while (GetKeyNbElt() == 0) {
        SDL_Delay(10);
        DgCheckEvents();
    }
}

void ClearKeyCircBuff() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iClearKeyCircBuff();
        SDL_UnlockMutex(mutexEvents);
    }
}

void GetTimedKeyDown(unsigned char *Key,unsigned int *KeyTime) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iGetTimedKeyDown(Key,KeyTime);
        SDL_UnlockMutex(mutexEvents);
    }
}

void ClearTimedKeyCircBuff() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iClearTimedKeyCircBuff();
        SDL_UnlockMutex(mutexEvents);
    }
}

void GetAscii(unsigned char *Ascii,unsigned int *AsciiFLAG) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iGetAscii(Ascii, AsciiFLAG);
        SDL_UnlockMutex(mutexEvents);
    }
}

void ClearAsciiCircBuff() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iClearAsciiCircBuff();
        SDL_UnlockMutex(mutexEvents);
    }
}


int  LoadKbMAP(KbMAP **KMap,const char *Fname) {
    FILE *InKbMAP;
    KbMAP KM;
    int Size,i;
    unsigned int Buff;

    if (fopen_s(&InKbMAP,Fname,"rb")!=0) {
        return 0;
    }
    if (fread(&KM,sizeof(KbMAP),1,InKbMAP)<1) {
        fclose(InKbMAP);
        return 0;
    }
    fseek(InKbMAP,0,SEEK_END);
    Size=ftell(InKbMAP);
    if (KM.Sign!='PAMK' || KM.SizeKbMap!=(Size-sizeof(KbMAP))) {
        fclose(InKbMAP);
        return 0;
    }
    if ((*KMap=(KbMAP*) malloc(KM.SizeKbMap+sizeof(KbMAP)))==NULL) {
        fclose(InKbMAP);
        return 0;
    }
    Buff=(unsigned int)(*KMap);

    fseek(InKbMAP,0,SEEK_SET);
    if (fread(*KMap,KM.SizeKbMap+sizeof(KbMAP),1,InKbMAP)<1) {
        free(*KMap);
        fclose(InKbMAP);
        return 0;
    }

    // Adjust pointers
    (*KMap)->KbMapPtr=(void*)((unsigned int)((*KMap)->KbMapPtr)+Buff);
    if ((*KMap)->TabPrefixKeyb!=NULL) {
        (*KMap)->TabPrefixKeyb = (PrefixKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb)+Buff);
    }
    if ((*KMap)->TabNormPrefixKeyb!=NULL) {
        (*KMap)->TabNormPrefixKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabNormPrefixKeyb)+Buff);
    }
    if ((*KMap)->TabNormKeyb!=NULL) {
        (*KMap)->TabNormKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabNormKeyb)+Buff);
    }

    if ((*KMap)->TabNormKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbNorm; i++)
            (*KMap)->TabNormKeyb[i].Ptr = (unsigned char*)((unsigned int)((*KMap)->TabNormKeyb[i].Ptr)+Buff);
    }
    if ((*KMap)->TabNormPrefixKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbNormPrefix; i++) {
            (*KMap)->TabNormPrefixKeyb[i].Ptr = (unsigned char*)((unsigned int)((*KMap)->TabNormPrefixKeyb[i].Ptr)+Buff);
        }
    }
    if ((*KMap)->TabPrefixKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbPrefix; i++) {
            (*KMap)->TabPrefixKeyb[i].TabNormKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb[i].TabNormKeyb)+Buff);
        }
    }
    fclose(InKbMAP);
    return 1;
}

int  LoadMemKbMAP(KbMAP **KMap,void *In,int SizeIn) {
    KbMAP KM;
    int i;
    unsigned int Buff;

    memcpy(&KM,In,sizeof(KbMAP));
    if (KM.Sign!='PAMK' || KM.SizeKbMap!=(SizeIn-sizeof(KbMAP))) return 0;
    if ((*KMap=(KbMAP*)malloc(KM.SizeKbMap+sizeof(KbMAP)))==NULL) return 0;
    Buff=(unsigned int)(*KMap);
    memcpy(*KMap,In,KM.SizeKbMap+sizeof(KbMAP));

    // Adjust pointers
    (*KMap)->KbMapPtr=(void*)((unsigned int)((*KMap)->KbMapPtr)+Buff);
    if ((*KMap)->TabPrefixKeyb!=NULL) {
        (*KMap)->TabPrefixKeyb = (PrefixKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb)+Buff);
    }
    if ((*KMap)->TabNormPrefixKeyb!=NULL) {
        (*KMap)->TabNormPrefixKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabNormPrefixKeyb)+Buff);
    }
    if ((*KMap)->TabNormKeyb!=NULL) {
        (*KMap)->TabNormKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabNormKeyb)+Buff);
    }

    if ((*KMap)->TabNormKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbNorm; i++)
            (*KMap)->TabNormKeyb[i].Ptr = (unsigned char*)((unsigned int)((*KMap)->TabNormKeyb[i].Ptr)+Buff);
    }
    if ((*KMap)->TabNormPrefixKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbNormPrefix; i++)
            (*KMap)->TabNormPrefixKeyb[i].Ptr = (unsigned char*)((unsigned int)((*KMap)->TabNormPrefixKeyb[i].Ptr)+Buff);
    }
    if ((*KMap)->TabPrefixKeyb!=NULL) {
        for (i=0; i<(*KMap)->NbPrefix; i++) {
            (*KMap)->TabPrefixKeyb[i].TabNormKeyb = (NormKeyb*)((unsigned int)((*KMap)->TabPrefixKeyb[i].TabNormKeyb)+Buff);
        }
    }
    return 1;
}

void DestroyKbMAP(KbMAP *KM) {
    if (KM) free(KM);
}

////////////////////////////////////////////////
// Mouse ///////////////////////////////////////

int MsScanEvents = 0;
unsigned char MsInWindow = 0;

int  InstallMouse() {
    if (MsScanEvents == 1)
        return 1; // already installed
    if (SDL_LockMutex(mutexEvents) == 0) {
        MsZ = 0;
        ClearMsEvntsStack();
        EnableMsEvntsStack();
        MsScanEvents = 1;
        if (DgWindow != NULL) {
            if (DgWindow == SDL_GetMouseFocus()) {
                MsInWindow = 1;
                SDL_ShowCursor(SDL_DISABLE);
            } else {
                MsInWindow = 0;
                SDL_ShowCursor(SDL_ENABLE);
            }
            DgView defaultMsView;
            GetSurfView(RendSurf, &defaultMsView);
            SetMouseRView(&defaultMsView);
        }
        if (MsInWindow == 1) {
            SDL_GetMouseState(&MsX, &MsY);
            iSetMousePos(MsX, MsY);
            iPushMsEvent(MS_EVNT_MOUSE_MOVE);
        }

        SDL_UnlockMutex(mutexEvents);
    }
    return 1;
}

void UninstallMouse() {
    if (MsScanEvents == 0)
        return;
    if (SDL_LockMutex(mutexEvents) == 0) {
        MsScanEvents = 0;
        ClearMsEvntsStack();
        SDL_UnlockMutex(mutexEvents);
    }
}

int IsMouseWheelSupported() {
    return 1;
}

void PushMsEvent(unsigned int eventID) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iPushMsEvent(eventID);
        SDL_UnlockMutex(mutexEvents);
    }
}

void SetMouseRView(DgView *V) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iSetMouseRView(V);
        SDL_UnlockMutex(mutexEvents);
    }
}

void SetMouseOrg(int MsOrgX,int MsOrgY) {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iSetMouseOrg(MsOrgX, MsOrgY);
        SDL_UnlockMutex(mutexEvents);
    }
}

void EnableMsEvntsStack() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iEnableMsEvntsStack();
        SDL_UnlockMutex(mutexEvents);
    }
}

void DisableMsEvntsStack() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iDisableMsEvntsStack();
        SDL_UnlockMutex(mutexEvents);
    }
}

void ClearMsEvntsStack() {
    if (SDL_LockMutex(mutexEvents) == 0) {
        iClearMsEvntsStack();
        SDL_UnlockMutex(mutexEvents);
    }
}

int GetMsEvent(MouseEvent *MsEvnt) {
    int resMsEvent = 0;
    if (SDL_LockMutex(mutexEvents) == 0) {
        resMsEvent = iGetMsEvent(MsEvnt);
        SDL_UnlockMutex(mutexEvents);
    }
    return resMsEvent;
}





