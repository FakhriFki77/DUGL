/*	Dust Ultimate Game Library (DUGL)
    Copyright (C) 2025	Fakhri Feki */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
//#include <dir.h>
#ifdef __MINGW32__
#include <direct.h>
#define GetCurrentDir _getcwd
#else
#include <unistd.h>
#include <dirent.h>
#include <pwd.h>
#include <fnmatch.h>
#define GetCurrentDir getcwd
#endif
#include <DUGL.h>

#include "INTRNGUI.H"
#include "DGUI.H"


//****** MessageBox *******************
//*************************************

typedef struct {
    MainWin *MsgBoxWin;
    Button *ButtOk,*ButtNo,*ButtCancel;
    Label *LabMsg;
    void (*ClickOk)(),(*ClickNo)(),(*ClickCancel)();
    NodeWin *LastCurWinNode;
} MessageBoxInfo;

MessageBoxInfo *TbMsgBox;
unsigned int CptMsgBx=0,InitMsgBx=1,MaxMsgBx;

void MsgBoxClickOk(),MsgBoxClickNo(),MsgBoxClickCancel();
void InitMsgBox(unsigned int MaxMsgBox) {
    unsigned int i;
    if (CptMsgBx && TbMsgBox) {
        for (i=0; i<CptMsgBx; i++) delete TbMsgBox[i].MsgBoxWin;
        free(TbMsgBox);
    }
    TbMsgBox= (MessageBoxInfo*)malloc(sizeof(MessageBoxInfo)*MaxMsgBox);
    if (TbMsgBox != nullptr)
        memset(TbMsgBox, 0, sizeof(MessageBoxInfo)*MaxMsgBox);
    InitMsgBx=0;
    CptMsgBx=0;
    MaxMsgBx=MaxMsgBox;
}

void MessageBox(WinHandler *MsgBoxWH, const char *NmWin, const char *Msg,
                const char *NmOk, void (*clickOk)(), const char *NmNo, void (*clickNo)(),
                const char *NmCancel, void (*clickCancel)()) {
    if (InitMsgBx) InitMsgBox(DEFAULT_MAX_MSGBOX);
    if (CptMsgBx>=MaxMsgBx) return;
    int MaxLargButt=WidthText(NmOk),largText,HeightMsgBox=FntHaut*8;
    int NbButt=1,LargButtons;
    int YPosMsgBox=MsgBoxWH->S->ResV/2-FntHaut*4,XPosMsgBox;
    int XPosButton;
    int LargMsg=WidthText(Msg)+30,LargMsgBox;
    DgView V1;
    if (NmNo && (largText=WidthText(NmNo))>MaxLargButt) MaxLargButt=largText;
    if (NmNo) NbButt++;
    if (NmCancel && (largText=WidthText(NmCancel))>MaxLargButt) MaxLargButt=largText;
    if (NmCancel) NbButt++;
    MaxLargButt+=30;
    if (MaxLargButt<90) MaxLargButt=90;
    LargButtons=MaxLargButt*NbButt+(NbButt-1)*10;
    LargMsgBox=LargButtons+30;
    LargMsgBox=(LargMsgBox>=LargMsg)?LargMsgBox:LargMsg;

    if (LargMsgBox<150) LargMsgBox=150;
    XPosMsgBox=MsgBoxWH->S->ResH/2-(LargMsgBox/2);
    XPosButton=(LargMsgBox-6)/2-(LargButtons/2);

    TbMsgBox[CptMsgBx].ClickOk=clickOk;
    TbMsgBox[CptMsgBx].ClickNo=clickNo;
    TbMsgBox[CptMsgBx].ClickCancel=clickCancel;
    TbMsgBox[CptMsgBx].LastCurWinNode=MsgBoxWH->CurWinNode;
    TbMsgBox[CptMsgBx].MsgBoxWin=new MainWin(XPosMsgBox,YPosMsgBox,LargMsgBox,HeightMsgBox,NmWin,MsgBoxWH);
    V1=TbMsgBox[CptMsgBx].MsgBoxWin->VActiv;
    TbMsgBox[CptMsgBx].LabMsg=new Label(V1.MinX,V1.MaxY-FntHaut*3,
                                        V1.MaxX,V1.MaxY-FntHaut*1,TbMsgBox[CptMsgBx].MsgBoxWin,Msg,AJ_MID);
    if (NmCancel || NmNo)
        TbMsgBox[CptMsgBx].ButtOk=new Button(XPosButton,10,XPosButton+MaxLargButt,10+FntHaut+11,TbMsgBox[CptMsgBx].MsgBoxWin,NmOk,1,0);
    else
        TbMsgBox[CptMsgBx].ButtOk=new Button(XPosButton,10,XPosButton+MaxLargButt,10+FntHaut+11,TbMsgBox[CptMsgBx].MsgBoxWin,NmOk,1,1);
    TbMsgBox[CptMsgBx].ButtOk->Click=MsgBoxClickOk;
    if (NmNo) {
        TbMsgBox[CptMsgBx].ButtNo=new Button(XPosButton+10+MaxLargButt,10,XPosButton+10+2*MaxLargButt,10+FntHaut+11,TbMsgBox[CptMsgBx].MsgBoxWin,NmNo,0,0);
        TbMsgBox[CptMsgBx].ButtNo->Click=MsgBoxClickNo;
    }
    if (NmCancel) {
        if (NmNo)
            TbMsgBox[CptMsgBx].ButtCancel=new Button(XPosButton+20+2*MaxLargButt,10,XPosButton+20+3*MaxLargButt,10+FntHaut+11,TbMsgBox[0].MsgBoxWin,NmCancel,0,1);
        else
            TbMsgBox[CptMsgBx].ButtCancel=new Button(XPosButton+20+MaxLargButt,10,XPosButton+20+2*MaxLargButt,10+FntHaut+11,TbMsgBox[0].MsgBoxWin,NmCancel,0,1);
        TbMsgBox[CptMsgBx].ButtCancel->Click=MsgBoxClickCancel;
    }
    TbMsgBox[CptMsgBx].MsgBoxWin->Enable();
    CptMsgBx++;
}

void MsgBoxClickOk() {
    if (TbMsgBox == nullptr)
        return;
    CptMsgBx--;
    if (TbMsgBox[CptMsgBx].LastCurWinNode) TbMsgBox[CptMsgBx].LastCurWinNode->Item->Enable();
    if (TbMsgBox[CptMsgBx].ClickOk) TbMsgBox[CptMsgBx].ClickOk();
    if (TbMsgBox[CptMsgBx].MsgBoxWin) TbMsgBox[CptMsgBx].MsgBoxWin->DeleteLater();
    memset(&TbMsgBox[CptMsgBx], 0, sizeof(MessageBoxInfo));
}

void MsgBoxClickNo() {
    if (TbMsgBox == nullptr)
        return;
    CptMsgBx--;
    if (TbMsgBox[CptMsgBx].LastCurWinNode) TbMsgBox[CptMsgBx].LastCurWinNode->Item->Enable();
    if (TbMsgBox[CptMsgBx].ClickNo) TbMsgBox[CptMsgBx].ClickNo();
    if (TbMsgBox[CptMsgBx].MsgBoxWin) TbMsgBox[CptMsgBx].MsgBoxWin->DeleteLater();
    memset(&TbMsgBox[CptMsgBx], 0, sizeof(MessageBoxInfo));
}

void MsgBoxClickCancel() {
    if (TbMsgBox == nullptr)
        return;
    CptMsgBx--;
    if (TbMsgBox[CptMsgBx].LastCurWinNode) TbMsgBox[CptMsgBx].LastCurWinNode->Item->Enable();
    if (TbMsgBox[CptMsgBx].ClickCancel) TbMsgBox[CptMsgBx].ClickCancel();
    if (TbMsgBox[CptMsgBx].MsgBoxWin) TbMsgBox[CptMsgBx].MsgBoxWin->DeleteLater();
    memset(&TbMsgBox[CptMsgBx], 0, sizeof(MessageBoxInfo));
}

//****** FileBox **********************
//*************************************

typedef struct {
    MainWin *FilesBoxWin;
    WinHandler *MyWH;
    Button *ButtOk,*ButtCancel;
    Label *LabReps,*LabNom,*LabType,*LabLect,*LabFiles,*LabCurDir;
    TextBox *TxBNom;
    ComBox *CmBLect,*CmBType;
    ListBox *LBFiles,*LBReps;
    ListString *LStrMask;
    void (*ClickOk)(String *S,int typesel),(*ClickCancel)();
    NodeWin *LastCurWinNode;
#ifndef WINDOWS
    char Dirs[3][512]; // init cur dir, home dir, and root
#endif // WINDOWS
    int NbDrive;
    bool bSortFilesDirs;
    bool bSortAsc;
} FilesBoxInfo;

FilesBoxInfo FileBox;
const char *defNomOk="Ok",*defNomCancel="Cancel";
const char *LNmType[]= { "All files(*.*)" };
const char *LMskType[]= { "*.*" };
ListString LSDefTypes(1,LNmType),LSDefMaskTypes(1,LMskType);

void FilesBoxClickOk(),FilesBoxClickCancel();
void LBFilesChanged(String *S,int Select);
void LBRepsValidateStr(String *S,int Select);
void LBFilesValidateStr(String *S,int Select);
void ChgdCmBLect(String *S,int Select),ChgdCmBType(String *S,int Select);
void FBChgdCmB(String *SLect,int SelectLect,String *SType,int SelectType);
void FBSelectFirstDirFile();

void FilesBox(WinHandler *FilesBoxWH, const char *NmWin,
              const char *NmOk, void (*clickOk)(String *S,int typesel),
              const char *NmCancel, void (*clickCancel)(),
              ListString *NomTypes,ListString *MaskTypes,int deftype, bool SortFilesDirs, bool sortAsc) {

    int largw=500,hautw=400;
    DgView V1;

    memset(&FileBox, 0, sizeof(FilesBoxInfo));
    GetSurfView(FilesBoxWH->S,&V1);

    FileBox.bSortFilesDirs = SortFilesDirs;
    FileBox.bSortAsc = sortAsc;

    FileBox.ClickOk=clickOk;
    FileBox.ClickCancel=clickCancel;
    FileBox.LastCurWinNode=FilesBoxWH->CurWinNode;
    FileBox.MyWH=FilesBoxWH;
    FileBox.FilesBoxWin=
        new MainWin((V1.MinX+V1.MaxX-largw)/2,(V1.MinY+V1.MaxY-hautw)/2,
                    largw,hautw,NmWin,FilesBoxWH);

    FileBox.LabCurDir= new Label(10,343,480,365,FileBox.FilesBoxWin,NULL,AJ_SRC);

    FileBox.LBFiles= new ListBox(10,70,240,322,FileBox.FilesBoxWin);
    FileBox.LBFiles->Changed=LBFilesChanged;
    FileBox.LBFiles->ValidateString=LBFilesValidateStr;
    FileBox.LabFiles= new Label(10,323,190,340,FileBox.FilesBoxWin,"Files:",AJ_SRC);

    FileBox.LBReps= new ListBox(255,70,483,302,FileBox.FilesBoxWin);
    FileBox.LBReps->ValidateString=LBRepsValidateStr;
    FileBox.LabReps= new Label(255,303,480,320,FileBox.FilesBoxWin,"Directories:",AJ_SRC);
//----- Drive
    FileBox.CmBLect= new ComBox(325,322,115,20,FileBox.FilesBoxWin);
    FileBox.CmBLect->Changed=ChgdCmBLect;

#ifdef __MINGW32__
    int i,IdxDrv,CountDrvFound,count_drives = (int)_getdrives();
    char Drv[4]="a:/";
    i=_getdrive(); // save current disk
    CountDrvFound=0; // nb drive
    for (IdxDrv=1; IdxDrv<255 && IdxDrv<count_drives; IdxDrv++) {
        if (!_chdrive(IdxDrv)) {
            Drv[0]='a'+IdxDrv-1;
            FileBox.CmBLect->LStr->Add(Drv);
            CountDrvFound++;
        }
    }
    FileBox.NbDrive=CountDrvFound;
    _chdrive(i); // restore current disk
    FileBox.LabLect= new Label(255,322,322,342,FileBox.FilesBoxWin,"Drive:",AJ_SRC);
#else
    // init possible paths
    FileBox.NbDrive=3;
    FileBox.CmBLect->LStr->Add("CWD");
    FileBox.CmBLect->LStr->Add("HOME");
    FileBox.CmBLect->LStr->Add("ROOT");
    // init directories
    GetCurrentDir(FileBox.Dirs[0], 512);
    const char *homedir;
    if ((homedir = getenv("HOME")) == NULL) {
        homedir = getpwuid(getuid())->pw_dir;
    }
    strcpy(FileBox.Dirs[1], homedir);
    strcpy(FileBox.Dirs[2], "/");
    FileBox.LabLect= new Label(255,322,322,342,FileBox.FilesBoxWin,"Dirs:",AJ_SRC);
#endif

//-------------
    FileBox.TxBNom= new TextBox (55,40,320,40+FntHaut+6,FileBox.FilesBoxWin,NULL,0);
    FileBox.LabNom= new Label(10,40,50,60,FileBox.FilesBoxWin,"Name",AJ_DST);
    if (NomTypes) {
        FileBox.CmBType= new ComBox(55,10,268,22,FileBox.FilesBoxWin,NomTypes);
    } else {
        FileBox.CmBType= new ComBox(55,10,268,22,FileBox.FilesBoxWin,&LSDefTypes);
    }
    FileBox.CmBType->Changed=ChgdCmBType;
    if (MaskTypes) {
        FileBox.LStrMask= MaskTypes;
    } else {
        FileBox.LStrMask= &LSDefMaskTypes;
    }
    if (deftype>=0 && deftype<FileBox.LStrMask->NbElement()) {
        FileBox.CmBType->Select=deftype;
    }
    if (!NomTypes) {
        FileBox.CmBType->Select=0;
    }
    FileBox.LabType= new Label(10,10,50,30,FileBox.FilesBoxWin,"Type",AJ_DST);

    FileBox.ButtOk=new Button(333,21+FntHaut,483,29+FntHaut*2,FileBox.FilesBoxWin,
                              ((NmOk != nullptr) ? NmOk : defNomOk),0,0);
    FileBox.ButtOk->Click=FilesBoxClickOk;
    FileBox.ButtCancel=new Button(333,10,483,18+FntHaut,FileBox.FilesBoxWin,
                                  ((NmCancel != nullptr) ? NmCancel : defNomCancel),0,1);
    FileBox.ButtCancel->Click=FilesBoxClickCancel;
    FileBox.FilesBoxWin->Enable();

#ifdef __MINGW32__
    Drv[0]='a'+i-1; // name current drive
    FileBox.CmBLect->Select=FileBox.CmBLect->LStr->Index(Drv, 0);
#else
    FileBox.CmBLect->Select=0; // select CWD
#endif // __MINGW32__

    FileBox.CmBLect->Scan();
}

void FBSelectFirstDirFile() {
    // if there is any dir then select the first and ensure it's visiblity
    if (FileBox.LBReps->LStr->NbElement()>0) {
        FileBox.LBReps->PosCursor=0;
        FileBox.LBReps->EnsureVisible(0);
    }
    // if there is any file select the first and ensure it's visiblity
    if (FileBox.LBFiles->LStr->NbElement()>0) {
        FileBox.LBFiles->PosCursor=0;
        FileBox.LBFiles->EnsureVisible(0);
    }

}

void FilesBoxClickOk() {
    String *S;
    int lectsel=FileBox.CmBLect->Select,typesel=FileBox.CmBType->Select;
    String Err;
    if (lectsel==-1) Err="Select a drive !";
    else if (!strlen(FileBox.TxBNom->Text.StrPtr)) Err="Select a file !";

    if (Err.Length()>0) {
        MessageBox(FileBox.MyWH,"Error",Err.StrPtr, "Ok",NULL, NULL,NULL, NULL,NULL);
        return;
    }
    S=new String;
    *S=FileBox.LabCurDir->Text;
    if (strlen(S->StrPtr)>3) {
        *S+="/";
        *S+=FileBox.TxBNom->Text;
    } else
        *S+=FileBox.TxBNom->Text;
    if (FileBox.LastCurWinNode) FileBox.LastCurWinNode->Item->Enable();
    if (FileBox.ClickOk) FileBox.ClickOk(S,typesel);
    if (FileBox.FilesBoxWin) FileBox.FilesBoxWin->DeleteLater();
    delete S;
}

void FilesBoxClickCancel() {
    if (FileBox.LastCurWinNode) FileBox.LastCurWinNode->Item->Enable();
    if (FileBox.ClickCancel) FileBox.ClickCancel();
    if (FileBox.FilesBoxWin) FileBox.FilesBoxWin->DeleteLater();
}

void LBFilesChanged(String *S,int Select) {
    if (Select!=-1) FileBox.TxBNom->Text=*S;
    else FileBox.TxBNom->Text="";
}

void LBRepsValidateStr(String *S,int Select) {
    if (Select==-1) return;
    if (chdir(S->StrPtr)) {
        FileBox.LabCurDir->Text="";
        FileBox.CmBLect->Select=-1;
        FileBox.LBReps->PosCursor=-1;
        FileBox.LBReps->LStr->ClearListStr();
        FileBox.LBFiles->PosCursor=-1;
        FileBox.LBFiles->LStr->ClearListStr();
        MessageBox(FileBox.MyWH, "Error", "Directory or drive invalide !",
                   "Ok", NULL, NULL, NULL, NULL, NULL);
        return;
    }
    GetCurrentDir(FileBox.LabCurDir->Text.StrPtr, 360);
    FileBox.LabCurDir->Redraw();
    FileBox.LBReps->PosCursor=-1;
    FileBox.LBReps->LStr->ClearListStr();
    FileBox.LBFiles->PosCursor=-1;
    FileBox.LBFiles->LStr->ClearListStr();

    // refresh directories List
#ifdef __MINGW32__
    struct _finddata32_t f;
    int fileHandler = _findfirst32("*.*", &f); //, FA_HIDDEN| FA_DIREC| FA_SYSTEM);
    if (fileHandler != -1) {
        for (;;) {
            if ((f.attrib&_A_SUBDIR) /*&& ((f.attrib&_A_SYSTEM)|| (f.attrib&_A_NORMAL)|| (f.attrib&_A_HIDDEN))*/ && strcmp(".",f.name) != 0) {
                FileBox.LBReps->LStr->Add(f.name);
            }
            if (_findnext32(fileHandler, &f) == -1)
                break;
        }
        _findclose(fileHandler);
    }
#else
    DIR *dir;
    struct dirent *dp;
    if ((dir = opendir (".")) != NULL) {
        while ((dp = readdir (dir)) != NULL) {
            if (dp->d_type == DT_DIR && strcmp(".",dp->d_name) != 0) {
                FileBox.LBReps->LStr->Add(dp->d_name);
            }
        }
        closedir(dir);
    }
#endif

    if(FileBox.bSortFilesDirs)
        FileBox.LBReps->LStr->Sort(FileBox.bSortAsc);

    if (FileBox.CmBType->Select!=-1) {
        ListString *LSMasks = NULL;

        LSMasks = (*FileBox.LStrMask)[FileBox.CmBType->Select]->Split('|');

        if(LSMasks != NULL) {
            for (int i=0; i<LSMasks->NbElement(); i++) {
#ifdef __MINGW32__
                fileHandler= _findfirst32((*LSMasks)[i]->StrPtr, &f); //, FA_HIDDEN| FA_SYSTEM);
                if (fileHandler != -1) {
                    for (;;) {
                        if (!(f.attrib&_A_SUBDIR) /*&& ((f.attrib&_A_SYSTEM)|| (f.attrib&_A_NORMAL) || (f.attrib&_A_HIDDEN))*/) {
                            FileBox.LBFiles->LStr->Add(f.name);
                        }
                        if (_findnext32(fileHandler, &f) == -1)
                            break;
                    }
                    _findclose(fileHandler);
                }
#else
                DIR *dir;
                struct dirent *dp;
                if ((dir = opendir (".")) != NULL) {
                    while ((dp = readdir (dir)) != NULL) {
                        if (dp->d_type == DT_REG && fnmatch((*LSMasks)[i]->StrPtr, dp->d_name, FNM_FILE_NAME) == 0) {
                            FileBox.LBFiles->LStr->Add(dp->d_name);
                        }
                    }
                    closedir(dir);
                }
#endif
            }
            if(FileBox.bSortFilesDirs)
                FileBox.LBFiles->LStr->Sort(FileBox.bSortAsc);
            delete LSMasks;
        }
    }

    FBSelectFirstDirFile();
    FileBox.LBReps->SetFocus();
}

void LBFilesValidateStr(String *S,int) {
    if (S) FileBox.TxBNom->Text=*S;
    FilesBoxClickOk();
}

void ChgdCmBLect(String *S,int Select) {
    int seltype=FileBox.CmBType->Select;
    if (seltype!=-1)
        FBChgdCmB(S,Select,(*FileBox.CmBType->LStr)[seltype],seltype);
    else
        FBChgdCmB(S,Select,NULL,-1);
}

void ChgdCmBType(String *S,int Select) {
    int sellect=FileBox.CmBLect->Select;
    if (sellect!=-1)
        FBChgdCmB((*FileBox.CmBLect->LStr)[sellect],sellect,S,Select);
    else
        FBChgdCmB(NULL,-1,S,Select);
}
//-----------------------
int OldSelLect;
void RetryDrive();
void FBChgdCmB(String *SLect,int SelectLect,String *SType,int SelectType) {
    FileBox.LBReps->PosCursor=-1;
    FileBox.LBReps->LStr->ClearListStr();
    FileBox.LBFiles->PosCursor=-1;
    FileBox.LBFiles->LStr->ClearListStr();
    if (SelectLect==-1) {
        FileBox.LabCurDir->Text="";
        return;
    }
#ifdef __MINGW32__
    int fileHandler,cdisk;
    //cdisk=(SelectLect>0)?(SelectLect+1):(SelectLect);
    cdisk = (*FileBox.CmBLect->LStr)[SelectLect]->StrPtr[0]-'a' + 1;
    _chdrive(cdisk);
#else
    chdir(FileBox.Dirs[SelectLect]);
#endif
    GetCurrentDir(FileBox.LabCurDir->Text.StrPtr, 360);
    FileBox.LabCurDir->Redraw();

#ifdef __MINGW32__
    if ((FileBox.LabCurDir->Text.StrPtr[0]!=SLect->StrPtr[0] &&
            chdir(SLect->StrPtr)) || (FileBox.LabCurDir->Text.StrPtr[0]==SLect->StrPtr[0] &&
                                      chdir(FileBox.LabCurDir->Text.StrPtr))) {
#else
    // current dir should be equal to the already set dir
    if (strcmp(FileBox.Dirs[SelectLect], FileBox.LabCurDir->Text.StrPtr) != 0) {
#endif
        FileBox.CmBLect->Select=-1;
        FileBox.CmBLect->Scan();
        FileBox.LabCurDir->Text="";
        OldSelLect=SelectLect;
        MessageBox(FileBox.MyWH, "Error", "Invalide drive !",
                   "Retry", RetryDrive, NULL, NULL, "Cancel", NULL);
        return;
    }
#ifdef __MINGW32__
    struct _finddata32_t f;
    fileHandler= _findfirst32("*.*", &f);//, FA_HIDDEN| FA_DIREC| FA_SYSTEM);
    if (fileHandler != -1) {
        for (;;) {
            if ((f.attrib&_A_SUBDIR) /*&& ((f.attrib&_A_SYSTEM)|| (f.attrib&_A_NORMAL)|| (f.attrib&_A_HIDDEN))*/ && strcmp(".",f.name) != 0) {
                FileBox.LBReps->LStr->Add(f.name);
            }
            if (_findnext32(fileHandler, &f) == -1)
                break;
        }
        _findclose(fileHandler);
    }
#else
    DIR *dir;
    struct dirent *dp;
    if ((dir = opendir (".")) != NULL) {
        while ((dp = readdir (dir)) != NULL) {

            if (dp->d_type == DT_DIR && strcmp(".",dp->d_name) != 0) {
                FileBox.LBReps->LStr->Add(dp->d_name);
            }
        }
        closedir(dir);
    }
#endif

    if(FileBox.bSortFilesDirs)
        FileBox.LBReps->LStr->Sort(FileBox.bSortAsc);

    GetCurrentDir(FileBox.LabCurDir->Text.StrPtr, 360);
    FileBox.LabCurDir->Redraw();
    if (SelectType!=-1) {
        if (SelectType>=FileBox.LStrMask->NbElement()) {
            FileBox.CmBType->Select=-1;
            MessageBox(FileBox.MyWH, "Error", "Mask file not found !",
                       "Ok", NULL, NULL, NULL, NULL, NULL);
            return;
        }

        if (FileBox.CmBType->Select!=-1) {
            ListString *LSMasks = NULL;

            LSMasks = (*FileBox.LStrMask)[FileBox.CmBType->Select]->Split('|');

            if(LSMasks != NULL) {
                for (int i=0; i<LSMasks->NbElement(); i++) {
#ifdef __MINGW32__
                    fileHandler = _findfirst32((*LSMasks)[i]->StrPtr, &f); //, FA_HIDDEN| FA_SYSTEM);
                    if (fileHandler != -1) {
                        for (;;) {
                            if (!(f.attrib&_A_SUBDIR) /*&& ((f.attrib&_A_SYSTEM)|| (f.attrib&_A_NORMAL) || (f.attrib&_A_HIDDEN))*/) {
                                FileBox.LBFiles->LStr->Add(f.name);
                            }
                            if (_findnext32(fileHandler, &f) == -1)
                                break;
                        }
                        _findclose(fileHandler);
                    }
#else
                    DIR *dir;
                    struct dirent *dp;
                    if ((dir = opendir (".")) != NULL) {
                        while ((dp = readdir (dir)) != NULL) {
                            if (dp->d_type == DT_REG && fnmatch((*LSMasks)[i]->StrPtr, dp->d_name, FNM_FILE_NAME) == 0) {
                                FileBox.LBFiles->LStr->Add(dp->d_name);
                            }
                        }
                        closedir(dir);
                    }
#endif
                }
                if(FileBox.bSortFilesDirs)
                    FileBox.LBFiles->LStr->Sort(FileBox.bSortAsc);
                delete LSMasks;
            }
        }
    }
    FBSelectFirstDirFile();
    FileBox.LBReps->SetFocus();
}
void RetryDrive() {
    FileBox.CmBLect->Select=OldSelLect;
}
//----------------------------

