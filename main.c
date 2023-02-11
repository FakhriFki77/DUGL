/*	Dust Ultimate Game Library (DUGL)
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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

#define DEFAULT_DBLBUFF_ENABLED false

int SDLEventHandler(void *data, SDL_Event* event);

SDL_Window *DgWindow = NULL;
SDL_Surface *surfaceW = NULL;
SDL_mutex *mutexEvents = NULL;
SDL_Surface *surf16bpp = NULL;
SDL_Surface *surfFront16bpp = NULL;
DgWindowResizeCallBack dgWindowResizeCallBack = NULL;
DgWindowResizeCallBack dgWindowPreResizeCallBack = NULL;
void *dgResizeWinMutex = NULL;
bool *dgRequestResizeWinMutex = NULL;
bool enableDoubleBuff = true;


int DgInit() {
    mutexEvents = SDL_CreateMutex();
    if (mutexEvents == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "failed to create SDL_mutex\n");
        return 0;
    }

    /* Initialize SDL */
    if (SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_Init fail : %s\n", SDL_GetError());
        return 0;
    }
    SDL_memset4(&CurSurf, 0, sizeof(DgSurf) / 4);
    SDL_memset4(&SrcSurf, 0, sizeof(DgSurf) / 4);
    RendSurf = NULL;
    RendFrontSurf = NULL;

    SDL_AddEventWatch(SDLEventHandler, NULL);
    if (!InitDWorkers(0)) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "failed to init DWorkers\n");
        return 0;
    }
    enableDoubleBuff = DEFAULT_DBLBUFF_ENABLED;

    return 1;
}

void DgQuit() {
    if (mutexEvents != NULL) {
        if (SDL_LockMutex(mutexEvents) == 0) {
            SDL_DelEventWatch(SDLEventHandler, NULL);
            SDL_UnlockMutex(mutexEvents);
            SDL_DestroyMutex(mutexEvents);
            mutexEvents = NULL;
        }
    }
    DestroyDWorkers();
    if (DgWindow != NULL) {
        SDL_DestroyWindow(DgWindow);
        if (RendSurf!=NULL && RendSurf->rlfb != 0) {
            DestroySurf(RendSurf);
            RendSurf = NULL;
            SDL_FreeSurface(surf16bpp);
            surf16bpp = NULL;

        }
        if (RendFrontSurf!=NULL && RendFrontSurf->rlfb != 0) {
            DestroySurf(RendFrontSurf);
            RendFrontSurf = NULL;
            SDL_FreeSurface(surfFront16bpp);
            surfFront16bpp = NULL;
        }
    }
    SDL_Quit();
}

void DgResizeRendSurf(int resH, int resV) {
    if (DgWindow != NULL) {
        if (RendSurf!=NULL && RendSurf->rlfb != 0) {
            DestroySurf(RendSurf);
            RendSurf = NULL;
            SDL_FreeSurface(surf16bpp);
            surf16bpp = NULL;

        }
        if (enableDoubleBuff && RendFrontSurf!=NULL && RendFrontSurf->rlfb != 0) {
            DestroySurf(RendFrontSurf);
            RendFrontSurf = NULL;
            SDL_FreeSurface(surfFront16bpp);
            surfFront16bpp = NULL;
        }

        // recreate the render Surface 16bpp
        if (!CreateSurf(&RendSurf, resH, resV, 16))
            return;
        surf16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendSurf->rlfb), resH, resV, 16, resH*2, SDL_PIXELFORMAT_RGB565);
        if (surf16bpp == NULL) {
            SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
            return;
        }
        if (enableDoubleBuff) {
            if (!CreateSurf(&RendFrontSurf, resH, resV, 16))
                return;

            surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf->rlfb), resH, resV, 16, resH*2, SDL_PIXELFORMAT_RGB565);
            if (surfFront16bpp == NULL) {
                SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
                return;
            }
        }
    }
}

int SDLEventHandler(void *data, SDL_Event* event) {
    DgScanEvents(event);
    return 0;
}

int  DgInitMainWindow(const char *title, int ResHz, int ResVt, char BitsPixel) {
    return DgInitMainWindowX(title, ResHz, ResVt, BitsPixel, -1, -1, 0, 0, 0);
}

int DgInitMainWindowX(const char *title, int ResHz, int ResVt, char BitsPixel, int PosX, int PosY, bool FullScreen, bool Borderless, bool ResizeWin) {
    int posX = SDL_WINDOWPOS_UNDEFINED;
    int posY = SDL_WINDOWPOS_UNDEFINED;
    Uint32 FlagCreate = 0;

    // Main windows already initialized ?
    if (DgWindow != NULL)
        return 0;

    if (BitsPixel != 16 || ResHz <= 1 || ResVt <= 1)
        return 0;
    if (PosX >= 0) posX = PosX;
    if (PosY >= 0) posY = PosY;

    FlagCreate |= SDL_WINDOW_SHOWN;
    if (Borderless)
        FlagCreate |= SDL_WINDOW_BORDERLESS;
    else {
        if (ResizeWin)
            FlagCreate |= SDL_WINDOW_RESIZABLE;
    }

    DgWindow = SDL_CreateWindow(title, posX, posY, ResHz, ResVt, FlagCreate);
    if (DgWindow == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Window creation fail : %s\n",SDL_GetError());
        return 0;
    }
    surfaceW = SDL_GetWindowSurface(DgWindow);
    if (surfaceW == NULL) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Window Surface creation fail : %s\n",SDL_GetError());
        return 0;
    }

    if (!CreateSurf(&RendSurf, ResHz, ResVt, 16))
        return 0;

    // create the render Surface 16bpp
    surf16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendSurf->rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
    if (surf16bpp == NULL) {
        SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
        return 0;
    }
    if (enableDoubleBuff) {
        if (!CreateSurf(&RendFrontSurf, ResHz, ResVt, 16))
            return 0;

        surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf->rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
        if (surfFront16bpp == NULL) {
            SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
            return 0;
        }
    }

    if (FullScreen) {
        SDL_SetWindowFullscreen(DgWindow, SDL_WINDOW_FULLSCREEN);
    }

    if (MsScanEvents == 1) {
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
                if (MsInWindow == 1) {
                    SDL_GetMouseState(&MsX, &MsY);
                    iSetMousePos(MsX, MsY);
                    iPushMsEvent(MS_EVNT_MOUSE_MOVE);
                }
            }
            SDL_UnlockMutex(mutexEvents);
        }
    }
    dgWindowResizeCallBack = NULL;
    dgWindowPreResizeCallBack = NULL;
    dgResizeWinMutex = NULL;
    dgRequestResizeWinMutex = NULL;

    return 1;
}

void DgSetMainWindowSize(int ResHz, int ResVt) {
    if (DgWindow != NULL) {
        SDL_SetWindowSize(DgWindow, ResHz, ResVt);
    }
}

void DgSetMainWindowMinSize(int minResHz, int minResVt) {
    if (DgWindow != NULL) {
        SDL_SetWindowMinimumSize(DgWindow, minResHz, minResVt);
    }
}

void DgSetMainWindowMaxSize(int maxResHz, int maxResVt) {
    if (DgWindow != NULL) {
        SDL_SetWindowMaximumSize(DgWindow, maxResHz, maxResVt);
    }
}

void DgGetMainWindowSize(int *ResHz, int *ResVt) {
    if (DgWindow != NULL) {
        SDL_GetWindowSize(DgWindow, ResHz, ResVt);
    }
}

void DgGetMainWindowMinSize(int *minResHz, int *minResVt) {
    if (DgWindow != NULL) {
        SDL_GetWindowMinimumSize(DgWindow, minResHz, minResVt);
    }
}

void DgGetMainWindowMaxSize(int *maxResHz, int *maxResVt) {
    if (DgWindow != NULL) {
        SDL_GetWindowMaximumSize(DgWindow, maxResHz, maxResVt);
    }
}

void DgSetMainWindowResizeCallBack(DgWindowResizeCallBack preresizeCallBack, DgWindowResizeCallBack resizeCallBack, void *resizeMutex, bool *requestResizeMutex) {
    if (DgWindow != NULL) {
        dgWindowResizeCallBack = resizeCallBack;
        dgWindowPreResizeCallBack = preresizeCallBack;
        dgResizeWinMutex = resizeMutex;
        dgRequestResizeWinMutex = requestResizeMutex;
    }
}

DgWindowResizeCallBack GetMainWindowResizeCallBack() {
    return dgWindowResizeCallBack;
}


void DgToggleFullScreen(bool fullScreen) {
    SDL_SetWindowFullscreen(DgWindow, (fullScreen) ? SDL_WINDOW_FULLSCREEN : 0);
}

bool DgIsFullScreen() {
    return ((SDL_GetWindowFlags(DgWindow) & SDL_WINDOW_FULLSCREEN) != 0);
}

void DgCheckEvents() {
    SDL_PumpEvents();
}

void DgSetWindowIcone(DgSurf *S) {
    if (DgWindow != NULL) {
        SDL_Surface *surf16Icone = SDL_CreateRGBSurfaceWithFormatFrom((void*)(S->rlfb), S->ResH, S->ResV, 16, S->ResH*2, SDL_PIXELFORMAT_RGB565);
        SDL_SetWindowIcon(DgWindow, surf16Icone);
        SDL_FreeSurface(surf16Icone);
    }
}

void DgUpdateWindow() {
    SDL_Surface *tmpSDLSurf = surf16bpp;
    DgSurf *tmpSurf;
    surfaceW = SDL_GetWindowSurface(DgWindow);

    if (RendSurf->rlfb != 0 && surfaceW != NULL) {
        SDL_BlitSurface( tmpSDLSurf, NULL, surfaceW, NULL );
        SDL_UpdateWindowSurface(DgWindow);

        if (enableDoubleBuff) {
            tmpSurf = RendSurf;

            surf16bpp = surfFront16bpp;
            RendSurf = RendFrontSurf;

            surfFront16bpp = tmpSDLSurf;
            RendFrontSurf = tmpSurf;
        }
    }
}

void DgSetEnabledDoubleBuff(bool dblBuffEnabled) {
    if (enableDoubleBuff && !dblBuffEnabled) { // disable
        // destroy not required data
        if (RendFrontSurf->rlfb != 0) {
            DestroySurf(RendFrontSurf);
            SDL_memset4(RendFrontSurf, 0, sizeof(DgSurf));
        }
        if (surfFront16bpp != NULL) {
            SDL_FreeSurface(surfFront16bpp);
            surfFront16bpp = NULL;
        }

        enableDoubleBuff = false;
    } else if (!enableDoubleBuff && dblBuffEnabled) { // enable
        if (!CreateSurf(&RendFrontSurf, RendSurf->ResH, RendSurf->ResV, 16))
            return; // failed to enable double buff

        surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf->rlfb), RendSurf->ResH, RendSurf->ResV, 16, RendSurf->ResH*2, SDL_PIXELFORMAT_RGB565);
        if (surfFront16bpp == NULL) {
            DestroySurf(RendFrontSurf);
            return; // failed 2
        }

        enableDoubleBuff = true;
    }
}

bool DgGetEnabledDoubleBuff() {
    return enableDoubleBuff;
}

int GetPixelSize(int bitsPixel) {
    switch (bitsPixel) {
    case 8:
        return 1;
    case 15:
        return 2;
    case 16:
        return 2;
    case 24:
        return 3;
    case 32:
        return 4;
    default :
        return 0;
    }
}

void SetOrgSurf(DgSurf *S,int LOrgX,int LOrgY) {
    int dx,dy;
    int pixelsize=GetPixelSize(S->BitsPixel);
    dx=LOrgX-S->OrgX;
    dy=LOrgY-S->OrgY;
    S->MinX-= dx;
    S->MaxX-= dx;
    S->MinY-= dy;
    S->MaxY-= dy;
    S->OrgX= LOrgX;
    S->OrgY= LOrgY;
    if (pixelsize>1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

int CreateSurf(DgSurf **S, int ResHz, int ResVt, char BitsPixel) {
    int cvlfb;
    int pixelsize = GetPixelSize(BitsPixel);

    if (pixelsize==0 || ResHz<=1 || ResVt<=1) return 0;

    if ((*S = (DgSurf*)SDL_SIMDAlloc(sizeof(DgSurf)+(ResHz*ResVt*pixelsize))) == NULL)
        return 0;

    SDL_memset4(*S, 0, sizeof(DgSurf)/4);

    cvlfb = (int)(&((char*)(*S))[sizeof(DgSurf)]);
    if (cvlfb != 0) {
        (*S)->vlfb=(*S)->rlfb= cvlfb;
        (*S)->ResH= ResHz;
        (*S)->ResV= ResVt;

        (*S)->MaxX= ResHz-1;
        (*S)->MaxY= (*S)->MinX= 0;
        (*S)->MinY= -ResVt+1;      // Y axis ascendent
        (*S)->SizeSurf= ResHz*ResVt*pixelsize;
        (*S)->Mask= 0;
        (*S)->OrgX= 0;
        (*S)->OrgY= ResVt-1;
        (*S)->BitsPixel= BitsPixel;
        (*S)->ScanLine= ResHz *pixelsize;
        (*S)->NegScanLine = -((*S)->ScanLine);
        SetOrgSurf(*S, 0, 0);
        return 1;
    }
    return 0;
}

void DestroySurf(DgSurf *S) {
    if (S->rlfb!=0) {
        SDL_memset4(S, 0, sizeof(DgSurf)/4);
        SDL_SIMDFree((void*)S);
    }
}

int CreateSurfBuff(DgSurf **S, int ResHz, int ResVt, char BitsPixel, void *Buff) {
    if ((*S = (DgSurf*)SDL_SIMDAlloc(sizeof(DgSurf))) == NULL)
        return 0;
    SDL_memset4(*S, 0, sizeof(DgSurf)/4);
    int pixelsize=GetPixelSize(BitsPixel);

    if (pixelsize == 0 || ResHz <= 1 || ResVt <= 1 || Buff == NULL)
        return 0;
    (*S)->vlfb = (*S)->rlfb = (int)(Buff);
    (*S)->ResH= ResHz;
    (*S)->ResV= ResVt;
    (*S)->MaxX= ResHz-1;
    (*S)->MaxY= (*S)->MinX= 0;
    (*S)->MinY= -ResVt+1;      //axis Y Up
    (*S)->SizeSurf= ResHz*ResVt*pixelsize;
    (*S)->OrgX= 0;
    (*S)->OrgY= ResVt-1;
    (*S)->BitsPixel= BitsPixel;
    (*S)->ScanLine= ResHz *pixelsize;
    (*S)->Mask= 0;
    (*S)->NegScanLine = -((*S)->ScanLine);
    SetOrgSurf(*S,0,0);
    return 1;
}

// View or (clipped area) handling


// sets DgSurf View
void SetSurfView(DgSurf *S, DgView *V) {
    int pixelsize = GetPixelSize(S->BitsPixel);
    // clip if required
    int RMaxX= ((V->MaxX+V->OrgX)<S->ResH) ? V->MaxX+V->OrgX : S->ResH-1;
    int RMaxY= ((V->MaxY+V->OrgY)<S->ResV) ? V->MaxY+V->OrgY : S->ResV-1;
    int RMinX= ((V->MinX+V->OrgX)>=0) ? V->MinX+V->OrgX : 0;
    int RMinY= ((V->MinY+V->OrgY)>=0) ? V->MinY+V->OrgY : 0;

    S->OrgX= V->OrgX;
    S->OrgY= V->OrgY;
    S->MaxX= RMaxX-S->OrgX;
    S->MinX= RMinX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinY= RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// sets DgSurf relative View Bounds (ignoring the new View Origin)
void SetSurfViewBounds(DgSurf *S, DgView *V) {
    // clip if required
    int RMaxX= ((V->MaxX+S->OrgX)<S->ResH) ? V->MaxX+S->OrgX : S->ResH-1;
    int RMaxY= ((V->MaxY+S->OrgY)<S->ResV) ? V->MaxY+S->OrgY : S->ResV-1;
    int RMinX= ((V->MinX+S->OrgX)>=0) ? V->MinX+S->OrgX : 0;
    int RMinY= ((V->MinY+S->OrgY)>=0) ? V->MinY+S->OrgY : 0;

    S->MaxX= RMaxX-S->OrgX;
    S->MinX= RMinX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinY= RMinY-S->OrgY;
}

// sets View port clipped inside current DgSurf view port
void SetSurfInView(DgSurf *S, DgView *V) {
    int pixelsize = GetPixelSize(S->BitsPixel);
    int RMaxX= S->MaxX+S->OrgX;
    int RMaxY= S->MaxY+S->OrgY;
    int RMinX= S->MinX+S->OrgX;
    int RMinY= S->MinY+S->OrgY;

    // clip View if required
    if ((V->MaxX+V->OrgX)<RMaxX) {
        RMaxX = V->MaxX+V->OrgX;
    }
    if ((V->MaxY+V->OrgY)<RMaxY) {
        RMaxY= V->MaxY+V->OrgY;
    }
    if ((V->MinX+V->OrgX)>RMinX) {
        RMinX= V->MinX+V->OrgX;
    }
    if ((V->MinY+V->OrgY)>RMinY) {
        RMinY= V->MinY+V->OrgY;
    }
    S->OrgX= V->OrgX;
    S->OrgY= V->OrgY;
    S->MaxX= RMaxX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinX= RMinX-S->OrgX;
    S->MinY= RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// sets View port Bounds clipped inside current DgSurf view port (ignoring the new View Origin)
void SetSurfInViewBounds(DgSurf *S, DgView *V) {
    int RMaxX= S->MaxX+S->OrgX;
    int RMaxY= S->MaxY+S->OrgY;
    int RMinX= S->MinX+S->OrgX;
    int RMinY= S->MinY+S->OrgY;

    // clip View if required
    if ((V->MaxX+S->OrgX)<RMaxX) {
        RMaxX = V->MaxX+S->OrgX;
    }
    if ((V->MaxY+S->OrgY)<RMaxY) {
        RMaxY= V->MaxY+S->OrgY;
    }
    if ((V->MinX+S->OrgX)>RMinX) {
        RMinX= V->MinX+S->OrgX;
    }
    if ((V->MinY+S->OrgY)>RMinY) {
        RMinY= V->MinY+S->OrgY;
    }
    S->MaxX= RMaxX-S->OrgX;
    S->MaxY= RMaxY-S->OrgY;
    S->MinX= RMinX-S->OrgX;
    S->MinY= RMinY-S->OrgY;
}

void GetSurfView(DgSurf *S, DgView *V) {
    SDL_memcpy4(V, &S->OrgX, sizeof(DgView)/4);
}

void Bar16(void *Pt1,void *Pt2,int bcol) {
    bar16(((int*)(Pt1))[0], ((int*)(Pt1))[1], ((int*)(Pt2))[0], ((int*)(Pt2))[1], bcol);
}

int CBar[8], ACBar[5] = { 4, (int)(&CBar[0]), (int)(&CBar[2]), (int)(&CBar[4]), (int)(&CBar[6]) };

void bar16(int x1,int y1,int x2,int y2,int bcol) {
    if (x1==x2 || y1==y2) {
        line16(x1,y1,x2,y2,bcol);
        return;
    }
    CBar[0]= CBar[6]= x2;
    CBar[2]= CBar[4]= x1;
    CBar[5]= CBar[7]= y1;
    CBar[1]= CBar[3]= y2;
    Poly16(&ACBar, NULL, POLY16_SOLID|POLY16_FLAG_DBL_SIDED, bcol);
}

void BarBlnd16(void *Pt1,void *Pt2,int bcol) {
    barblnd16(((int*)(Pt1))[0], ((int*)(Pt1))[1],
              ((int*)(Pt2))[0],((int*)(Pt2))[1], bcol);
}
void barblnd16(int x1,int y1,int x2,int y2,int bcol) {
    if (x1==x2 || y1==y2) {
        lineblnd16(x1,y1,x2,y2,bcol);
        return;
    }
    CBar[0]= CBar[6]= x2;
    CBar[2]= CBar[4]= x1;
    CBar[5]= CBar[7]= y1;
    CBar[1]= CBar[3]= y2;
    Poly16(&ACBar, NULL, POLY16_SOLID_BLND|POLY16_FLAG_DBL_SIDED, bcol);
}

void rect16(int x1,int y1,int x2,int y2,int rcol) {
    line16(x1,y1,x2,y1,rcol);
    if (y1 != y2) {
        line16(x1,y2,x2,y2,rcol);
        if (y2>y1) {
            line16(x1,y1+1,x1,y2-1,rcol);
            line16(x2,y1+1,x2,y2-1,rcol);
        } else {
            line16(x1,y1-1,x1,y2+1,rcol);
            line16(x2,y1-1,x2,y2+1,rcol);
        }
    }
}

void rectmap16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemap16(x1,y1,x2,y1,rcol,rmap);
    if (y1 != y2) {
        linemap16(x1,y2,x2,y2,rcol,rmap);
        if (y2>y1) {
            linemap16(x1,y1+1,x1,y2-1,rcol,rmap);
            linemap16(x2,y1+1,x2,y2-1,rcol,rmap);
        } else {
            linemap16(x1,y1-1,x1,y2+1,rcol,rmap);
            linemap16(x2,y1-1,x2,y2+1,rcol,rmap);
        }
    }
}

void rectblnd16(int x1,int y1,int x2,int y2,int rcol) {
    lineblnd16(x1,y1,x2,y1,rcol);
    if (y1 != y2) {
        lineblnd16(x1,y2,x2,y2,rcol);
        if (y2>y1) {
            lineblnd16(x1,y1+1,x1,y2-1,rcol);
            lineblnd16(x2,y1+1,x2,y2-1,rcol);
        } else {
            lineblnd16(x1,y1-1,x1,y2+1,rcol);
            lineblnd16(x2,y1-1,x2,y2+1,rcol);
        }
    }
}

void rectmapblnd16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemapblnd16(x1,y1,x2,y1,rcol,rmap);
    if (y1 != y2) {
        linemapblnd16(x1,y2,x2,y2,rcol,rmap);
        if (y2>y1) {
            linemapblnd16(x1,y1+1,x1,y2-1,rcol,rmap);
            linemapblnd16(x2,y1+1,x2,y2-1,rcol,rmap);
        } else {
            linemapblnd16(x1,y1-1,x1,y2+1,rcol,rmap);
            linemapblnd16(x2,y1-1,x2,y2+1,rcol,rmap);
        }
    }
}

// ============================
// EFFECTS & CONVERSION =======

void ConvSurf8ToSurf16Pal(DgSurf *S16Dst, DgSurf *S8Src,void *PalBGR1024) {
    if (S8Src==NULL || S16Dst==NULL ||
            S16Dst->BitsPixel!=16 || S8Src->BitsPixel!=8 ||
            S8Src->ResH!=S16Dst->ResH ||
            S8Src->ResV!=S16Dst->ResV) return;
    // convert buffers
    ConvB8ToB16Pal((void*)(S8Src->rlfb), (void*)(S16Dst->rlfb), S8Src->ResH, S8Src->ResV, PalBGR1024);
}

void BlurSurf16(DgSurf *S16Dst, DgSurf *S16Src) {
    if (S16Dst==NULL || S16Src==NULL ||
            S16Dst->BitsPixel!=16 || S16Src->BitsPixel!=16 ||
            S16Dst->ResH!=S16Src->ResH ||
            S16Dst->ResV!=S16Src->ResV) return;
    Blur16((void*)(S16Dst->rlfb), (void*)(S16Src->rlfb), S16Src->ResH, S16Src->ResV, 0, (S16Src->ResV - 1));
}
