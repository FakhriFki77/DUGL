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

#ifndef DIMAGE_H_INCLUDED
#define DIMAGE_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// IMAGE Support ============================================

// COMPRESSION

void InRLE(void *InBuffRLE,void *Out,int LenOut);
void OutRLE(void *OutBuffRLE,void *In,int LenIn,int ResHz);
int  SizeOutRLE(void *In,int LenIn,int ResHz);
int InLZW(void *InBuffLZW,void *Out, int LenOut);

// BMP
int LoadBMP(DgSurf **S,const char *filename,void *PalBGR1024);
int LoadMemBMP16(DgSurf **S,void *In,int SizeIn); // load a 24bpp uncompressed BMP into a 16bpp Surf
int LoadBMP16(DgSurf **S,char *filename);
int SaveMemBMP16(DgSurf *S,void *Out); // save  a 16bpp surf into a 24bpp uncompressed BMP
int SaveBMP16(DgSurf *S,char *filename);
int SizeSaveBMP16(DgSurf *S);
int LoadBMP8To16(DgSurf **S16,char *filename); // load a 8bpp BMP and convert it to 16 bpp
// GIF
int LoadMemGIF(DgSurf **S,void *In,void *PalBGR1024,int SizeIn);
int LoadGIF(DgSurf **S,char *filename,void *PalBGR1024);
int LoadMemGIF16(DgSurf **S16,void *In,int SizeIn); // load a 8bpp GIF and convert it to 16 bpp
int LoadGIF16(DgSurf **S16,char *filename);
// PCX
int LoadMemPCX(DgSurf **S,void *In,void *PalBGR1024,int SizeIn);
int LoadPCX(DgSurf **S,char *filename,void *PalBGR1024);
int LoadMemPCX16(DgSurf **S,void *In,int SizeIn); // load a 8bpp PCX and convert it to 16 bpp
int LoadPCX16(DgSurf **S,char *filename);
// PNG
int LoadPNG16(DgSurf **S,char *filename);
int LoadMemPNG16(DgSurf **S, void *In, int SizeIn);
// JPG
int LoadJPG16(DgSurf **S,char *filename);
int LoadMemJPG16(DgSurf **S,void *buffJpeg,int sizeBuff);
int SaveJPG16(DgSurf *S,char *filename,int quality);
int SaveMemJPG16(DgSurf *S,void **OutJpg, int *SizeOutJpg, int quality);

#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DIMAGE_H_INCLUDED

