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

#include "HelpDlg.h"
#include "AboutDlg.h"

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
// main render func
void RenderFunc();
// asset data
DgSurf BackSurf;
DgSurf MsSurf;
bool displayBackSurf = true;
bool validBackSurf = false;
bool previewCalc = false;
int CalcTransparency = 10;
int startXBackSurf = 0;
int startYBackSurf = 0;
int zstep=6;
bool needRedrawGraphBoxs = false;
int asciiCopyIdx = -1;
// synch buffers
char RenderSynchBuff[SIZE_SYNCH_BUFF];
bool SynchScreen = true;
// fps counter
float avgFps,lastFps;
// mouse view
DgView MsView;
// effects
bool blurSurf = false;
bool debugInfo = false;

// data
void ApplyCalcToCurCar();
void CopyCar();
void InsertCopiedCar();
void ClearCurCar();
void ReverseCurCar();
void ShiftUpCurCar();
void ShiftDownCurCar();
void ShiftRightCurCar();
void ShiftLeftCurCar();

int  CalcSizeDataCar();
int  CalcSizeData1Car(int Ascii);
int  SaveCHR(char *FName);
int  ReadCHR(char *FName);
void SetSnsLR(),SetSnsRL();

const char *TSChrName[]={ "CHR Font file", "All Files(*.*)" };
const char *TSChrMask[]={ "*.chr", "*.*" };
ListString LSChrName(2,TSChrName),LSChrMask(2,TSChrMask);
const char *TSImgName[]={ "GIF", "PCX", "BMP" };
const char *TSImgMask[]={ "*.gif", "*.pcx", "*.bmp" };
ListString LSImgName(3,TSImgName),LSImgMask(3,TSImgMask);
int car[2][256*64];
Caract InfCar[256];

int copiedCar[2][64];
Caract copiedInfCar;

unsigned int OldTime,ExitNow=0;
bool confirmExit = false;
bool waitConfirmExit = false;
void YesExit() {
	confirmExit = true;
	waitConfirmExit = false;
}
void CancelExit() {
	confirmExit = false;
	waitConfirmExit = false;
}

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
void ChgdCalcTransparency(int val);
void ChgdCalcVisibility(char vtrue);
void ShowHelpDlg();
void ShowAboutDlg();

// Gestionnaire des fenˆtres
WinHandler *WH = nullptr;
// windows -------------
MainWin *FPrinc = nullptr;
MainWin *HELPDlg = nullptr;
MainWin *ABOUTDlg = nullptr;
// FPrinc --
Menu *Mn;
Label *LbAscii = nullptr,*LbNmHeight = nullptr,*LbHeight = nullptr,*LbNmWidth = nullptr,*LbWidth = nullptr;
Label *LbNmPlusX = nullptr,*LbPlusX = nullptr,*LbNmPlusLn = nullptr,*LbPlusLn = nullptr;
HzSlider *HzSBAscii = nullptr,*HzSBHeight = nullptr,*HzSBWidth = nullptr,*HzSBPlusX = nullptr;
VtScrollBar *VtSBPlusLn = nullptr;
ContBox *CtBCalc = nullptr;
Button *BtApplyCalc = nullptr;
CocheBox *CBxVisibleCalc = nullptr;
HzSlider *HzSTransCalc = nullptr;
ContBox *CtBSensFnt = nullptr;
OptionButt *OpBtSnsLR = nullptr,*OpBtSnsRL = nullptr;
GraphBox *GphBCarMap = nullptr,*GphBCarDraw = nullptr;

// Menu -----------------
NodeMenu TNM[]= {
  { "",	                    3,  &TNM[1], 1, NULL } ,
  { "File",                 6,  &TNM[4], 1, NULL } ,   // 1
  { "Edit",                 4, &TNM[10], 1, NULL } ,
  { "Help",                 2, &TNM[14], 1, NULL } ,
  { "New",                  0,     NULL, 1, MenuNew } ,
  { "Open        F3",       0,     NULL, 1, MenuOpen } ,
  { "Save        F2",       0,     NULL, 1, MenuSave } ,
  { "Save as...",           0,     NULL, 1, MenuSaveAs } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Exit     Alt+X",       0,     NULL, 1, Exit } ,
  { "Copy        Ctrl+Ins", 0,     NULL, 1, CopyCar } ,   // 10
  { "Paste      Shift+Ins", 0,     NULL, 1, InsertCopiedCar } ,
  { "",                     0,     NULL, 1, NULL } ,
  { "Load Calc Image   F4", 0,     NULL, 1, MenuLoadImage } ,
  { "Help   F1",            0,     NULL, 1, ShowHelpDlg } ,
  { "About",                0,     NULL, 1, ShowAboutDlg }
  };


int main()
{
    // load font
    if (!LoadFONT(&F1,"helloc.chr")) {
      printf("Error loading helloc.chr\n"); exit(-1); }
    // load azerty kbmap
   if (!LoadKbMAP(&KM,"kbmap.map")) {
     printf("Error Loading kbmap.map\n"); exit(-1); }

    // load asset
    if (!LoadGIF16(&MsSurf, "Mouseimg.gif")) {
      printf("Error loading Mouseimg.gif\n"); exit(-1); }

    DgInit();


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
	HELPDlg = CreateMainWinHelpDLG(WH);
	ABOUTDlg = CreateMainWinAboutDLG(WH);

    FPrinc->AllowMove = false;
//---- FPrinc


    Mn = new Menu(FPrinc,&TNM[0]);
    LbAscii=new Label(5,5,78,25,FPrinc,"1",AJ_RIGHT);
    HzSBAscii= new HzSlider(81,395,8,FPrinc,1,255);
    HzSBAscii->Changed=ChgdAscii;
    CtBCalc=new ContBox(396,109,630,149,FPrinc,"Calc");
    {
    	CBxVisibleCalc = new CocheBox(1, 0, 75,1+FntHaut+6, FPrinc, CtBCalc, "Visible", 1);
    	CBxVisibleCalc->Changed = ChgdCalcVisibility;
    	HzSTransCalc = new HzSlider(80,177,3,FPrinc,1,30, CtBCalc);
    	HzSTransCalc->Changed = ChgdCalcTransparency;
    	HzSTransCalc->SetVal(CalcTransparency);
    	BtApplyCalc = new Button(182,1,227,1+FntHaut+6, FPrinc, "Apply",0,0,CtBCalc);
    	BtApplyCalc->Click = ApplyCalcToCurCar;
    }
    LbNmPlusX= new Label(395,87,439,107,FPrinc,"PlusX",AJ_LEFT);
    LbPlusX= new Label(439,87,467,107,FPrinc,"0",AJ_LEFT);
    HzSBPlusX= new HzSlider(472,630,90,FPrinc,0,127);
    HzSBPlusX->Changed=ChgdPlusX;
    LbNmHeight= new Label(395,65,445,85,FPrinc,"Height",AJ_LEFT);
    LbHeight= new Label(445,65,465,85,FPrinc,"1",AJ_LEFT);
    HzSBHeight= new HzSlider(472,630,68,FPrinc,1,64);
    HzSBHeight->Changed=ChgdHeight;
    LbNmWidth= new Label(395,43,445,63,FPrinc,"Width",AJ_LEFT);
    LbWidth= new Label(445,43,465,63,FPrinc,"1",AJ_LEFT);
    HzSBWidth= new HzSlider(472,630,46,FPrinc,1,64);
    HzSBWidth->Changed=ChgdWidth;
    LbNmPlusLn=  new Label(500,150,560,165,FPrinc,"PlusLn",AJ_LEFT);
    LbPlusLn=  new Label(561,147,600,165,FPrinc,"0",AJ_LEFT);
    VtSBPlusLn= new VtScrollBar(483,149,424,FPrinc,-127,127);
    VtSBPlusLn->SetVal(0); VtSBPlusLn->Changed=ChgdPlusLn;
    CtBSensFnt=new ContBox(396,5,630,42,FPrinc,"Direction");
    {
        OpBtSnsLR=new OptionButt(0,0,110,20,FPrinc,CtBSensFnt,"Left-Right",1);
        OpBtSnsLR->Changed=ChgdSensFnt;
        OpBtSnsRL=new OptionButt(110,0,220,20,FPrinc,CtBSensFnt,"Right-Left",0);
        OpBtSnsRL->Changed=ChgdSensFnt;
    }
    GphBCarMap= new GraphBox(5,29,395,423,FPrinc,WH->m_GraphCtxt->WinGris);
    GphBCarMap->GraphBoxDraw=GphBDrawMap;
    GphBCarMap->ScanGraphBox=ScanGphBMap;
    GphBCarDraw= new GraphBox(500,167,629,423,FPrinc,WH->m_GraphCtxt->WinGris);
    GphBCarDraw->GraphBoxDraw=GphBDrawCar;
    needRedrawGraphBoxs = true;

    // initialize
    MenuNew();

    //SetSurfView(&RendSurf, &clippedView);

    InitSynch(RenderSynchBuff, NULL, 60.0f);

    for (int countFrame = 0; ; countFrame++)
    {
        // scan GUI events
        DgCheckEvents();
        WH->Scan();
		// render and update screen
		RenderFunc();

		bool homeEndArrowsKeyHolded = HzSBAscii->Focus || HzSTransCalc->Focus || HzSBPlusX->Focus || HzSBHeight->Focus || HzSBWidth->Focus || VtSBPlusLn->Focus;

        switch (WH->Key)
        {
            case KB_KEY_F1:
                ShowHelpDlg();
                break;
            case KB_KEY_F2:
                MenuSave();
                break;
            case KB_KEY_F3:
                MenuOpen();
                break;
            case KB_KEY_F4:
                MenuLoadImage();
                break;
            case KB_KEY_F7:
                break;
            case KB_KEY_F12:
                debugInfo = !debugInfo;
                break;
			case KB_KEY_ESC:
				ExitNow = 1;
				break;
			case KB_KEY_QWERTY_X: // alt + X => exit
				if ((WH->KeyFLAG & KB_ALT_PR))
					ExitNow = 1;
				break;
			case KB_KEY_ENTER:
				if (FPrinc->Focus && validBackSurf && displayBackSurf) {
					if ((WH->KeyFLAG & KB_ALT_PR) > 0) {
						ApplyCalcToCurCar();
						needRedrawGraphBoxs = true;
					}
				}
				break;
			case KB_KEY_RIGHT:
			case KB_KEY_LEFT:
			case KB_KEY_UP:
			case KB_KEY_DOWN:
				if (FPrinc->Focus && (WH->KeyFLAG & KB_CTRL_PR) > 0 && (WH->KeyFLAG & KB_ALT_PR) == 0 && GphBCarMap->Focus == 0) {
					GphBCarMap->SetFocus();
					GphBCarMap->Scan();
				}
				if (FPrinc->Focus && (WH->KeyFLAG & KB_CTRL_PR) == 0 && (WH->KeyFLAG & KB_ALT_PR) > 0 && HzSBAscii->Focus == 0) {
					if (WH->Key == KB_KEY_LEFT && !homeEndArrowsKeyHolded)
						HzSBAscii->SetVal(HzSBAscii->GetVal()-1);
					if (WH->Key == KB_KEY_RIGHT && !homeEndArrowsKeyHolded)
						HzSBAscii->SetVal(HzSBAscii->GetVal()+1);
				}
				break;

			case KB_KEY_INSERT:
				// copy
				if (FPrinc->Focus && (WH->KeyFLAG&KB_CTRL_PR) > 0 && (WH->KeyFLAG&KB_SHIFT_PR) == 0) {
					CopyCar();
				}
				// paste/insert
				if (FPrinc->Focus && (WH->KeyFLAG&KB_CTRL_PR) == 0 && (WH->KeyFLAG&KB_SHIFT_PR) > 0) {
					InsertCopiedCar();
					needRedrawGraphBoxs = true;
				}
				break;


			case KB_KEY_HOME:
			    if (!homeEndArrowsKeyHolded) {
                    if (FPrinc->Focus) {
                        if ((KbFLAG&KB_CTRL_PR) > 0) {
                         startXBackSurf = 0;
                         startYBackSurf = 0;
                        } else {
                         ReverseCurCar();
                        }
                        needRedrawGraphBoxs = true;
                    }
			    }
				break;
			case KB_KEY_END:
				if (FPrinc->Focus && !homeEndArrowsKeyHolded) {
					ClearCurCar();
					ReverseCurCar();
					needRedrawGraphBoxs = true;
				}
				break;
			case KB_KEY_DELETE:
				if (FPrinc->Focus) {
					ClearCurCar();
					needRedrawGraphBoxs = true;
				}
				break;
            default:
                break;
        }
        if (ExitNow == 1) {
			confirmExit = false;
			ExitNow = 0;
			// if messageBox is already waiting for confirmation of exit
			if (!waitConfirmExit) {
				waitConfirmExit = true;
				MessageBox(WH, "Warning", "Confirm exit from EDCHR2 ?", "Yes", YesExit, "Cancel", CancelExit, NULL, NULL);
			}
        }
		if (confirmExit) {
            break;
		}
    }

    delete ABOUTDlg;
    delete HELPDlg;
    delete FPrinc;
    delete WH;

    ABOUTDlg = nullptr;
    HELPDlg = nullptr;
    FPrinc = nullptr;
    WH = nullptr;

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

   if (fopen_s(&InCHR,FName,"rb")!=0) {
       MessageBox(WH,"can't open file", FName,
         "Ok", NULL, NULL, NULL, NULL, NULL);
       return 0;
   }
   fread(&hchr,sizeof(HeadCHR),1,InCHR);
   if (hchr.Sign!='RHCF') { fclose(InCHR); return 0; }

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

   if (fopen_s(&OutCHR, FName,"wb")!=0) return 0;
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
void LoadBackImage(String *filename, int selection) {
	int res = 0;

	if (validBackSurf && BackSurf.rlfb != 0) {
		validBackSurf = false;
		needRedrawGraphBoxs = true;
		DestroySurf(&BackSurf);
	}

	switch (selection) {
		case 0: // GIF
			res = LoadGIF16(&BackSurf, filename->StrPtr);
			break;
		case 1: // PCX
			res = LoadPCX16(&BackSurf, filename->StrPtr);
			break;
		case 2: // BMP
			res = LoadBMP16(&BackSurf, filename->StrPtr);
			break;
	}
	if (res) {
		startXBackSurf = 0;
		startYBackSurf = 0;
		validBackSurf = true;
		needRedrawGraphBoxs = true;
	}
}
void MenuLoadImage() {
   FilesBox(WH,"Load Calc Image", "Load", LoadBackImage, "Cancel", NULL, &LSImgName,
            &LSImgMask, 0);
}

void ChgdCalcTransparency(int val) {
	CalcTransparency = val;
	if (GphBCarMap!= nullptr)
       needRedrawGraphBoxs = true;
}

void ChgdCalcVisibility(char vtrue) {
	displayBackSurf = (vtrue > 0);
	if (GphBCarMap!= nullptr)
       needRedrawGraphBoxs = true;
}

void ShowHelpDlg() {
	HELPDlg->ShowModal();
}

void ShowAboutDlg() {
	ABOUTDlg->ShowModal();
}
//-------
void ChgdAscii(int val) {
   char displayAscii[128];
   if (val>32 && val<127)
	  sprintf(displayAscii,"[%c]: %03i", val, (char)val);
   else
	  sprintf(displayAscii,"%03i", val);
   LbAscii->Text=displayAscii;
   HzSBHeight->SetVal(InfCar[val].Ht);
   HzSBWidth->SetVal(InfCar[val].Lg);
   HzSBPlusX->SetVal(abs(InfCar[val].PlusX));
   VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[val].Ht);
   VtSBPlusLn->SetVal(InfCar[val].PlusLgn);
   needRedrawGraphBoxs = true;
}

void ChgdHeight(int val) {
   int curascii=HzSBAscii->GetVal();
   LbHeight->Text=val;
   if (InfCar[curascii].Ht!=val) {
     InfCar[curascii].Ht=val;
     VtSBPlusLn->SetMinMaxVal(-127,127-InfCar[curascii].Ht);
     if (InfCar[curascii].Ht+InfCar[curascii].PlusLgn>127)
       VtSBPlusLn->SetVal(127-InfCar[curascii].Ht);
     needRedrawGraphBoxs = true;
   }
}
void ChgdWidth(int val) {
   int curascii=HzSBAscii->GetVal();
   LbWidth->Text=val;
   if (InfCar[curascii].Lg!=val) {
     InfCar[curascii].Lg=val;
     HzSBPlusX->SetVal(val);
     needRedrawGraphBoxs = true;
   }
}
void ChgdPlusX(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusX->Text=val;
   if (abs(InfCar[curascii].PlusX)!=val) {
     InfCar[curascii].PlusX=(OpBtSnsLR->True)?val:(-val);
     needRedrawGraphBoxs = true;
   }
}
void ChgdPlusLn(int val) {
   int curascii=HzSBAscii->GetVal();
   LbPlusLn->Text=val;
   if (InfCar[curascii].PlusLgn!=val) {
     InfCar[curascii].PlusLgn=val;
     needRedrawGraphBoxs = true;
   }
}
void GphBDrawMap(GraphBox *Me) {
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
         WH->m_GraphCtxt->InBar(DebX+j*zstep,DebY+i*zstep,
			 DebX+(j+1)*zstep-1,DebY+(i+1)*zstep-1,DrawCol);
	WH->m_GraphCtxt->rect(DebX,DebY,DebX+LargRect,DebY+HautRect,WH->m_GraphCtxt->WinBlanc);
	for (j=1;j<HautChar;j++)
		for (i=1;i<LargChar;i++)
			WH->m_GraphCtxt->cputpixel(DebX+i*zstep,DebY+j*zstep,WH->m_GraphCtxt->WinBleuF);
	if (validBackSurf && displayBackSurf) {
		DgView saveView, saveBackView, backView, backSurfView;
		GetSurfView(&CurSurf, &saveView);
		GetSurfView(&CurSurf, &backView);
		backView.MinX = DebX+1;
		backView.MinY = DebY+1;
		backView.MaxX = DebX+LargRect-1;
		backView.MaxY = DebY+HautRect-1;
		SetSurfView(&CurSurf, &backView); // set the new view

		GetSurfView(&BackSurf, &backSurfView);
		GetSurfView(&BackSurf, &saveBackView);

		// check if it's completely out
		if (startXBackSurf <= backSurfView.MaxX && startYBackSurf <= backSurfView.MaxY) {
			backSurfView.MinX = startXBackSurf;
			backSurfView.MinY = startYBackSurf;
			backSurfView.MaxX = startXBackSurf + (LargChar-1);
			backSurfView.MaxY = startYBackSurf + (HautChar-1);
			SetSurfView(&BackSurf, &backSurfView); // clip view inside
			if (BackSurf.MaxX < startXBackSurf + (LargChar-1)) { // clip the destination view ?
				backView.MaxX -= ((startXBackSurf + (LargChar-1)) - BackSurf.MaxX) * zstep;
				SetSurfView(&CurSurf, &backView); // set the new view
			}
			if (BackSurf.MaxY < startYBackSurf + (HautChar-1)) { // clip the destination view ?
				backView.MaxY -= ((startYBackSurf + (HautChar-1)) - BackSurf.MaxY) * zstep;
				SetSurfView(&CurSurf, &backView); // set the new view
			}

			if ((MsButton&MS_LEFT_BUTT) > 0 && (KbFLAG&KB_CTRL_PR) > 0 && Me->MsIn) {
				WH->m_GraphCtxt->MaskBlndResizeViewSurf(&BackSurf, 0, 0, WH->m_GraphCtxt->WinBlanc | (CalcTransparency<<24));
				previewCalc = true;
			}
			else {
				WH->m_GraphCtxt->MaskTransResizeViewSurf(&BackSurf, 0, 0, CalcTransparency);
				previewCalc = false;
			}

		}
		// restore views
		SetSurfView(&CurSurf, &saveView);
		SetSurfView(&BackSurf, &saveBackView);
	}

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
	 needRedrawGraphBoxs = true;
   }
}

void ScanGphBMap(GraphBox *Me) {
   //int redr=0;
   int curascii=HzSBAscii->GetVal();
   int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
   int LargRect=LargChar*zstep,HautRect=HautChar*zstep;
   int MidX=(CurSurf.MaxX+CurSurf.MinX)/2,MidY=(CurSurf.MaxY+CurSurf.MinY)/2;
   int DebX=MidX-LargRect/2,DebY=MidY-HautRect/2;
   int x,y,mousex=Me->MouseX,mousey=Me->MouseY;

   if (previewCalc){
      needRedrawGraphBoxs = true;
   }

   if ((MsButton&MS_LEFT_BUTT) > 0)
     if ( mousex>=DebX && mousey>=DebY &&
        mousex<=(DebX+LargRect-1) && mousey<=(DebY+HautRect-1) ) {
       x=(mousex-DebX)/zstep;
       y=(mousey-DebY)/zstep;
       if ((KbFLAG&KB_CTRL_PR) == 0 || !(validBackSurf && displayBackSurf)) {
		   if (!( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) )) {
				car[x>>5][y+curascii*64] |= 1<<(x&0x1f);
				needRedrawGraphBoxs = true;
		   }
       } else { // if CTRL pressed and a calc is displayed then set the mask color
			unsigned int newmask = DgSurfCGetPixel16(&BackSurf, startXBackSurf+x, startYBackSurf+y);
			if (newmask != 0xffffffff && BackSurf.Mask != newmask) {
				BackSurf.Mask = newmask;
				needRedrawGraphBoxs = true;
			}
       }
     }

   if ((MsButton&MS_RIGHT_BUTT)>0)
     if ( mousex>=DebX && mousey>=DebY && mousex<=(DebX+LargRect-1) &&
          mousey<=(DebY+HautRect-1) ) {
       x=(Me->MouseX-DebX)/zstep;
       y=(Me->MouseY-DebY)/zstep;
       if ( car[x>>5][y+curascii*64] & (1<<(x&0x1f)) ) {
         car[x>>5][y+curascii*64]&=(1<<(x&0x1f))^0xffffffff; // xor 1111b == NOT
 		 needRedrawGraphBoxs = true;
       }
     }
   if (Me->Focus) {
     if ((KbFLAG&KB_ALT_PR) == 0) {
		 if ((WH->Key==KB_KEY_UP) || (WH->Key==0x48 && (!(KbFLAG|KB_NUM_ACT)))) {// up
		   if ((KbFLAG&KB_CTRL_PR) > 0) {
			 if ((KbFLAG&KB_SHIFT_PR) > 0) {
			   if (startYBackSurf >= 4)
				  startYBackSurf -= 4;
			 } else {
			   if (startYBackSurf > 0)
				  startYBackSurf --;
			 }
		   } else {
		   	  ShiftUpCurCar();
		   }
 		   needRedrawGraphBoxs = true;
		 }
		 if ((WH->Key==KB_KEY_DOWN) || (WH->Key==0x50 && (!(KbFLAG|KB_NUM_ACT)))) {// down
		   if ((KbFLAG&KB_CTRL_PR) > 0) {
			 if ((KbFLAG&KB_SHIFT_PR) > 0) {
				startYBackSurf += 4;
			 } else {
				startYBackSurf ++;
			 }
		   } else {
		   	  ShiftDownCurCar();
		   }
 		   needRedrawGraphBoxs = true;
		 }
		 if ((WH->Key==KB_KEY_RIGHT) || (WH->Key==0x4d && (!(KbFLAG|KB_NUM_ACT)))) {// right
		   if ((KbFLAG&KB_CTRL_PR) > 0) {
			 if ((KbFLAG&KB_SHIFT_PR) > 0) {
			   if (startXBackSurf >= 4)
				  startXBackSurf -= 4;
			 } else {
			   if (startXBackSurf > 0)
				  startXBackSurf --;
			 }
		   } else {
		   	  ShiftRightCurCar();
		   }
 		   needRedrawGraphBoxs = true;
		 }
		 if ((WH->Key==KB_KEY_LEFT) || (WH->Key==0x4b && (!(KbFLAG|KB_NUM_ACT)))) {// left
		   if ((KbFLAG&KB_CTRL_PR) > 0) {
			 if ((KbFLAG&KB_SHIFT_PR) > 0) {
				startXBackSurf += 4;
			 } else {
				startXBackSurf ++;
			 }
		   } else {
		   	  ShiftLeftCurCar();
		   }
 		   needRedrawGraphBoxs = true;
		 }
     }
   }

}

void ApplyCalcToCurCar() {
	int curascii=HzSBAscii->GetVal();
	int LargChar=InfCar[curascii].Lg,HautChar=InfCar[curascii].Ht;
	int i,j;
    int calCol = 0;

	if (validBackSurf && displayBackSurf) {
		// clear all
		for (i=0;i<64;i++) {
			for (j=0;j<2;j++) {
				car[j][i+curascii*64]=0;
			}
		}

		for (i=0;i<HautChar;i++) {
			for (j=0;j<LargChar;j++) {
				calCol = DgSurfCGetPixel16(&BackSurf, startXBackSurf+j, startYBackSurf+i);
				if (calCol != 0xffffffff) {
					if (calCol != BackSurf.Mask) { // set
						car[j>>5][i+curascii*64] |= 1<<(j);
					}
				}
			}
		}
		needRedrawGraphBoxs = true;
	} else {
		if (!validBackSurf)
			MessageBox(WH,"Error", "You need first to load a Calc Image!",
				"Ok", NULL, NULL, NULL, NULL, NULL);
		if (!displayBackSurf)
			MessageBox(WH,"Error", "Calc Image should be visible to apply Calc",
				"Ok", NULL, NULL, NULL, NULL, NULL);
	}
}

void CopyCar() {
	int i,j;

	asciiCopyIdx = HzSBAscii->GetVal();

	// copy Info
	copiedInfCar = InfCar[asciiCopyIdx];
	// copy Data
    for (i=0;i<64;i++) {
		for (j=0;j<2;j++) {
			copiedCar[j][i]=car[j][i+asciiCopyIdx*64];
		}
    }
}

void InsertCopiedCar() {
	int curascii=HzSBAscii->GetVal();

    int i,j;
	if (asciiCopyIdx == -1)
		return;

	// copy Info
	InfCar[curascii] = copiedInfCar;

    // copy data
    for (i=0;i<64;i++) {
		for (j=0;j<2;j++) {
			car[j][i+curascii*64]=copiedCar[j][i];
		}
    }

    // refresh ui
    HzSBPlusX->SetVal((int)copiedInfCar.PlusX);
    HzSBHeight->SetVal((int)copiedInfCar.Ht);
    HzSBWidth->SetVal((int)copiedInfCar.Lg);
    VtSBPlusLn->SetVal((int)copiedInfCar.PlusLgn);
}

void ClearCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i,j;

    // clear all
    for (i=0;i<64;i++) {
		for (j=0;j<2;j++) {
			car[j][i+curascii*64]=0;
		}
    }
}



void ReverseCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i,j;

	for (i=0;i<64;i++) {
		for (j=0;j<2;j++)
			car[j][i+curascii*64]^=0xffffffff;
	}
}

void ShiftUpCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i,j;

	 for (i=62;i>=0;i--) {
		for (j=0;j<2;j++)
			car[j][(i+1)+curascii*64]=car[j][i+curascii*64];
	 }
	 car[0][curascii*64]=0; car[1][curascii*64]=0;
}

void ShiftDownCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i,j;

	for (i=0;i<63;i++) {
	   for (j=0;j<2;j++)
		 car[j][i+curascii*64]=car[j][(i+1)+curascii*64];
	}
	car[0][63+curascii*64]=0; car[1][63+curascii*64]=0;
}

void ShiftRightCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i;

	for (i=0;i<64;i++)
		RightShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);

}

void ShiftLeftCurCar() {
	int curascii=HzSBAscii->GetVal();
    int i;

	for (i=0;i<64;i++)
		LeftShiftLine(&car[0][i+curascii*64],&car[1][i+curascii*64]);

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


void RenderFunc() {
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

	if (needRedrawGraphBoxs) {
		GphBCarMap->Redraw();
		GphBCarDraw->Redraw();
		needRedrawGraphBoxs = false;
	}

	WH->DrawSurf(&CurSurf);

	if (debugInfo)
	{
		barblnd16(0+dx,460+dy, 639+dx, 479+dy, 0xffff | (25<<24));

		ClearText();
		char text[125];
		SetTextCol(0x0);
		if (avgFps!=0.0)
			OutText16ModeFormat(AJ_RIGHT, text, 124, "Ms(x,y) (%i,%i)  KbFLAG %x  LastKey %x LastAscii '%c' -  FPS %i\n", MsX, MsY, KbFLAG, LastKey, (WH->Ascii != 0)? WH->Ascii : ' ', (int)(1.0/avgFps));
		else
			OutText16Mode("FPS ???\n", AJ_RIGHT);
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

