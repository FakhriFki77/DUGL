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


int  LoadMemFONT(FONT *F,void *In,int SizeIn) {
    HeadCHR hchr;
    int i,Size;
    void *Buff;
    if (SizeIn<(int)(sizeof(HeadCHR))) return 0;
    memcpy(&hchr,In,sizeof(HeadCHR));
    if (hchr.Sign!='RHCF') return 0;
    for (Size=0,i=1; i<256; i++)
        Size+=((hchr.C[i].Lg<=32)?1:2)*hchr.C[i].Ht*4;
    if (hchr.SizeDataCar!=Size) return 0;
    if ((hchr.PtrBuff+hchr.SizeDataCar)<SizeIn) return 0;
    if ((Buff=SDL_malloc(hchr.SizeDataCar+sizeof(Caract)*256))==NULL) return 0;
    for (i=1; i<256; i++) {
        if (hchr.C[i].DatCar < hchr.SizeDataCar)
            hchr.C[i].DatCar+=((int)(Buff)+2048);
        else
            hchr.C[i].DatCar = 0;
    }
    memcpy(Buff,&hchr.C[0],sizeof(Caract)*256);
    memcpy((void*)(((int)(Buff)+2048)),(void*)((int)(In)+hchr.PtrBuff),hchr.SizeDataCar);
    F->FntPtr=(int)Buff;
    F->FntHaut=F->FntDistLgn=hchr.MaxHautFnt;
    F->FntLowPos=hchr.MinPlusLgn;
    F->FntHighPos=hchr.MaxHautLgn;
    F->FntSens=hchr.SensFnt;
    F->FntTab=8;
    return 1;
}

int LoadFONT(FONT *F,const char *FName) {
    HeadCHR hchr;
    int i,Size;
    void *Buff;
    FILE *InCHR;
    if ((InCHR = fopen(FName,"rb"))==NULL) return 0;
    if (fread(&hchr,sizeof(HeadCHR),1,InCHR)<1) {
        fclose(InCHR);
        return 0;
    }
    if (hchr.Sign!='RHCF') {
        fclose(InCHR);
        return 0;
    }
    for (Size=0,i=1; i<256; i++)
        Size+=((hchr.C[i].Lg<=32)?1:2)*hchr.C[i].Ht*4;
    if (hchr.SizeDataCar!=Size) {
        fclose(InCHR);
        return 0;
    }

    if ((Buff=SDL_malloc(hchr.SizeDataCar+2048))==NULL) {
        fclose(InCHR);
        return 0;
    }
    for (i=1; i<256; i++) {
        if (hchr.C[i].DatCar < hchr.SizeDataCar)
            hchr.C[i].DatCar+=((int)(Buff)+2048);
        else
            hchr.C[i].DatCar = 0;
    }
    memcpy(Buff,&hchr.C[0],sizeof(Caract)*256);
    fseek(InCHR,hchr.PtrBuff,SEEK_SET);
    if (fread((void*)((int)Buff+2048),hchr.SizeDataCar,1,InCHR)<1) {
        free(Buff);
        fclose(InCHR);
        return 0;
    }
    F->FntPtr=(int)Buff;
    F->FntHaut=F->FntDistLgn=hchr.MaxHautFnt;
    F->FntLowPos=hchr.MinPlusLgn;
    F->FntHighPos=hchr.MaxHautLgn;
    F->FntSens=hchr.SensFnt;
    F->FntTab=8;

    fclose(InCHR);
    return 1;
}

void DestroyFONT(FONT *F) {
    if (F->FntPtr) SDL_free((void*)(F->FntPtr));
    F->FntHaut=F->FntDistLgn=F->FntLowPos=F->FntHighPos=F->FntSens=0;
    F->FntPtr=FntCol=0;
}

void ClearText() {
    if (FntSens) FntX=MaxX;
    else FntX=MinX;
    FntY=MaxY-FntHighPos;
}

void ViewClearText(DgView *V) {
    if (FntSens) FntX=V->MaxX;
    else FntX=V->MinX;
    FntY=V->MaxY-FntHighPos;
}

void SetTextAttrib(int TX,int TY,int TCol) {
    FntX=TX;
    FntY=TY;
    FntCol=TCol;
}

void SetTextPos(int TX,int TY) {
    FntX=TX;
    FntY=TY;
}

void SetTextCol(int TCol) {
    FntCol=TCol;
}

int GetFntYMID() {
    return (MaxY+MinY)/2-FntHaut/2-FntLowPos;
}

int ViewGetFntYMID(DgView *V) {
    return (V->MaxY+V->MinY)/2-FntHaut/2-FntLowPos;
}

void OutText16XY(int TX,int TY,const char *str) {
    FntX=TX;
    FntY=TY;
    OutText16(str);
}

void OutText16ModeFormat(int Mode, char *midStr, unsigned int sizeMidStr, char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsprintf(midStr, fmt, args);
    va_end(args);
    OutText16Mode(midStr, Mode);
}

void OutText16Format(char *midStr, unsigned int sizeMidStr, char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsprintf(midStr, fmt, args);
    va_end(args);
    OutText16(midStr);
}

// Mode : 0 CurPos, 1 mid, 2 AjusteSrc, 3 AjusteI-src, 4 AjLeft, 5 AjRight
int  OutText16Mode(const char *str,int Mode) {
    int L,x;
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

int  OutText16YMode(int TY,const char *str,int Mode) {
    FntY=TY;
    return OutText16Mode(str,Mode);
}

// Mode : 0 CurPos, 1 mid, 2 AjusteSrc, 3 AjusteI-src, 4 AjLeft, 5 AjRight
int  ViewOutText16Mode(DgView *V,const char *str,int Mode) {
    DgView saveView;
    int x;
    GetSurfView(&CurSurf, &saveView);
    x=OutText16Mode(str,Mode);
    SetSurfView(&CurSurf, &saveView);
    return x;
}

int  ViewGetXOutTextMode(DgView *V,const char *str,int Mode) {
    int L,x;

    switch (Mode) {
    case 0:
        x=FntX;
        break;
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

int  ViewOutText16YMode(DgView *V,int TY,const char *str,int Mode) {
    FntY=TY;
    return ViewOutText16Mode(V,str,Mode);
}

int  ViewOutText16XYMode(DgView *V,int TXY,int TY,const char *str) {
    FntX=TXY;
    FntY=TY;
    return ViewOutText16Mode(V,str,AJ_CUR_POS);
}

