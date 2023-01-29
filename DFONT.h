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

    contact: libdugl(at)hotmail.com    */

#ifndef DFONT_H_INCLUDED
#define DFONT_H_INCLUDED


#ifdef __cplusplus
extern "C" {
#endif

//** FONT Structure ****************************
typedef struct {
    int             FntPtr;
    unsigned char   FntHaut,FntDistLgn;
    char            FntLowPos, FntHighPos, FntSens;
    unsigned char   FntTab,Fntrevb[2];
    int             FntX, FntY, FntCol, FntBCol, FntDresv;
} FONT;

// FONT character loading, handling and drawing functions
// of the DUGL CHR FONT FORMAT
// ---------------------------------------------------------

extern FONT             CurFONT;
extern int              FntPtr, FntX, FntY, FntCol;
extern unsigned char    FntHaut, FntDistLgn, FntTab;
extern char             FntLowPos, FntHighPos, FntSens;
// Text drawing Mode
#define AJ_CUR_POS  0 // draw starting from the current xy text position
#define AJ_MID      1 // set the text on the middle of the current Surf View
#define AJ_SRC      2 // justify to the text source (left in case of left to right)
#define AJ_DST      3 // justify to the text destination
#define AJ_LEFT     4 // justify always to the left
#define AJ_RIGHT    5 // justify always to the right

int  LoadMemFONT(FONT *F,void *In,int SizeIn);
int  LoadFONT(FONT *F,const char *Fname);
void DestroyFONT(FONT *F);
void SetFONT(FONT *F);
void GetFONT(FONT *F);
void ClearText(); // clear text position inside the CurSurf current View
void ViewClearText(DgView *V); // // clear text position inside given RView
void SetTextAttrib(int TX,int TY,int TCol);
void SetTextPos(int TX,int TY);
void SetTextCol(int TCol); // set text color
int  GetFntYMID();
int  ViewGetFntYMID(DgView *V);
int  WidthText(const char *str); // text width in pixels
int  WidthPosText(const char *str,int pos); // text width taking only Pos characters
int  PosWidthText(const char *str,int width); // Position in *str if we progress by "width" pixels
void OutText16(const char *str);
void OutText16XY(int TX,int TY,const char *str);
int  OutText16Mode(const char *str,int Mode);
void OutText16Format(char *midStr, unsigned int sizeMidStr, char *fmt, ...);
void OutText16ModeFormat(int Mode, char *midStr, unsigned int sizeMidStr, char *fmt, ...);
int  OutText16YMode(int TY,const char *str,int Mode);
int  ViewOutText16Mode(DgView *V,const char *str,int Mode);
int  ViewGetXOutTextMode(DgView *V,const char *str,int Mode);
int  ViewOutText16YMode(DgView *V,int TY,const char *str,int Mode);
int  ViewOutText16XY(DgView *V,int TX,int TY,const char *str);

#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DFONT_H_INCLUDED

