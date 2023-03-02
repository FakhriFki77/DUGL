#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <DUGL.h>
#include <DGUI.H>
#include "AboutDlg.h"


MainWin *aboutDLG = nullptr;
// HelpDlg
GraphBox *GphBAbout = nullptr;
Button *BtOkAbout = nullptr;
// events
void DrawAboutGBox(GraphBox *Me);
void CloseOKAbout();

MainWin *CreateMainWinAboutDLG(WinHandler *wh) {
    aboutDLG = new MainWin(90,140,460,200,"About",wh);

    GphBAbout= new GraphBox(aboutDLG->VActiv.MinX+3,25,aboutDLG->VActiv.MaxX-3,aboutDLG->VActiv.MaxY-3,aboutDLG, wh->m_GraphCtxt->WinGris);
    GphBAbout->GraphBoxDraw=DrawAboutGBox;
	BtOkAbout = new Button(aboutDLG->VActiv.MinX+50,1,aboutDLG->VActiv.MaxX-50,1+FntHaut+6, aboutDLG, "Ok", 1,0, nullptr);
	BtOkAbout->Click = CloseOKAbout;

	return aboutDLG;
}

void DrawAboutGBox(GraphBox *Me) {
	ClearSurf16(aboutDLG->MWWinHand->m_GraphCtxt->WinGrisF);
	char midstr[128];
	char versionType[20];
	char duglVersionType[20];

	switch (EDCHR2_VERSION_TYPE) {
		case 'a':
		case 'A':
			strcpy(versionType, "Alpha");
			break;
		case 'b':
		case 'B':
			strcpy(versionType, "Beta");
			break;
		case 'r':
		case 'R':
			strcpy(versionType, "Release");
			break;
		default:
			strcpy(versionType, "???");
	}
	switch (DUGL_VERSION_TYPE) {
		case 'a':
		case 'A':
			strcpy(duglVersionType, "Alpha");
			break;
		case 'b':
		case 'B':
			strcpy(duglVersionType, "Beta");
			break;
		case 'r':
		case 'R':
			strcpy(duglVersionType, "Release");
			break;
		default:
			strcpy(duglVersionType, "???");
	}
	ClearText();
	SetTextCol(aboutDLG->MWWinHand->m_GraphCtxt->WinBlanc);
	OutText16Mode("\n", AJ_MID);
	OutText16Mode("Edchr2: DUGL CHR FONT Editor", AJ_MID);
	OutText16Mode("\n", AJ_MID);
	OutText16ModeFormat(AJ_MID, midstr, 127,"V%i.%i %s r%i \n", EDCHR2_VERSION_MAJOR, EDCHR2_VERSION_MINOR, versionType, EDCHR2_VERSION_PATCH);
	OutText16Mode("\n", AJ_MID);
	OutText16ModeFormat(AJ_MID, midstr, 127, "Made using DUGL V%i.%i %s r%i \n", DUGL_VERSION_MAJOR, DUGL_VERSION_MINOR, duglVersionType, DUGL_VERSION_PATCH);
	OutText16Mode("https://github.com/FakhriFki77/DUGL\n", AJ_MID);
	OutText16Mode("Copyright (C) 2023 Fakhri Feki\n", AJ_MID);
	OutText16Mode("contact: libdugl(at)hotmail.com", AJ_MID);
}

void CloseOKAbout() {
	aboutDLG->HideModal();
}
