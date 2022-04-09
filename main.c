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

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "SDL.h"

#include "DUGL.h"
#include "intrndugl.h"

#define DEFAULT_DBLBUFF_ENABLED false

int SDLEventHandler(void *data, SDL_Event* event);

SDL_Window *window = NULL;
SDL_Surface *surfaceW = NULL;
SDL_mutex *mutexEvents = NULL;
SDL_Surface *surf16bpp = NULL;
SDL_Surface *surfFront16bpp = NULL;
bool enableDoubleBuff = true;


int DgInit()
{
    mutexEvents = SDL_CreateMutex();
    if (mutexEvents == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "failed to create SDL_mutex\n");
        return 0;
    }

    /* Initialize SDL */
    if (SDL_Init(SDL_INIT_TIMER | SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_JOYSTICK | SDL_INIT_HAPTIC | SDL_INIT_GAMECONTROLLER) != 0) {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "SDL_Init fail : %s\n", SDL_GetError());
        return 0;
    }
    SDL_memset4(&CurSurf, 0, sizeof(DgSurf) / 4);
    SDL_memset4(&RendSurf, 0, sizeof(DgSurf) / 4);
    SDL_memset4(&RendFrontSurf, 0, sizeof(DgSurf) / 4);

    SDL_AddEventWatch(SDLEventHandler, NULL);
    if (!InitDWorkers(0)) {
		return 0;
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "failed to init DWorkers\n");
    }
    enableDoubleBuff = DEFAULT_DBLBUFF_ENABLED;

    return 1;
}

void DgQuit()
{
    if (mutexEvents != NULL)
    {
        if (SDL_LockMutex(mutexEvents) == 0)
        {
            SDL_DelEventWatch(SDLEventHandler, NULL);
            SDL_UnlockMutex(mutexEvents);
            SDL_DestroyMutex(mutexEvents);
            mutexEvents = NULL;
        }
    }
    DestroyDWorkers();
    if (window != NULL) {
		SDL_DestroyWindow(window);
		if (RendSurf.rlfb != 0)
			DestroySurf(&RendSurf);
		if (RendFrontSurf.rlfb != 0)
			DestroySurf(&RendFrontSurf);
    }
    SDL_Quit();
}

int SDLEventHandler(void *data, SDL_Event* event)
{
    DgScanEvents(event);
    return 0;
}

int  DgInitMainWindow(const char *title, int ResHz, int ResVt, char BitsPixel)
{
    return DgInitMainWindowX(title, ResHz, ResVt, BitsPixel, -1, -1, 0, 0, 0);
}

int DgInitMainWindowX(const char *title, int ResHz, int ResVt, char BitsPixel, int PosX, int PosY, bool FullScreen, bool Borderless, bool ResizeWin)
{
    int posX = SDL_WINDOWPOS_UNDEFINED;
    int posY = SDL_WINDOWPOS_UNDEFINED;
    Uint32 FlagCreate = 0;

    // Main windows already initialized ?
    if (window != NULL)
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


    window = SDL_CreateWindow(title, posX, posY, ResHz, ResVt, FlagCreate);
    if (window == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Window creation fail : %s\n",SDL_GetError());
        return 0;
    }
    surfaceW = SDL_GetWindowSurface(window);
    if (surfaceW == NULL)
    {
        SDL_LogError(SDL_LOG_CATEGORY_APPLICATION, "Window Surface creation fail : %s\n",SDL_GetError());
        return 0;
    }

    if (!CreateSurf(&RendSurf, ResHz, ResVt, 16))
        return 0;

    // create the render Surface 16bpp
    surf16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendSurf.rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
    if (surf16bpp == NULL) {
        SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
        return 0;
    }
    if (enableDoubleBuff) {
		if (!CreateSurf(&RendFrontSurf, ResHz, ResVt, 16))
			return 0;

		surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf.rlfb), ResHz, ResVt, 16, ResHz*2, SDL_PIXELFORMAT_RGB565);
		if (surfFront16bpp == NULL) {
			SDL_Log("SDL_CreateRGBSurfaceWithFormat() failed: %s", SDL_GetError());
			return 0;
		}
    }

	if (FullScreen) {
		SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN);
	}

    return 1;
}

void DgToggleFullScreen(bool fullScreen) {
	SDL_SetWindowFullscreen(window, (fullScreen) ? SDL_WINDOW_FULLSCREEN : 0);
}

bool DgIsFullScreen() {
	return ((SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN) != 0);
}

void DgCheckEvents() {
    SDL_PumpEvents();
}

void DgUpdateWindow()
{
	SDL_Surface *tmpSDLSurf = surf16bpp;
	DgSurf tmpSurf;
	surfaceW = SDL_GetWindowSurface(window);

    if (RendSurf.rlfb != 0 && surfaceW != NULL)
    {
        SDL_BlitSurface( tmpSDLSurf, NULL, surfaceW, NULL );
		SDL_UpdateWindowSurface(window);

		if (enableDoubleBuff) {
			SDL_memcpy4(&tmpSurf,&RendSurf, sizeof(DgSurf)/4);

			surf16bpp = surfFront16bpp;
			SDL_memcpy4(&RendSurf,&RendFrontSurf, sizeof(DgSurf)/4);

			surfFront16bpp = tmpSDLSurf;
			SDL_memcpy4(&RendFrontSurf,&tmpSurf, sizeof(DgSurf)/4);
		}
   }
}

void DgSetEnabledDoubleBuff(bool dblBuffEnabled) {
	if (enableDoubleBuff && !dblBuffEnabled) { // disable
		// destroy not required data
		if (RendFrontSurf.rlfb != 0) {
			DestroySurf(&RendFrontSurf);
			SDL_memset4(&RendFrontSurf, 0, sizeof(DgSurf));
		}
		if (surfFront16bpp != NULL) {
			SDL_FreeSurface(surfFront16bpp);
			surfFront16bpp = NULL;
		}

		enableDoubleBuff = false;
	} else if (enableDoubleBuff && !dblBuffEnabled) { // enable
		if (!CreateSurf(&RendFrontSurf, RendSurf.ResH, RendSurf.ResV, 16))
			return; // failed to enable double buff

		surfFront16bpp = SDL_CreateRGBSurfaceWithFormatFrom((void*)(RendFrontSurf.rlfb), RendSurf.ResH, RendSurf.ResV, 16, RendSurf.ResH*2, SDL_PIXELFORMAT_RGB565);
		if (surfFront16bpp == NULL) {
			DestroySurf(&RendFrontSurf);
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
      case 8:  return 1;
      case 15: return 2;
      case 16: return 2;
      case 24: return 3;
      case 32: return 4;
      default : return 0;
   }
}

void SetOrgSurf(DgSurf *S,int LOrgX,int LOrgY)
{	int dx,dy;
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

int CreateSurf(DgSurf *S, int ResHz, int ResVt, char BitsPixel)
{
    int cvlfb;
    int pixelsize = GetPixelSize(BitsPixel);

	S->vlfb=S->rlfb=S->OffVMem=0;
	if (pixelsize==0 || ResHz<=1 || ResVt<=1) return 0;
	cvlfb = (int)SDL_SIMDAlloc(ResHz*ResVt*pixelsize);
    if (cvlfb != 0)
    {
          S->vlfb=S->rlfb= cvlfb;
          S->OffVMem= -1;
          S->ResH= ResHz;
          S->ResV= ResVt;
          S->RMaxY= ResVt-1;
          S->RMaxX= S->MaxX= ResHz-1;
          S->RMinX= S->RMinY=  S->MaxY= S->MinX= 0;
          S->MinY= -ResVt+1;      //axe Y montant
          S->SizeSurf= ResHz*ResVt*pixelsize;
          S->Mask= 0;
          S->OrgX= 0;
          S->OrgY= ResVt-1;
          S->BitsPixel= BitsPixel;
          S->ScanLine= ResHz *pixelsize;
          S->NegScanLine = -(S->ScanLine);
          SetOrgSurf(S, 0, 0);
          return 1;
	}
	return 0;
}

void DestroySurf(DgSurf *S)
{
    if (S->rlfb!=0)
    {
        SDL_SIMDFree((void*)S->rlfb);
        SDL_memset4(S, 0, sizeof(DgSurf)/4);
	}
}

int CreateSurfBuff(DgSurf *S, int ResHz, int ResVt, char BitsPixel, void *Buff)
{
    if (S == NULL)
        return 0;
    SDL_memset4(S, 0, sizeof(DgSurf)/4);
    int pixelsize=GetPixelSize(BitsPixel);

 	if (pixelsize == 0 || ResHz <= 1 || ResVt <= 1 || Buff == NULL)
        return 0;
	S->vlfb = S->rlfb = (int)(Buff);
	S->OffVMem= -1;
	S->ResH= ResHz;
	S->ResV= ResVt;
	S->RMaxY= ResVt-1;
	S->RMaxX= S->MaxX= ResHz-1;
	S->RMinX= S->RMinY=  S->MaxY= S->MinX= 0;
	S->MinY= -ResVt+1;      //axis Y Up
	S->SizeSurf= ResHz*ResVt*pixelsize;
	S->OrgX= 0;
	S->OrgY= ResVt-1;
	S->BitsPixel= BitsPixel;
	S->ScanLine= ResHz *pixelsize;
	S->Mask= 0;
	S->NegScanLine = -(S->ScanLine);
	SetOrgSurf(S,0,0);
	return 1;
}

// View or (clipped area) handling

// sets DgSurf real View
void SetSurfView(DgSurf *S, DgView *V)
{
    int pixelsize = GetPixelSize(S->BitsPixel);

    S->OrgX= V->OrgX;
 	S->OrgY= V->OrgY;
	// limite reel dans l'ecran
	S->RMaxX= (V->MaxX<S->ResH) ? V->MaxX : S->ResH-1;
	S->RMaxY= (V->MaxY<S->ResV) ? V->MaxY : S->ResV-1;
	S->RMinX= (V->MinX>=0) ? V->MinX : 0;
	S->RMinY= (V->MinY>=0) ? V->MinY : 0;
	// limite par rapport a OrgX,OrgY
	S->MaxX= S->RMaxX-S->OrgX;
	S->MinX= S->RMinX-S->OrgX;
	S->MaxY= S->RMaxY-S->OrgY;
	S->MinY= S->RMinY-S->OrgY;
    if (pixelsize>1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// sets DgSurf relative View
void SetSurfRView(DgSurf *S, DgView *V)
{
    int pixelsize = GetPixelSize(S->BitsPixel);
 	S->OrgX= V->OrgX;
 	S->OrgY= V->OrgY;
	S->RMaxX= ((V->MaxX+S->OrgX)<S->ResH) ? V->MaxX+S->OrgX : S->ResH-1;
	S->RMaxY= ((V->MaxY+S->OrgY)<S->ResV) ? V->MaxY+S->OrgY : S->ResV-1;
	S->RMinX= ((V->MinX+S->OrgX)>=0) ? V->MinX+S->OrgX : 0;
	S->RMinY= ((V->MinY+S->OrgY)>=0) ? V->MinY+S->OrgY : 0;
	S->MaxX= S->RMaxX-S->OrgX;
	S->MinX= S->RMinX-S->OrgX;
	S->MaxY= S->RMaxY-S->OrgY;
	S->MinY= S->RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// sets View port clipped inside current DgSurf view port
void SetSurfInView(DgSurf *S, DgView *V)
{
    int pixelsize = GetPixelSize(S->BitsPixel);

	S->OrgX= V->OrgX;
 	S->OrgY= V->OrgY;
	// Real limits
	S->RMaxX= (V->MaxX<=S->RMaxX) ? V->MaxX : S->RMaxX;
	S->RMaxY= (V->MaxY<=S->RMaxY) ? V->MaxY : S->RMaxY;
	S->RMinX= (V->MinX>=S->RMinX) ? V->MinX : S->RMinX;
	S->RMinY= (V->MinY>=S->RMinY) ? V->MinY : S->RMinY;
	// Limits relative to current origin
	S->MaxX= S->RMaxX-S->OrgX;
	S->MinX= S->RMinX-S->OrgX;
	S->MaxY= S->RMaxY-S->OrgY;
	S->MinY= S->RMinY-S->OrgY;
    if (pixelsize>1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

// sets Real View port clipped inside current DgSurf real view port
void SetSurfInRView(DgSurf *S, DgView *V)
{
	int pixelsize = GetPixelSize(S->BitsPixel);

	S->OrgX= V->OrgX;
 	S->OrgY= V->OrgY;
	S->RMaxX= ((V->MaxX+S->OrgX)<=S->RMaxX) ? V->MaxX+S->OrgX : S->RMaxX;
	S->RMaxY= ((V->MaxY+S->OrgY)<=S->RMaxY) ? V->MaxY+S->OrgY : S->RMaxY;
	S->RMinX= ((V->MinX+S->OrgX)>=S->RMinX) ? V->MinX+S->OrgX : S->RMinX;
	S->RMinY= ((V->MinY+S->OrgY)>=S->RMinY) ? V->MinY+S->OrgY : S->RMinY;
	S->MaxX= S->RMaxX-S->OrgX;
	S->MinX= S->RMinX-S->OrgX;
	S->MaxY= S->RMaxY-S->OrgY;
	S->MinY= S->RMinY-S->OrgY;
    if (pixelsize > 1)
        S->vlfb= S->rlfb+(S->OrgX*pixelsize)-((S->OrgY-(S->ResV-1))*S->ResH*pixelsize);
    else
        S->vlfb= S->rlfb+S->OrgX-(S->OrgY-(S->ResV-1))*S->ResH;
}

void GetSurfRView(DgSurf *S, DgView *V)
{
    V->OrgX=S->OrgX;  V->OrgY=S->OrgY;
	V->MaxX=S->MaxX;  V->MaxY=S->MaxY;
	V->MinX=S->MinX;  V->MinY=S->MinY;
}

void GetSurfView(DgSurf *S, DgView *V)
{
    V->OrgX=S->OrgX;  V->OrgY=S->OrgY;
	V->MaxX=S->RMaxX; V->MaxY=S->RMaxY;
	V->MinX=S->RMinX; V->MinY=S->RMinY;
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
	  lineblnd16(x1,y1,x2,y2,bcol); return; }
	CBar[0]= CBar[6]= x2;
	CBar[2]= CBar[4]= x1;
	CBar[5]= CBar[7]= y1;
	CBar[1]= CBar[3]= y2;
	Poly16(&ACBar, NULL, POLY16_SOLID_BLND|POLY16_FLAG_DBL_SIDED, bcol);
}

void rect16(int x1,int y1,int x2,int y2,int rcol) {
    line16(x1,y1,x2,y1,rcol);
    if (y1 != y2)
    {
        line16(x1,y2,x2,y2,rcol);
        if (y2>y1) {
          line16(x1,y1+1,x1,y2-1,rcol);
          line16(x2,y1+1,x2,y2-1,rcol);
        }
        else {
            line16(x1,y1-1,x1,y2+1,rcol);
            line16(x2,y1-1,x2,y2+1,rcol);
        }
    }
}

void rectmap16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemap16(x1,y1,x2,y1,rcol,rmap);
    if (y1 != y2)
    {
        linemap16(x1,y2,x2,y2,rcol,rmap);
        if (y2>y1) {
          linemap16(x1,y1+1,x1,y2-1,rcol,rmap);
          linemap16(x2,y1+1,x2,y2-1,rcol,rmap);
        }
        else {
            linemap16(x1,y1-1,x1,y2+1,rcol,rmap);
            linemap16(x2,y1-1,x2,y2+1,rcol,rmap);
        }
    }
}

void rectblnd16(int x1,int y1,int x2,int y2,int rcol) {
    lineblnd16(x1,y1,x2,y1,rcol);
    if (y1 != y2)
    {
        lineblnd16(x1,y2,x2,y2,rcol);
        if (y2>y1) {
            lineblnd16(x1,y1+1,x1,y2-1,rcol);
            lineblnd16(x2,y1+1,x2,y2-1,rcol);
        }
        else {
            lineblnd16(x1,y1-1,x1,y2+1,rcol);
            lineblnd16(x2,y1-1,x2,y2+1,rcol);
        }
    }
}

void rectmapblnd16(int x1,int y1,int x2,int y2,int rcol,unsigned int rmap) {
    linemapblnd16(x1,y1,x2,y1,rcol,rmap);
    if (y1 != y2)
    {
        linemapblnd16(x1,y2,x2,y2,rcol,rmap);
        if (y2>y1) {
            linemapblnd16(x1,y1+1,x1,y2-1,rcol,rmap);
            linemapblnd16(x2,y1+1,x2,y2-1,rcol,rmap);
        }
        else {
            linemapblnd16(x1,y1-1,x1,y2+1,rcol,rmap);
            linemapblnd16(x2,y1-1,x2,y2+1,rcol,rmap);
        }
    }
}

// ============================
// EFFECTS & CONVERSION =======

void ConvSurf8ToSurf16Pal(DgSurf *S16Dst, DgSurf *S8Src,void *PalBGR1024)
{
    if (S8Src==NULL || S16Dst==NULL ||
	    S16Dst->BitsPixel!=16 || S8Src->BitsPixel!=8 ||
	    S8Src->ResH!=S16Dst->ResH ||
	    S8Src->ResV!=S16Dst->ResV) return;
	// convert buffers
	ConvB8ToB16Pal((void*)(S8Src->rlfb), (void*)(S16Dst->rlfb), S8Src->ResH, S8Src->ResV, PalBGR1024);
}

void BlurSurf16(DgSurf *S16Dst, DgSurf *S16Src)
{	if (S16Dst==NULL || S16Src==NULL ||
	    S16Dst->BitsPixel!=16 || S16Src->BitsPixel!=16 ||
	    S16Dst->ResH!=S16Src->ResH ||
	    S16Dst->ResV!=S16Src->ResV) return;
	Blur16((void*)(S16Dst->rlfb), (void*)(S16Src->rlfb), S16Src->ResH, S16Src->ResV, 0, (S16Src->ResV - 1));
}

// ==============================
// ===================== FONT ===

int  LoadMemFONT(FONT *F,void *In,int SizeIn)
{	HeadCHR hchr;
	int i,Size;
	void *Buff;
	if (SizeIn<(int)(sizeof(HeadCHR))) return 0;
	memcpy(&hchr,In,sizeof(HeadCHR));
	if (hchr.Sign!='RHCF') return 0;
	for (Size=0,i=1;i<256;i++)
	   Size+=((hchr.C[i].Lg<=32)?1:2)*hchr.C[i].Ht*4;
	if (hchr.SizeDataCar!=Size) return 0;
	if ((hchr.PtrBuff+hchr.SizeDataCar)<SizeIn) return 0;
	if ((Buff=SDL_malloc(hchr.SizeDataCar+sizeof(Caract)*256))==NULL) return 0;
	for (i=1;i<256;i++) {
        if (hchr.C[i].DatCar < hchr.SizeDataCar)
            hchr.C[i].DatCar+=((int)(Buff)+2048);
        else
            hchr.C[i].DatCar = 0;
	}
	memcpy(Buff,&hchr.C[0],sizeof(Caract)*256);
	memcpy((void*)(((int)(Buff)+2048)),(void*)((int)(In)+hchr.PtrBuff),hchr.SizeDataCar);
	F->FntPtr=(int)Buff;
	F->FntHaut=F->FntDistLgn=hchr.MaxHautFnt;
	F->FntLowPos=hchr.MinPlusLgn;   F->FntHighPos=hchr.MaxHautLgn;
	F->FntSens=hchr.SensFnt;	F->FntTab=8;
	return 1;
}

int LoadFONT(FONT *F,const char *FName)
{	HeadCHR hchr;
	int i,Size;
	void *Buff;
	FILE *InCHR;
	if ((InCHR=fopen(FName,"rb"))==NULL) return 0;
	if (fread(&hchr,sizeof(HeadCHR),1,InCHR)<1) { fclose(InCHR); return 0; }
	if (hchr.Sign!='RHCF') { fclose(InCHR); return 0; }
	for (Size=0,i=1;i<256;i++)
	   Size+=((hchr.C[i].Lg<=32)?1:2)*hchr.C[i].Ht*4;
	if (hchr.SizeDataCar!=Size) { fclose(InCHR); return 0; }

	if ((Buff=SDL_malloc(hchr.SizeDataCar+2048))==NULL)
	  { fclose(InCHR); return 0; }
	for (i=1;i<256;i++) {
        if (hchr.C[i].DatCar < hchr.SizeDataCar)
            hchr.C[i].DatCar+=((int)(Buff)+2048);
        else
            hchr.C[i].DatCar = 0;
	}
	memcpy(Buff,&hchr.C[0],sizeof(Caract)*256);
	fseek(InCHR,hchr.PtrBuff,SEEK_SET);
	if (fread((void*)((int)Buff+2048),hchr.SizeDataCar,1,InCHR)<1)
	  { free(Buff); fclose(InCHR); return 0; }
	F->FntPtr=(int)Buff;
	F->FntHaut=F->FntDistLgn=hchr.MaxHautFnt;
	F->FntLowPos=hchr.MinPlusLgn;   F->FntHighPos=hchr.MaxHautLgn;
	F->FntSens=hchr.SensFnt;	F->FntTab=8;

	fclose(InCHR);
	return 1;
}

void DestroyFONT(FONT *F)
{	if (F->FntPtr) SDL_free((void*)(F->FntPtr));
        F->FntHaut=F->FntDistLgn=F->FntLowPos=F->FntHighPos=F->FntSens=0;
	F->FntPtr=FntCol=0;
}

void ClearText()
{
    if (FntSens) FntX=MaxX;
	else FntX=MinX;
 	FntY=MaxY-FntHighPos;
}

void RViewClearText(DgView *V)
{
    if (FntSens) FntX=V->MaxX;
	else FntX=V->MinX;
 	FntY=V->MaxY-FntHighPos;
}

void SetTextAttrib(int TX,int TY,int TCol)
{	FntX=TX; 	FntY=TY;	FntCol=TCol;
}

void SetTextPos(int TX,int TY)
{	FntX=TX; 	FntY=TY;
}

void SetTextCol(int TCol)
{	FntCol=TCol;
}

int GetFntYMID() {
    return (MaxY+MinY)/2-FntHaut/2-FntLowPos;
}

int RViewGetFntYMID(DgView *V) {
    return (V->MaxY+V->MinY)/2-FntHaut/2-FntLowPos;
}

void OutText16XY(int TX,int TY,const char *str)
{	FntX=TX; 	FntY=TY;
	OutText16(str);
}

void OutText16ModeFormat(int Mode, char *midStr, unsigned int sizeMidStr, char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsprintf_s(midStr, sizeMidStr, fmt, args);
    va_end(args);
    OutText16Mode(midStr, Mode);
}

void OutText16Format(char *midStr, unsigned int sizeMidStr, char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsprintf_s(midStr, sizeMidStr, fmt, args);
    va_end(args);
    OutText16(midStr);
}

// Mode : 0 CurPos, 1 mid, 2 AjusteSrc, 3 AjusteI-src, 4 AjLeft, 5 AjRight
int  OutText16Mode(const char *str,int Mode)
{	int L,x;
	switch (Mode) {
	  case 0:
	    break;
	  case 1:
	    L=WidthText(str);
	    if (FntSens) FntX=(MinX+MaxX+L)/2;
	    else FntX=(MinX+MaxX-L)/2;
	    break;
	  case 2:
	    if (FntSens) FntX=MaxX;
	    else FntX=MinX;
	    break;
	  case 3:
	    L=WidthText(str);
	    if (FntSens) FntX=MinX+L;
	    else FntX=MaxX-L;
	    break;
	  case 4:
	    L=WidthText(str);
	    if (FntSens) FntX=MinX+L;
	    else FntX=MinX;
	    break;
	  case 5:
	    L=WidthText(str);
	    if (FntSens) FntX=MaxX;
	    else FntX=MaxX-L;
	    break;
	  default:
	    return 0;
	}
	x=FntX;
	OutText16(str);
	return x;
}

int  OutText16YMode(int TY,const char *str,int Mode)
{	FntY=TY;
	return OutText16Mode(str,Mode);
}

// Mode : 0 CurPos, 1 mid, 2 AjusteSrc, 3 AjusteI-src, 4 AjLeft, 5 AjRight
int  RViewOutText16Mode(DgView *V,const char *str,int Mode)
{
   DgView saveView;
   int x;
   GetSurfRView(&CurSurf, &saveView);
   x=OutText16Mode(str,Mode);
   SetSurfRView(&CurSurf, &saveView);
   return x;
}

int  RViewGetXOutTextMode(DgView *V,const char *str,int Mode)
{
    int L,x;

	switch (Mode)
	{
	  case 0:
  	    x=FntX; break;
	  case 1:
	    L=WidthText(str);
	    if (FntSens) x=(V->MinX+V->MaxX+L)/2;
	    else x=(V->MinX+V->MaxX-L)/2;
	    break;
	  case 2:
	    if (FntSens) x=V->MaxX;
	    else x=V->MinX;
	    break;
	  case 3:
	    L=WidthText(str);
	    if (FntSens) x=V->MinX+L;
	    else x=V->MaxX-L;
	    break;
	  case 4:
	    L=WidthText(str);
	    if (FntSens) x=V->MinX+L;
	    else x=V->MinX;
	    break;
	  case 5:
	    L=WidthText(str);
	    if (FntSens) x=V->MaxX;
	    else x=V->MaxX-L;
	    break;
	  default:
	    x = 0;
	}
	return x;
}

int  RViewOutText16YMode(DgView *V,int TY,const char *str,int Mode)
{	FntY=TY;
	return RViewOutText16Mode(V,str,Mode);
}

int  RViewOutText16XYMode(DgView *V,int TXY,int TY,const char *str)
{	FntX=TXY; FntY=TY;
	return RViewOutText16Mode(V,str,AJ_CUR_POS);
}

