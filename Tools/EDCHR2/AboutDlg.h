#ifndef ABOUTDLG_H_INCLUDED
#define ABOUTDLG_H_INCLUDED

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "DUGL.h"
#include "DGUI.H"

#define EDCHR2_VERSION_MAJOR		1
#define EDCHR2_VERSION_MINOR		0
#define EDCHR2_VERSION_TYPE			'b' // a alpha, b beta, r release
#define EDCHR2_VERSION_PATCH		3

MainWin *CreateMainWinAboutDLG(WinHandler *WH);

#endif // ABOUTDLG_H_INCLUDED
