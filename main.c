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
SDL_Renderer *vsyncRenderer = NULL;
SDL_Texture *vsyncTexture = NULL;
SDL_DisplayMode orgDispMode;
SDL_DisplayMode wantedFullDispMode;
SDL_DisplayMode setFullDispMode;
DgWindowResizeCallBack dgWindowResizeCallBack = NULL;
DgWindowResizeCallBack dgWindowPreResizeCallBack = NULL;
void *dgResizeWinMutex = NULL;
bool *dgRequestResizeWinMutex = NULL;
bool enableDoubleBuff = false;
bool dgEnableFullScreen = false;
int dgLastErrID = 0;

int DgInit() {
    /* Initialize SDL */
    if (SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK | SDL_INIT_GAMECONTROLLER) != 0) {
        dgLastErrID = DG_ERRS_SYSTEM_INIT_FAIL;
        return 0;
    }
    SDL_memset4(&CurSurf, 0, sizeof(DgSurf) / 4);
    SDL_memset4(&SrcSurf, 0, sizeof(DgSurf) / 4);
    RendSurf = NULL;
    RendFrontSurf = NULL;

    SDL_AddEventWatch(SDLEventHandler, NULL);
    if (!InitDWorkers(0)) {
        dgLastErrID = DG_ERSS_DWORKERS_INIT_FAIL;
        return 0;
    }
    enableDoubleBuff = DEFAULT_DBLBUFF_ENABLED;

    mutexEvents = SDL_CreateMutex();
    if (mutexEvents == NULL) {
        dgLastErrID = DG_ERSS_EVENT_MUTEX_INIT_FAIL;
        return 0;
    }

    return 1;
}

void DgQuit() {
    // if full screen enabled - revert to original screen state
    if (dgEnableFullScreen) {
        DgToggleFullScreen(false);
        DgCheckEvents();
    }
    if (mutexEvents != NULL) {
        if (SDL_LockMutex(mutexEvents) == 0) {
            SDL_DelEventWatch(SDLEventHandler, NULL);
            SDL_UnlockMutex(mutexEvents);
            SDL_DestroyMutex(mutexEvents);
            mutexEvents = NULL;
        }
    }
    // if timer installed uninstall it
    if (DgTimerFreq > 0) {
        DgUninstallTimer();
    }
    DestroyDWorkers();
    if (vsyncTexture != NULL) {
        SDL_DestroyTexture(vsyncTexture);
        vsyncTexture = NULL;
    }
    if (vsyncRenderer != NULL) {
        SDL_DestroyRenderer(vsyncRenderer);
        vsyncRenderer = NULL;
    }
    if (DgWindow != NULL) {
        SDL_DestroyWindow(DgWindow);
        DgWindow = NULL;
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

int DgGetLastErr() {
    return dgLastErrID;
}

int dgCurDisplayMode = -1, dgDisplayModeCount = 0, dgDisplayInUse = 0;
SDL_DisplayMode dgMode;

int DgGetFirstDisplayMode(int *width, int *height, int *bpp, int *refreshRate) {
    if (DgWindow != NULL && RendSurf != NULL) {
        dgDisplayInUse = SDL_GetWindowDisplayIndex(DgWindow);
        if (dgDisplayInUse >= 0) {
            dgDisplayModeCount = SDL_GetNumDisplayModes(dgDisplayInUse);
            if (dgDisplayModeCount > 0 && SDL_GetDisplayMode(dgDisplayInUse, 0, &dgMode) == 0) {
                *width = dgMode.w;
                *height = dgMode.h;
                *bpp = SDL_BITSPERPIXEL(dgMode.format);
                *refreshRate = dgMode.refresh_rate;
                dgCurDisplayMode = 1;
                return dgDisplayModeCount;
            }
        }
    }

    dgDisplayModeCount = 0;
    dgCurDisplayMode = -1;
    return 0;
}


bool DgGetNextDisplayMode(int *width, int *height, int *bpp, int *refreshRate) {
    if (dgCurDisplayMode > 0 && dgCurDisplayMode < dgDisplayModeCount) {
        if (SDL_GetDisplayMode(dgDisplayInUse, dgCurDisplayMode, &dgMode) == 0) {
            *width = dgMode.w;
            *height = dgMode.h;
            *bpp = SDL_BITSPERPIXEL(dgMode.format);
            *refreshRate = dgMode.refresh_rate;
            dgCurDisplayMode++;
            return true;
        }
    }
    dgDisplayModeCount = 0;
    dgCurDisplayMode = -1;
    return false;
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
        if (!CreateSurf(&RendSurf, resH, resV, 16)) {
            return;
        }
        surf16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendSurf->rlfb), resH, resV, 16, resH*2, SDL_PIXELFORMAT_RGB565);
        if (surf16bpp == NULL) {
            dgLastErrID = DG_ERSS_FAIL_CREATE_SYSTEM_RGB_SURF;
            return;
        }
        if (enableDoubleBuff) {
            if (!CreateSurf(&RendFrontSurf, resH, resV, 16)) {
                return;
            }
            surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf->rlfb), resH, resV, 16, resH*2, SDL_PIXELFORMAT_RGB565);
            if (surfFront16bpp == NULL) {
                dgLastErrID = DG_ERSS_FAIL_CREATE_SYSTEM_RGB_SURF;
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
    if (ResizeWin)
        FlagCreate |= SDL_WINDOW_RESIZABLE;

    if (SDL_GetCurrentDisplayMode(0, &orgDispMode) != 0) {
        dgLastErrID = DG_ERSS_FAIL_QUERY_DISPLAY_MODE;
        return 0;
    }

    DgWindow = SDL_CreateWindow(title, posX, posY, ResHz, ResVt, FlagCreate);
    if (DgWindow == NULL) {
        dgLastErrID = DG_ERSS_WINDOW_CREATION_FAIL;
        return 0;
    }
    surfaceW = SDL_GetWindowSurface(DgWindow);
    if (surfaceW == NULL) {
        dgLastErrID = DG_ERSS_WINDOW_SURFACE_CREATION_FAIL;
        return 0;
    }

    // VSync
    vsyncRenderer = SDL_CreateSoftwareRenderer(surfaceW);
    if (vsyncRenderer != NULL) {
        SDL_RenderSetVSync(vsyncRenderer, 1);
        vsyncTexture = SDL_CreateTexture(vsyncRenderer, surfaceW->format->format, SDL_TEXTUREACCESS_STREAMING, 1, 1);
        if (vsyncTexture == NULL) {
            SDL_DestroyRenderer(vsyncRenderer);
            vsyncRenderer = NULL;
        }
    }

    if (!CreateSurf(&RendSurf, ResHz, ResVt, 16))
        return 0;

    // create the render Surface 16bpp
    surf16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendSurf->rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
    if (surf16bpp == NULL) {
        dgLastErrID = DG_ERSS_FAIL_CREATE_SYSTEM_RGB_SURF;
        return 0;
    }
    if (enableDoubleBuff) {
        if (!CreateSurf(&RendFrontSurf, ResHz, ResVt, 16))
            return 0;

        surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf->rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
        if (surfFront16bpp == NULL) {
            dgLastErrID = DG_ERSS_FAIL_CREATE_SYSTEM_RGB_SURF;
            return 0;
        }
    }

    dgEnableFullScreen = false;
    if (FullScreen) {
        DgToggleFullScreen(true);
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

void DgSetMainWindowResizeCallBack(DgWindowResizeCallBack preresizeCallBack, DgWindowResizeCallBack resizeCallBack, PDMutex resizeMutex, bool *requestResizeMutex) {
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

int DgPreferredFullSwidth = 0, DgPreferredFullSheight = 0, DgPreferredFullSrefreshRate = 0;
int DgNFSWidth = 0, DgNFSHeight = 0;

void DgToggleFullScreen(bool fullScreen) {
    if (!DgWindow || RendSurf == NULL)
        return;
    bool RecreateVSyncTexture = false;

    if (fullScreen && !dgEnableFullScreen) {
        wantedFullDispMode.w = (DgPreferredFullSwidth > 0) ? DgPreferredFullSwidth : RendSurf->ResH;
        wantedFullDispMode.h = (DgPreferredFullSheight > 0) ? DgPreferredFullSheight : RendSurf->ResV;
        wantedFullDispMode.format = SDL_PIXELFORMAT_RGB565;
        wantedFullDispMode.refresh_rate = (DgPreferredFullSrefreshRate > 0) ? DgPreferredFullSrefreshRate : 0;
        wantedFullDispMode.driverdata = 0;
        DgNFSWidth = RendSurf->ResH;
        DgNFSHeight = RendSurf->ResV;

        if (SDL_GetClosestDisplayMode(SDL_GetWindowDisplayIndex(DgWindow), &wantedFullDispMode, &setFullDispMode) == NULL)
            return; // fail
        SDL_SetWindowDisplayMode(DgWindow, &setFullDispMode);
        SDL_SetWindowFullscreen(DgWindow, SDL_WINDOW_FULLSCREEN);
        dgEnableFullScreen = true;
        RecreateVSyncTexture = true;
    } else if (!fullScreen && dgEnableFullScreen) {
        SDL_SetWindowDisplayMode(DgWindow, &orgDispMode);
        SDL_SetWindowSize(DgWindow, DgNFSWidth, DgNFSHeight);
        SDL_SetWindowFullscreen(DgWindow, 0);
        dgEnableFullScreen = false;
        RecreateVSyncTexture = true;
    }
    if (RecreateVSyncTexture && vsyncRenderer != NULL && vsyncTexture != NULL) {
        // destroy the old renderer/texture
        SDL_DestroyTexture(vsyncTexture);
        SDL_DestroyRenderer(vsyncRenderer);
        vsyncTexture = NULL;
        vsyncRenderer = NULL;
        // get the new surface
        surfaceW = SDL_GetWindowSurface(DgWindow);
        // create the new texture
        vsyncRenderer = SDL_CreateSoftwareRenderer(surfaceW);
        if (vsyncRenderer != NULL) {
            SDL_RenderSetVSync(vsyncRenderer, SDL_TRUE);
            vsyncTexture = SDL_CreateTexture(vsyncRenderer, surfaceW->format->format, SDL_TEXTUREACCESS_STREAMING, 1, 1);
            if (vsyncTexture == NULL) {
                SDL_DestroyRenderer(vsyncRenderer);
                vsyncRenderer = NULL;
            }
        }
    }
}

void DgWaitVSync() {
    if (vsyncRenderer == NULL || vsyncTexture == NULL)
        return; // failed

    SDL_Rect rect; rect.h=1; rect.w=1; rect.x=0; rect.y=0;
    SDL_RenderCopy(vsyncRenderer, vsyncTexture, NULL, &rect);
    SDL_RenderPresent(vsyncRenderer);
}

bool DgIsFullScreen() {
    return (DgWindow != NULL && (SDL_GetWindowFlags(DgWindow) & SDL_WINDOW_FULLSCREEN) != 0);
}

void DgSetPreferredFullScreenMode(int width, int height, int refreshRate) {
    DgPreferredFullSwidth = (width <= 0) ? 0 : width;
    DgPreferredFullSheight = (height <= 0) ? 0 : height;
    DgPreferredFullSrefreshRate = (refreshRate <= 0) ? 0 : refreshRate;
}

void DgGetPreferredFullScreenMode(int *width, int *height, int *refreshRate) {
    if (width != NULL) {
        *width = DgPreferredFullSwidth;
    }
    if (height != NULL) {
        *height = DgPreferredFullSheight;
    }
    if (refreshRate != NULL) {
        *refreshRate = DgPreferredFullSrefreshRate;
    }
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
    int pixelsize = GetPixelSize(BitsPixel);

    if (pixelsize==0 || ResHz<MIN_DGSURF_WIDTH || ResVt<MIN_DGSURF_HEIGHT) {
        dgLastErrID = DG_ERSS_INVALID_DGSURF_FORMAT;
        return 0;
    }

    if ((*S = (DgSurf*)SDL_SIMDAlloc(sizeof(DgSurf)+(ResHz*ResVt*pixelsize))) == NULL) {
        dgLastErrID = DG_ERSS_NO_MEM;
        return 0;
    }

    SDL_memset4(*S, 0, sizeof(DgSurf)/4);

    (*S)->vlfb=(*S)->rlfb= (int)(&((char*)(*S))[sizeof(DgSurf)]);
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

void DestroySurf(DgSurf *S) {
    if (S->rlfb!=0) {
        SDL_memset4(S, 0, sizeof(DgSurf)/4);
        SDL_SIMDFree((void*)S);
    }
}

int CreateSurfBuff(DgSurf **S, int ResHz, int ResVt, char BitsPixel, void *Buff) {
    if ((*S = (DgSurf*)SDL_SIMDAlloc(sizeof(DgSurf))) == NULL) {
        dgLastErrID = DG_ERSS_NO_MEM;
        return 0;
    }
    SDL_memset4(*S, 0, sizeof(DgSurf)/4);
    int pixelsize=GetPixelSize(BitsPixel);

    if (pixelsize == 0 || ResHz<MIN_DGSURF_WIDTH || ResVt<MIN_DGSURF_HEIGHT || Buff == NULL) {
        free(*S);
        *S = NULL;
        dgLastErrID = DG_ERSS_INVALID_DGSURF_FORMAT;
        return 0;
    }
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

void bar16(int x1,int y1,int x2,int y2,int bcol) {
    Bar16(&x1, &x2, bcol);
}

void barblnd16(int x1,int y1,int x2,int y2,int bcol) {
    BarBlnd16(&x1, &x2, bcol);
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
