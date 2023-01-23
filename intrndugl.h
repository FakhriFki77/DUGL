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

    contact: libdugl@hotmail.com    */

#ifndef INTRNDUGL_H_INCLUDED
#define INTRNDUGL_H_INCLUDED

#define SYNCH_HST_SIZE  32

#ifdef __cplusplus
extern "C" {
#endif

typedef struct
{
    unsigned int TimeHst[SYNCH_HST_SIZE];
    float Freq,  // freq / per sec
        LastPos;
    unsigned int FirstTimeValue, LastTimeValue;
    unsigned int NbNullSynch, LastSynchNull, LastNbNullSynch;
    unsigned int hstNbItems, hstIdxDeb, hstIdxFin;
} SynchTime;

//************FORMAT ** BMP**************************
typedef struct __attribute__ ((packed))
{   short           Sign; // == 'BM'
    unsigned int   SizeFile; // size in bytes of the file
    short           Reserved0; // 0
    short           Reserved1; // 0
    unsigned int   DataOffset;
} HeadBMP;
typedef struct __attribute__((packed))
{   unsigned int    SizeInfo, // size in bytes of the info struct
                    ImgWidth,
                    ImgHeight;
    short           Planes, // == 1
                    BitsPixel; // bits per pixel
    unsigned int    Compression, // == 0 no compression
                    SizeCompData, // == 0 no compression or the size in byte of the comp data
                    PixXPerMeter, // == 0
                    PixYPerMeter, // == 0
                    NBUsedColors, // == 0
                    ImportantColors; // == 0 if all colors important
} InfoBMP;

//************FORMAT ** PCX**************************
typedef struct __attribute__((packed))
{   char    Sign;
    char    Ver;
    char    Comp;
    char    BitPixel;
    short   X1;
    short   Y1;
    short   X2;
    short   Y2;
    short   ResHzDPI;
    short   ResVtDPI;
    char    Pal[48];
    char    resv;
    char    NbPlan;
    short   OctLgImg;
    short   TypePal;
    short   ResHz;
    short   ResVt;
    char    resv2[54];
} HeadPCX;

//************FORMAT ** GIF**************************
typedef struct __attribute__((packed))
{   int     Sign; // == "GIF8"
    short   Ver; // == "7a" | "9a"
    short   LargEcran;
    short   HautEcran;
    char    IndicRes;
    char    FondCol;
    char    PAspcRation;
} HeadGIF;

typedef struct __attribute__((packed))
{   char    Sign; // == ','
    short   XPos;
    short   YPos;
    short   ResHz;
    short   ResVt;
    char    Indicateur;
} DescImgGIF;

typedef struct __attribute__((packed))
{   unsigned char   SignExt; // == '!'
    char            code;
    unsigned char   Size;
} ExtBlock;

// FONT AND CHR FORMAT ================================================

typedef struct
{   int             DatCar;
    char            PlusX,PlusLgn;
    unsigned char   Ht,Lg;
} Caract;

typedef struct
{   int         Sign;       // = "FCHR"
    char        MaxHautFnt,
                MaxHautLgn,
                MinPlusLgn,
                SensFnt;
    int         SizeDataCar,
                PtrBuff;
    int         Resv[28];
    Caract      C[256];
} HeadCHR;

// GLOBAL vars
extern int vlfb,rlfb,OffVMem,ResH,ResV,MaxX,MaxY,MinX,MinY,SizeSurf;
extern int OrgX,OrgY,NegScanLine;
// DWorker

#define DWORKERS_DEFAULT_MAX_COUNT  128

bool InitDWorkers(unsigned int MAX_DWorker);
void DestroyDWorkers();

// mutex

typedef struct
{   int         Sign;       // = "DMTX"
    SDL_mutex   *mutex;
} DMutex;

// GLOBAL Events Handling
extern SDL_mutex *mutexEvents;
void DgScanEvents(SDL_Event *event);

// keyboard ==========================================

extern unsigned int KbScanEvents;

void iUninstallKeyboard();
void iSetKbMAP(KbMAP *KM);
void iDisableCurKbMAP();
void iPushKbDownEvent(unsigned int KeyCode);
void iPushKbReleaseEvent(unsigned int KeyCode);
void iGetKey(unsigned char *Key,unsigned int *KeyFLAG);
void iClearKeyCircBuff();
void iGetTimedKeyDown(unsigned char *Key,unsigned int *KeyTime);
void iClearTimedKeyCircBuff();
void iGetAscii(unsigned char *Ascii,unsigned int *AsciiFLAG);
void iClearAsciiCircBuff();

// Mouse =======================================

extern int MsScanEvents;

void iPushMsEvent(unsigned int eventID);
void iSetMousePos(int MouseX,int MouseY);
void iSetMouseRView(DgView *V);
void iSetMouseOrg(int MsOrgX,int MsOrgY);
void iSetMousePos(int MouseX,int MouseY);
void iEnableMsEvntsStack();
void iDisableMsEvntsStack();
void iClearMsEvntsStack();
int iGetMsEvent(MouseEvent *MsEvnt);
void UpdateMouseButtonsState();
void UpdateCAPS_NUMKbFLAG();

// window
extern SDL_Window *DgWindow;
extern DgWindowResizeCallBack dgWindowResizeCallBack;
extern DgWindowResizeCallBack dgWindowPreResizeCallBack;
extern void *dgResizeWinMutex;
extern bool *dgRequestResizeWinMutex;
void DgResizeRendSurf(int resH, int resV);

// conversion & effect

void ConvB8ToB16Pal(void *BuffImgSrc, void *BuffImgDst, int ImgWidth, int ImgHeight, void *PalRGBA1024);

// math3d

#define MDEG_TO_RAD_STEP     3.14159265358979323846 / 180.0

// utils

#define DMAX(a,b) ((a) > (b) ? a : b)
#define DMIN(a,b) ((a) < (b) ? a : b)

#ifdef __cplusplus
           }
#endif


#endif // INTRNDUGL_H_INCLUDED


