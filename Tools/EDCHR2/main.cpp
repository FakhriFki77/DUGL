/*  Dust Ultimate Game Library (DUGL) - (C) 2022 Fakhri Feki */
/*  Simple editor of the proprietary chr font format using DUGLGUI addon*/
/*  History : */
/*  24 march 2022 : first release */

#include <dir.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "DUGL.h"
#include "DGUI.h"

// fast asm function

#ifdef __cplusplus
extern "C" {
#endif
  void RightShiftLine(void *DD0,void *DD1);
  void LeftShiftLine(void *DD0,void *DD1);
#ifdef __cplusplus
	   }
#endif


// FONT AND CHR FORMAT ===from "intrndugl.h"=========================================

typedef struct
{	int		        DatCar;
	char	        PlusX,PlusLgn;
	unsigned char   Ht,Lg;
} Caract;

typedef struct
{	int	       	Sign;  		// = "FCHR"
	char	    MaxHautFnt,
		       	MaxHautLgn,
		       	MinPlusLgn,
		       	SensFnt;
	int	       	SizeDataCar,
                PtrBuff;
	int		    Resv[28];
	Caract	    C[256];
} HeadCHR;

using namespace std;
const int ScreenWidth = 640;
const int ScreenHeight = 480;
// FONT
FONT F1;
KbMAP *KM; // kbmap



int countLoops = 0;

// asset data
//DgSurf BackSurf;
DgSurf MsSurf;
// synch buffers
char EventsLoopSynchBuff[SIZE_SYNCH_BUFF];
char RenderSynchBuff[SIZE_SYNCH_BUFF];
bool SynchScreen = true;
// fps counter
float avgFps,lastFps;
// mouse view
DgView MsView;
// effects
bool blurSurf = false;
bool debugInfo = false;
// render DWorker
unsigned int renderWorkerID = 0;
void RenderWorkerFunc(void *, int );

// data
int  CalcSizeDataCar();
int  CalcSizeData1Car(int Ascii);
int  SaveCHR(char *FName);
int  ReadCHR(char *FName);
void SetSnsLR(),SetSnsRL();

const char *TSChrName[]={ "CHR Font file", "All Files(*.*)" };
const char *TSChrMask[]={ "*.chr", "*.*" };
ListString LSChrName(2,TSChrName),LSChrMask(2,TSChrMask);
const char *TSImgName[]={ "GIF", "PCX", "BMP", "All Files(*.*)" };
const char *TSImgMask[]={ "*.gif", "*.pcx", "*.bmp", "*.*" };
ListString LSImgName(4,TSImgName),LSImgMask(4,TSImgMask);
int car[2][256*64];
Caract InfCar[256];
unsigned int CopyCar[2][64];
Caract CopyInfCar;

unsigned int OldTime,ExitNow=0;
char FSens;
// config global
int newDefaultWidth = 16;
int newDefaultHeight = 16;
int defaultWinX = -1;
int defaultWinY = -1;
int WinBorderless = 1;
unsigned int DrawCol = RGB16(0,255,255);

void LoadConfig();
// GUI **********************************************
//***************************************************

String SCurFile,SLbFPrinc("Edchr2");
// events -----------
// FPrinc --
void OpenCHR(String *S,int TypeSel);
void MenuNew(),MenuOpen(),MenuSave(),MenuSaveAs(),Exit();
void MenuLoadImage();
void ChgdAscii(int val),GphBDrawMap(GraphBox *Me);
void GphBDrawCar(GraphBox *Me),ScanGphBMap(GraphBox *Me);
void ChgdHeight(int val),ChgdWidth(int val),ChgdPlusX(int val);
void ChgdPlusLn(int val);
void ChgdSensFnt(char vtrue);
// FOuvrImg --
void ExitOuvrImg();
// Gestionnaire des fenˆtres
WinHandler *WH;
// windows -------------
MainWin *FPrinc,*FOuvrImg;
// FPrinc --
Menu *Mn;
Label *LbNmAscii,*LbAscii,*LbNmHeight,*LbHeight,*LbNmWidth,*LbWidth;
Label *LbNmPlusX,*LbPlusX,*LbNmPlusLn,*LbPlusLn;
HzSlider *HzSBAscii,*HzSBHeight,*HzSBWidth,*HzSBPlusX;
VtScrollBar *VtSBPlusLn;
ContBox *CtBSensFnt;
OptionButt *OpBtSnsLR,*OpBtSnsRL;
GraphBox *GphBCarMap,*GphBCarDraw;
// FOuvrImg --
Button *BtCancelOI,*BtOIOkOI,*BtSelCol,*BtSelMskCol;

// Menu -----------------
NodeMenu TNM[]= {
  { "",	                    3,  &TNM[1], 1, NULL } ,
  { "File",                 6,  &TNM[4], 1, NULL } ,   // 1
  { "Edit",                 5, &TNM[10], 1, NULL } ,
  { "Help",                 2, &TNM[15], 1, NULL } ,
  { "New",                  0,     NULL, 1, MenuNew } ,
  { "Open        F3",       0,     NULL, 1, MenuOpen } ,
  { "Save        F2",       0,     NULL, 1, MenuSave } ,
  { "Save as...",           0,     NULL, 1, MenuSaveAs } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Exit     Alt+X",       0,     NULL, 1, Exit } ,
  { "Copy        Ctrl+Ins", 0,     NULL, 1, NULL } ,   // 10
  { "Paste      Shift+Ins", 0,     NULL, 1, NULL } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Load image        F4", 0,     NULL, 1, MenuLoadImage } ,
  { "Import character  F5", 0,     NULL, 1, NULL } ,
  { "Help   F1",            0,     NULL, 1, NULL } ,
  { "About",                0,     NULL, 1, NULL }
  };


int main()
{
    // load font
    if (!LoadFONT(&F1,"hello.chr")) {
      printf("Error loading hello.chr\n"); exit(-1); }
    // load azerty kbmap
   if (!LoadKbMAP(&KM,"kbmap.map")) {
     printf("Error Loading kbmap.map\n"); exit(-1); }

    // load asset
    if (!LoadGIF16(&MsSurf, "Mouseimg.gif")) {
      printf("Error loading Mouseimg.gif\n"); exit(-1); }

    DgInit();

    renderWorkerID = CreateDWorker(RenderWorkerFunc, nullptr);


    if (!DgInitMainWindowX(SLbFPrinc.StrPtr, ScreenWidth, ScreenHeight, 16, defaultWinX, defaultWinY, false, true, false))
        DgQuit();

    DgInstallTimer(500);
    InstallKeyboard();
    SetKbMAP(KM);
    InstallMouse();

    LoadConfig();

    GetSurfView(&RendSurf, &MsView);
    SetMouseRView(&MsView);
    //SetMouseOrg(RendSurf.ResH / 2, RendSurf.ResV / 2);

    SetFONT(&F1);

    SetOrgSurf(&MsSurf, 0, MsSurf.ResV - 1); // set org top left corner

    // GUI
    WH = new WinHandler(RendSurf.ResH,RendSurf.ResV,16,0x1f,0);
    FPrinc = new MainWin(RendSurf.MinX,RendSurf.MinY,RendSurf.ResH,RendSurf.ResV,SLbFPrinc.StrPtr,WH);
    FPrinc->AllowMove = false;
//---- FPrinc
    Mn = new Menu(FPrinc,&TNM[0]);
    LbNmAscii= new Label(5,5,50,25,FPrinc,"Ascii",AJ_LEFT);
    LbAscii=new Label(50,5,80,25,FPrinc,"1",AJ_LEFT);
    HzSBAscii= new HzSlider(81,395,8,FPrinc,1,255);
    HzSBAscii->Changed=ChgdAscii;
    LbNmPlusX= new Label(395,94,439,114,FPrinc,"PlusX",AJ_LEFT);
    LbPlusX= new Label(439,94,467,114,FPrinc,"0",AJ_LEFT);
    HzSBPlusX= new HzSlider(472,630,97,FPrinc,0,127);
    HzSBPlusX->Changed=ChgdPlusX;
    LbNmHeight= new Label(395,72,445,92,FPrinc,"Height",AJ_LEFT);
    LbHeight= new Label(445,72,465,92,FPrinc,"1",AJ_LEFT);
    HzSBHeight= new HzSlider(472,630,75,FPrinc,1,64);
    HzSBHeight->Changed=ChgdHeight;
    LbNmWidth= new Label(395,50,445,70,FPrinc,"Width",AJ_LEFT);
    LbWidth= new Label(445,50,465,70,FPrinc,"1",AJ_LEFT);
    HzSBWidth= new HzSlider(472,630,53,FPrinc,1,64);
    HzSBWidth->Changed=ChgdWidth;
    LbNmPlusLn=  new Label(500,143,560,163,FPrinc,"PlusLn",AJ_LEFT);
    LbPlusLn=  new Label(561,143,600,163,FPrinc,"0",AJ_LEFT);
    VtSBPlusLn= new VtScrollBar(483,144,421,FPrinc,-127,127);
    VtSBPlusLn->SetVal(0); VtSBPlusLn->Changed=ChgdPlusLn;
    CtBSensFnt=new ContBox(396,7,630,47,FPrinc,"Direction");
    {
        OpBtSnsLR=new OptionButt(0,0,110,20,FPrinc,CtBSensFnt,"Left-Right",1);
        OpBtSnsLR->Changed=ChgdSensFnt;
        OpBtSnsRL=new OptionButt(110,0,220,20,FPrinc,CtBSensFnt,"Right-Left",0);
        OpBtSnsRL->Changed=ChgdSensFnt;
    }
    GphBCarMap= new GraphBox(5,30,395,420,FPrinc,WH->m_GraphCtxt->WinGris);
    GphBCarMap->GraphBoxDraw=GphBDrawMap;
    GphBCarMap->ScanGraphBox=ScanGphBMap; GphBCarMap->Redraw();
    GphBCarDraw= new GraphBox(500,164,629,420,FPrinc,WH->m_GraphCtxt->WinGris);
    GphBCarDraw->GraphBoxDraw=GphBDrawCar;  GphBCarDraw->Redraw();
    // initialize
    MenuNew();

    //SetSurfView(&RendSurf, &clippedView);

    InitSynch(EventsLoopSynchBuff, NULL, 250.0f);
    InitSynch(RenderSynchBuff, NULL, 60.0f);

    //DgClear16(countLoops&0x1f);

    for (int countFrame = 0; ; countFrame++)
    {
        WaitSynch(EventsLoopSynchBuff, NULL);
        // scan GUI events
        WH->Scan();
		// render and update screen
		RunDWorker(renderWorkerID, false);

        DgCheckEvents();
        if (IsKeyDown(KB_KEY_ESC) || ExitNow == 1) // esc
            break;
        if (WH->Key == 0x2d && (WH->KeyFLAG & KB_ALT_PR)) // alt + x
            break;

        switch (WH->Key)
        {
            case KB_KEY_F2: // F2
                MenuSave();
                break;
            case KB_KEY_F3: // F3
                MenuOpen();
                break;
            case KB_KEY_F7: // F7
                break;
            case KB_KEY_F12: // F12
                debugInfo = !debugInfo;
                break;
            default:
                break;
        }
    }

    DestroyDWorker(renderWorkerID);
    UninstallMouse();
    DgUninstallTimer();
    UninstallKeyboard();

    DgQuit();
    return 0;
}

int ReadCHR(char *FName) {
   HeadCHR hchr;
   int i,j,k,l,h,BPtr;
   void *Buff;
   FILE *InCHR;

   if ((InCHR=fopen(FName,"rb"))==NULL) {
       MessageBox(WH,"can't open file", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
       return 0;
   }
/*   MessageBox(WH,"file exist", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
*/
   fread(&hchr,sizeof(HeadCHR),1,InCHR);
   if (hchr.Sign!='RHCF') { fclose(InCHR); return 0; }

/*   MessageBox(WH,"valid header", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
*/
   for (i=0;i<256;i++) InfCar[i]=hchr.C[i];
   if (hchr.SizeDataCar!=CalcSizeDataCar())
   { fclose(InCHR); return 0; }
   if ((Buff=malloc(hchr.SizeDataCar))==NULL) {
        MessageBox(WH,"Error", "No Mem !",
       "Ok", NULL, NULL, NULL, NULL, NULL);
     fclose(InCHR); return 0;
   }
   memset(car, 0, sizeof(int)*2*256*64);

   fseek(InCHR,hchr.PtrBuff,SEEK_SET);
   fread(Buff,hchr.SizeDataCar,1,InCHR);
   for (BPtr=0,i=1;i<256;i++) {
     hchr.C[i].DatCar=BPtr;
     l=(InfCar[i].Lg<=32)?1:2;
     h=InfCar[i].Ht;
     for (k=0;k<h;k++)
       for (j=0;j<l;j++)
         car[j][i*64+k]=((int *)((int)(Buff)+BPtr))[k*l+j];
     BPtr+=CalcSizeData1Car(i);
   }
   FSens=hchr.SensFnt;
   free(Buff);
   fclose(InCHR);
   return 1;
}
int SaveCHR(char *FName) {
   HeadCHR hchr;
   int i,j,k,l,h,BPtr,Size;
   void *Buff;
   FILE *OutCHR;

   if ((OutCHR=fopen(FName,"wb"))==NULL) return 0;
   if ((Buff=malloc(Size=CalcSizeDataCar()))==NULL) {
	  fclose(OutCHR); return 0;
   }
   for (i=0;i<Size/4;i++) ((int*)(Buff))[i]=0;
   for (i=0;i<28;i++) hchr.Resv[i]=0;
   hchr.Sign='RHCF';
   hchr.SensFnt=FSens;
   hchr.PtrBuff=sizeof(HeadCHR);
   for (i=0;i<256;i++) hchr.C[i]=InfCar[i];

   for (h=hchr.C[1].PlusLgn,i=2;i<256;i++)   // Max BasLgn
     h=(h>hchr.C[i].PlusLgn)?hchr.C[i].PlusLgn:h;
   hchr.MinPlusLgn=h;
   for (h=hchr.C[1].PlusLgn+(hchr.C[1].Ht-1),i=2;i<256;i++)// Max HautLgn
   h=(h<(hchr.C[i].PlusLgn+(hchr.C[i].Ht-1))) ?
     (hchr.C[i].PlusLgn+(hchr.C[i].Ht-1)):h;
   hchr.MaxHautLgn=h;

   hchr.MaxHautFnt=hchr.MaxHautLgn-hchr.MinPlusLgn+1;

   for (BPtr=0,i=1;i<256;i++) {
     hchr.C[i].DatCar=BPtr;
     l=(InfCar[i].Lg<=32)?1:2;
     h=InfCar[i].Ht;
     for (k=0;k<h;k++)
       for (j=0;j<l;j++)
         ((int *)((int)(Buff)+BPtr))[k*l+j]=car[j][i*64+k];
     BPtr+=CalcSizeData1Car(i);
   }
   hchr.SizeDataCar=BPtr;
   if (fwrite(&hchr,sizeof(HeadCHR),1,OutCHR)<1) {
     free(Buff); fclose(OutCHR); return 0; }
   if (fwrite(Buff,BPtr,1,OutCHR)<1) {
     free(Buff); fclose(OutCHR); return 0; }
   free(Buff);
   fclose(OutCHR);
   return 1;
}
int CalcSizeDataCar() {
   int i,Sz;
   for (Sz=0,i=1;i<256;i++)
   Sz+=((InfCar[i].Lg<=32)?1:2)*InfCar[i].Ht*4;
   return Sz;
}
int CalcSizeData1Car(int Ascii) {
   return ((InfCar[Ascii].Lg<=32)?1:2)*InfCar[Ascii].Ht*4;
}
void SetSnsLR() {
   for (int i=1;i<256;i++)
     InfCar[i].PlusX=abs(InfCar[i].PlusX);
    OpBtSnsLR->SetTrue(1);
}
void SetSnsRL() {
   for (int i=1;i<256;i++)
     InfCar[i].PlusX=-abs(InfCar[i].PlusX);
    OpBtSnsRL->SetTrue(1);
}
// evenements -----------
// FPrinc --
void MenuNew() {
   int i;

   HzSBAscii->SetVal(1);
   HzSBHeight->SetVal(newDefaultHeight);
   HzSBWidth->SetVal(newDefaultWidth);
   HzSBPlusX->SetVal((OpBtSnsLR->True)? newDefaultWidth : -newDefaultWidth);
   VtSBPlusLn->SetVal(0);

   memset(car, 0, sizeof(int)*2*256*64);
   for (i=0;i<256;i++) {
     InfCar[i].Ht=newDefaultHeight;
     InfCar[i].Lg=newDefaultWidth;
     InfCar[i].PlusX=(OpBtSnsLR->True)? newDefaultWidth : -newDefaultWidth;
     InfCar[i].PlusLgn=0;
   }
   SCurFile="";
   FPrinc->Label=SLbFPrinc;
   FPrinc->Redraw();
   HzSBHeight->Redraw();
}
void MenuOpen() {
   FilesBox(WH,"Open", "Open", OpenCHR, "Cancel", NULL, &LSChrName,
            &LSChrMask, 0);
}
void MenuSave() {
   if (strlen(SCurFile.StrPtr)==0) {
     MenuSaveAs();
     return;
   }
   if (!SaveCHR(SCurFile.StrPtr))
     MessageBox(WH,"Error", "can't save file !",
                "Ok", NULL, NULL, NULL, NULL, NULL);
}
void Exit() {
   ExitNow = 1;
}

//-------
void FSaveCHR(String *S,int TypeSel);
void MenuSaveAs() {
   FilesBox(WH,"Save as...", "Save", FSaveCHR, "Cancel", NULL, &LSChrName,
            &LSChrMask, 0);
}
void FSaveCHR(String *S,int TypeSel) {
   String S2=*S;
   char d[_MAX_DRIVE+1], p[_MAX_DIR+1], f[_MAX_FNAME+1], e[_MAX_EXT+1];
   _splitpath(S2.StrPtr, d, p, f, e);
   if (strlen(e)==0)
     S2+=".chr";
   else {
     _makepath(S2.StrPtr, d, p, f, ".chr");
   }
   if (!SaveCHR(S2.StrPtr))
     MessageBox(WH,"Error", "can't save file !",
                "Ok", NULL, NULL, NULL, NULL, NULL);
   else {
     SCurFile=S2;
     strlwr(SCurFile.StrPtr);
     FPrinc->Label=SLbFPrinc+"  "+SCurFile;
     FPrinc->Redraw();
   }
}
//-------
void MenuLoadImage() {
   FilesBox(WH,"Load image", "Load", NULL, "Cancel", NULL, &LSImgName,
            &LSImgMask, 0);
}
//-------
void ChgdAscii(int val) {
   LbAscii->Text=val;
   HzSBHeight->SetVal(InfCar[val].Ht);
   HzSBWidth->SetVal(InfCar[val].Lg);
   HzSBPlusX->SetVal(abs(InfCar[val].PlusX));
   VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[val].Ht);
   VtSBPlusLn->SetVal(InfCar[val].PlusLgn);
   GphBCarMap->Redraw();
   GphBCarDraw->Redraw();
}
void ChgdHeight(int val) {
   int curascii=HzSBAscii->GetVal();
   LbHeight->Text=val;
   if (InfCar[curascii].Ht!=val) {
     InfCar[curascii].Ht=val;
     VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[curascii].Ht);
     if (InfCar[curascii].Ht+InfCar[curascii].PlusLgn>127)
       VtSBPlusLn->SetVal(127-InfCar[curascii].Ht);
     GphBCarMap->Redraw();
   }
}
void ChgdWidth(int val) {
   int curascii=HzSBAscii->GetVal();
   LbWidth->Text=val;
   if (InfCar[curascii].Lg!=val) {
     InfCar[curascii].Lg=val;
     HzSBPlusX->SetVal(val);
     GphBCarMap->Redraw();
   }
}
void ChgdPlusX(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusX->Text=val;
   if (abs(InfCar[curascii].PlusX)!=val) {
     InfCar[curascii].PlusX=(OpBtSnsLR->True)?val:(-val);
     GphBCarDraw->Redraw();
   }
}
void ChgdPlusLn(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusLn->Text=val;
   if (InfCar[curascii].PlusLgn!=val) {
     InfCar[curascii].PlusLgn=val;
     GphBCarDraw->Redraw();
   }
}
void GphBDrawMap(GraphBox *Me) {
   int zstep=6;
   int curascii=HzSBAscii->GetVal();
   int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
   int LargRect=LargChar*zstep,HautRect=HautChar*zstep;
   int MidX=(CurSurf.MaxX+CurSurf.MinX)/2,MidY=(CurSurf.MaxY+CurSurf.MinY)/2;
   int DebX=MidX-LargRect/2,DebY=MidY-HautRect/2;
   int i,j;
   ClearSurf16(WH->m_GraphCtxt->WinGrisF);
   for (i=0;i<HautChar;i++)
     for (j=0;j<LargChar;j++)
       if (car[j>>5][i+curascii*64]&(1<<(j&0x1f)))
         WH->m_GraphCtxt->bar(DebX+j*zstep,DebY+i*zstep,
             DebX+(j+1)*zstep-1,DebY+(i+1)*zstep-1,DrawCol);
   WH->m_GraphCtxt->rect(DebX,DebY,DebX+LargRect,DebY+HautRect,WH->m_GraphCtxt->WinBlanc);
   for (j=1;j<HautChar;j++)
     for (i=1;i<LargChar;i++)
       WH->m_GraphCtxt->cputpixel(DebX+i*zstep,DebY+j*zstep,WH->m_GraphCtxt->WinBleuF);
}
void GphBDrawCar(GraphBox *Me) {
   int i,j,curascii=HzSBAscii->GetVal(),plsx;
   WH->m_GraphCtxt->ClearSurf(WH->m_GraphCtxt->WinGrisF);
   WH->m_GraphCtxt->line(0,128,128,128,WH->m_GraphCtxt->WinBlanc);
   plsx=(InfCar[curascii].PlusX>=0)?0:(128+InfCar[curascii].PlusX);
   for (i=0;i<InfCar[curascii].Ht;i++)
     for (j=0;j<InfCar[curascii].Lg;j++)
       if (car[j>>5][i+curascii*64]&(1<<(j&0x1f)))
         WH->m_GraphCtxt->cputpixel(plsx+j,i+128+InfCar[curascii].PlusLgn,DrawCol);
}
void OpenCHR(String *S,int TypeSel) {
   int i;
   if (!ReadCHR(S->StrPtr)) {
     MessageBox(WH,"Error", "Invalid format or error reading !",
       "Ok", NULL, NULL, NULL, NULL, NULL);
     SCurFile=""; return;
   }
   HzSBAscii->SetVal(1);
   ChgdAscii(1);
   for (i=1;i<256;i++) {
     if (InfCar[i].PlusX>0) { SetSnsLR(); break; }
     if (InfCar[i].PlusX<0) { SetSnsRL(); break; }
   }
   if (i<256) SetSnsLR();
   SCurFile=*S;
   strlwr(SCurFile.StrPtr);
   FPrinc->Label=SLbFPrinc+"  "+SCurFile;
   FPrinc->Redraw();
}
void ChgdSensFnt(char vtrue) {
   if (vtrue) {
     if (OpBtSnsLR->True)
       SetSnsLR();
     else
       SetSnsRL();
     GphBCarDraw->Redraw();
   }
}
void ScanGphBMap(GraphBox *Me) {
   int zstep=6,redr=0;
   int curascii=HzSBAscii->GetVal();
   int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
   int LargRect=LargChar*zstep,HautRect=HautChar*zstep;
   int MidX=(CurSurf.MaxX+CurSurf.MinX)/2,MidY=(CurSurf.MaxY+CurSurf.MinY)/2;
   int DebX=MidX-LargRect/2,DebY=MidY-HautRect/2;
   int x,y,mousex=Me->MouseX,mousey=Me->MouseY;
   int i,j;

   if (MsButton&1)
     if ( mousex>=DebX && mousey>=DebY &&
        mousex<=(DebX+LargRect-1) && mousey<=(DebY+HautRect-1) ) {
       x=(mousex-DebX)/zstep;
       y=(mousey-DebY)/zstep;
       if (WH->Ascii == 'D' && //BoutApp(32) &&     // D
            (!( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) )) ) {
         if (x>0)
	   for (i=x-1;i>=0;i--) {
	     if (car[i>>5][y+curascii*64] & (1<<(i&0x1f))) break;
	     car[i>>5][y+curascii*64] |= 1<<(i&0x1f);
	   }
         if (x<64)
	   for (i=x+1;i<65;i++) {
	     if (car[i>>5][y+curascii*64] & (1<<(i&0x1f))) break;
	     car[i>>5][y+curascii*64] |= 1<<(i&0x1f);
	   }
         redr=1;
       }
       if (!( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) )) {
         car[x>>5][y+curascii*64] |= 1<<(x&0x1f);
         redr=1;
       }
     }

   if ((MsButton&MS_RIGHT_BUTT)>0)
     if ( mousex>=DebX && mousey>=DebY && mousex<=(DebX+LargRect-1) &&
          mousey<=(DebY+HautRect-1) ) {
       x=(Me->MouseX-DebX)/zstep;
       y=(Me->MouseY-DebY)/zstep;
       if ( (WH->Ascii == 'D' || WH->Ascii == 'd') && //BoutApp(32) &&     // D
          ( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) ) ) {
             if (x>0)
               for (i=x-1;i>=0;i--) {
                 if (!(car[i>>5][y+curascii*64] & (1<<(i&0x1f)))) break;
                 car[i>>5][y+curascii*64] &= (1<<(i&0x1f))^0xffffffff;
               }
             if (x<64)
               for (i=x+1;i<65;i++) {
                 if (!(car[i>>5][y+curascii*64] & (1<<(i&0x1f)))) break;
                 car[i>>5][y+curascii*64] &= (1<<(i&0x1f))^0xffffffff;
               }
             redr=1;
       }
       if ( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) ) {
         car[x>>5][y+curascii*64]&=(1<<(x&0x1f))^0xffffffff; // xor 1111b == NOT
         redr=1;
       }
     }
   if (Me->Focus) {
     if (WH->Key==199) {    // 'Debut'  <28 Enter> <210 Ins>
       redr=1;
       for (i=0;i<64;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]^=0xffffffff;
     }
     if (WH->Key==211) {    // 'Suppr'  <28 Enter>
       redr=1;
       for (i=0;i<64;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]=0;
     }
     if ((WH->Key==0xc8) || (WH->Key==0x48 && (!(KbFLAG|KB_NUM_ACT)))) {// up
       redr=1;
       for (i=62;i>=0;i--)
         for (j=0;j<2;j++)
           car[j][(i+1)+curascii*64]=car[j][i+curascii*64];
       car[0][curascii*64]=0; car[1][curascii*64]=0;
     }
     if ((WH->Key==0xd0) || (WH->Key==0x50 && (!(KbFLAG|KB_NUM_ACT)))) {// down
       redr=1;
       for (i=0;i<63;i++)
         for (j=0;j<2;j++)
           car[j][i+curascii*64]=car[j][(i+1)+curascii*64];
       car[0][63+curascii*64]=0; car[1][63+curascii*64]=0;
     }
     if ((WH->Key==0xcd) || (WH->Key==0x4d && (!(KbFLAG|KB_NUM_ACT)))) {// right
       redr=1;
       for (i=0;i<64;i++)
         RightShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);
     }
     if ((WH->Key==0xcb) || (WH->Key==0x4b && (!(KbFLAG|KB_NUM_ACT)))) {// left
       redr=1;
       for (i=0;i<64;i++)
         LeftShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);
     }
     // up = c8, down = d0, right = cd, left = cb
     //      48         50          4d         4b
   }
   if (redr) { GphBCarMap->Redraw(); GphBCarDraw->Redraw(); }
}
// FOuvrImg --
void ExitOuvrImg() {
   FOuvrImg->Hide();
   FPrinc->Enable();
}

// config.ini

void LoadConfig()
{
  const int MAX_CONFIGLINE_LENGTH = 2048;
  FILE *fConfig = fopen("config.ini","rt");
  String lineID(MAX_CONFIGLINE_LENGTH);
  String lineInfo(MAX_CONFIGLINE_LENGTH);
  String *sInfoName;
  ListString *LSParams;
  ListString *LSTmp;

  if(fConfig == NULL)
    return;
  for(;;) {
    if(fgets(lineID.StrPtr, MAX_CONFIGLINE_LENGTH-1, fConfig) == NULL) break;
    if(fgets(lineInfo.StrPtr, MAX_CONFIGLINE_LENGTH-1, fConfig) == NULL) break;
    lineID.Del13_10();
    lineInfo.Del13_10();
    // remove comments
    LSTmp = lineID.Split(';');
    if(LSTmp != NULL) {
      lineID = *(*LSTmp)[0];
      delete LSTmp;
    }
    LSTmp = lineInfo.Split(';');
    if(LSTmp != NULL) {
      lineInfo = *(*LSTmp)[0];
      delete LSTmp;
    }
    //---
    if(lineID.Length()==0) break;
    if(lineInfo.Length()==0) break;
    // extract config
    sInfoName = lineID.SubString(0, '[', ']');
    LSParams = lineInfo.Split(',');

    if(*sInfoName == "DefaultCharSize" && LSParams->NbElement() >= 2) {
      newDefaultWidth = (*LSParams)[0]->GetInt();
      newDefaultHeight = (*LSParams)[1]->GetInt();
    }
    else if(*sInfoName == "DrawColor" && LSParams->NbElement() >= 3) {
      DrawCol = RGB16((*LSParams)[0]->GetInt() & 0xFF,
                      (*LSParams)[1]->GetInt() & 0xFF,
                      (*LSParams)[2]->GetInt() & 0xFF);
    }
    else if(*sInfoName == "WinPosition" && LSParams->NbElement() >= 2) {
      defaultWinX = (*LSParams)[0]->GetInt();
      defaultWinY = (*LSParams)[1]->GetInt();
    }
    else if(*sInfoName == "WinBorderless" && LSParams->NbElement() >= 1) {
      WinBorderless = ((*LSParams)[0]->GetInt() != 0) ? 1 : 0;
    }

    delete sInfoName;
    delete LSParams;
  }
  fclose(fConfig);
}


void RenderWorkerFunc(void *, int ) {
    int dx = 0;//-RendSurf.ResH / 2;
    int dy = 0;//-RendSurf.ResV / 2;

	// synchronise
	if (SynchScreen)
		WaitSynch(RenderSynchBuff, NULL);
	else
		Synch(RenderSynchBuff,NULL);

	// synch screen display
	avgFps=SynchAverageTime(RenderSynchBuff);
	lastFps=SynchLastTime(RenderSynchBuff);

	DgSetCurSurf(&RendSurf);

	WH->DrawSurf(&CurSurf);

	if (debugInfo)
	{
		barblnd16(0+dx,460+dy, 639+dx, 479+dy, 0xffff | (25<<24));

		ClearText();
		char text[124];
		SetTextCol(0x0);
		if (avgFps!=0.0)
			sprintf(text,"KbFLAG %x  LastKey %x LastAscii '%c' -  FPS %i\n", KbFLAG, LastKey, (WH->Ascii != 0)? WH->Ascii : ' ', (int)(1.0/avgFps));
		else
			sprintf(text,"FPS ???\n");
		OutText16Mode(text,AJ_RIGHT);
	}

	if (MsInWindow)
	{
		int PUTSURF_FLAG = PUTSURF_NORM;
		if (MsY - MsSurf.ResV < CurSurf.MinY) PUTSURF_FLAG |= PUTSURF_INV_VT;
		if (MsX + MsSurf.ResH > CurSurf.MaxX) PUTSURF_FLAG |= PUTSURF_INV_HZ;
		PutMaskSurf16(&MsSurf, MsX, MsY, PUTSURF_FLAG);
	}

	DgUpdateWindow();
}
