//#include <dir.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "DUGL.h"
#include "DGUI.H"

#include "HelpDlg.h"


MainWin *helpDLG = nullptr;
// HelpDlg
GraphBox *GphBHelp = nullptr;
Button *BtOk = nullptr;
// events
void DrawHelpGBox(GraphBox *Me);
void CloseOK();

MainWin *CreateMainWinHelpDLG(WinHandler *wh) {
    helpDLG = new MainWin(50,40,540,350,"Help",wh);


    GphBHelp= new GraphBox(helpDLG->VActiv.MinX+3,25,helpDLG->VActiv.MaxX-3,helpDLG->VActiv.MaxY-3,helpDLG, wh->m_GraphCtxt->WinGris);
    GphBHelp->GraphBoxDraw=DrawHelpGBox;
	BtOk = new Button(helpDLG->VActiv.MinX+50,1,helpDLG->VActiv.MaxX-50,1+FntHaut+6, helpDLG, "Ok", 1,0, nullptr);
	BtOk->Click = CloseOK;

	return helpDLG;
}


void DrawHelpGBox(GraphBox *Me) {
	ClearSurf16(helpDLG->MWWinHand->m_GraphCtxt->WinGrisF);

	ClearText();
	SetTextCol(helpDLG->MWWinHand->m_GraphCtxt->WinBlanc);
	OutText16Mode("\n", AJ_MID);
	OutText16Mode("F1: This Help\n", AJ_MID);
	OutText16Mode("F2: Save\n", AJ_MID);
	OutText16Mode("F3: Open\n", AJ_MID);
	OutText16Mode("F4: Open Calc Image\n", AJ_MID);
	OutText16Mode("F12: Debug Info\n", AJ_MID);
	OutText16Mode("Esc or Alt+X: Exit\n", AJ_MID);
	OutText16Mode("Del: Clear\n", AJ_MID);
	OutText16Mode("Home: Reverse\n", AJ_MID);
	OutText16Mode("End: Set All\n", AJ_MID);
	OutText16Mode("Alt+(Left|Right) arrows: Decrease/Increase Ascii\n", AJ_MID);
	OutText16Mode("Ctrl+ arrows [+Shift bigger step]: Move Calc Image\n", AJ_MID);
	OutText16Mode("Alt+ Enter: Apply Calc Image\n", AJ_MID);
	OutText16Mode("Focus on Char View + arrows: Move char\n", AJ_MID);
	OutText16Mode("Left Mouse Button on Char View: Set Pixel\n", AJ_MID);
	OutText16Mode("Right Mouse Button on Char View: Unset Pixel\n", AJ_MID);
	OutText16Mode("Ctrl+ Home: Reset Calc Image position to left/bottom corner\n", AJ_MID);
	OutText16Mode("Ctrl+ Left Mouse Button on Char View: Set Calc Image Mask\n", AJ_MID);
}

void CloseOK() {
	helpDLG->HideModal();
}
