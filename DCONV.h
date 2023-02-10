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

#ifndef DCONV_H_INCLUDED
#define DCONV_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// EFFECTS & CONVERSION ====================================

// thread safe functions
void ConvSurf8ToSurf16Pal(DgSurf *S16Dst, DgSurf *S8Src,void *PalBGR1024);
void Blur16(void *BuffImgDst, void *BuffImgSrc, int ImgWidth, int ImgHeight, int StartLine, int EndLine);
void BlurSurf16(DgSurf *S16Dst, DgSurf *S16Src);


#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DCONV_H_INCLUDED

