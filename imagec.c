/*	Dust Ultimate Game Library (DUGL)
    Copyright (C) 2022	Fakhri Feki

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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include "SDL.h"

#include "DUGL.h"
#include "intrndugl.h"


// BMP

short BMPSign = 'MB';

int  LoadBMP(DgSurf **S,const char *filename,void *PalBGR1024)
{
	FILE *InBMP;
	int j,padd;
	HeadBMP hbmp;
	InfoBMP ibmp;
	char *Linedata;

	if (fopen_s(&InBMP, filename,"rb") != 0) return 0;

    SDL_memset(&hbmp, 0, sizeof(HeadBMP));
    SDL_memset(&ibmp, 0, sizeof(InfoBMP));

	// read head
	fread(&hbmp,sizeof(HeadBMP),1,InBMP);

	// verify signature and data offset
	if (hbmp.Sign!=BMPSign ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  { fclose(InBMP); return 0; }

	// read info
	fread(&ibmp,sizeof(InfoBMP),1,InBMP);

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=8 || ibmp.Compression!=0) {
	   fclose(InBMP); return 0;
	}

	// no mem
	if (CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,8)==0) {
	   fclose(InBMP); return 0;
	}

	// read palette
	fread(PalBGR1024,1024,1,InBMP);

	// seek to data
	fseek(InBMP,hbmp.DataOffset,SEEK_SET);
	// read data
	padd=ibmp.ImgWidth&3;
	for (j=ibmp.ImgHeight-1;j>=0;j--) {
	  Linedata=(char*)((*S)->rlfb+(j*ibmp.ImgWidth));
	  fread(Linedata,ibmp.ImgWidth,1,InBMP);
	  if (padd) fseek(InBMP,4-padd,SEEK_CUR);
	}

	fclose(InBMP);
	return 1;
}


int  LoadMemBMP16(DgSurf **S,void *In,int SizeIn)
{
	unsigned int irow,padd,CurInBMP,BfPos;
	int j;
	HeadBMP hbmp;
	InfoBMP ibmp;
	unsigned short *Linedata;
	unsigned char *tempLine;

	if (In==NULL || SizeIn<=(int)(sizeof(HeadBMP)+sizeof(InfoBMP)))
	  return 0;

    SDL_memset(&hbmp, 0, sizeof(HeadBMP));
    SDL_memset(&ibmp, 0, sizeof(InfoBMP));

	// read head
	memcpy(&hbmp,In,sizeof(HeadBMP));

	// verify signature and data offset
	if (hbmp.Sign != BMPSign ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  return 0;

	// read info
	memcpy(&ibmp,(void*)((size_t)(In)+sizeof(HeadBMP)), sizeof(InfoBMP));

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=24 || ibmp.Compression!=0)
	   return 0;

	// no mem
	if (CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,16)==0)
	   return 0;

	// seek to data
	CurInBMP=hbmp.DataOffset;
	// read data
	padd=(ibmp.ImgWidth*3)&3;
	for (j=ibmp.ImgHeight-1;j>=0;j--) {
	  if (CurInBMP+ibmp.ImgWidth*3>(unsigned int)SizeIn) break;
	  Linedata=(unsigned short*)((*S)->rlfb+(j*ibmp.ImgWidth*2));
	  tempLine=(unsigned char*)(((size_t)(In)+CurInBMP));
	  BfPos=0;
	  for (irow=0;irow<ibmp.ImgWidth;irow++) {
	    Linedata[irow]=(tempLine[BfPos]>>3)|((tempLine[BfPos+1]>>2)<<5)|
		((tempLine[BfPos+2]>>3)<<11);
	      BfPos+=3;
	  }

	  CurInBMP+=ibmp.ImgWidth*3;
	  if (padd) CurInBMP+=(4-padd);
	}

	return 1;
}
int  LoadBMP16(DgSurf **S, char *filename)
{
	FILE *InBMP;
	unsigned int irow,padd,BfPos;
	int j;
	HeadBMP hbmp;
	InfoBMP ibmp;
	short *Linedata;
	unsigned char *tempLine;


	if (fopen_s(&InBMP, filename,"rb") != 0) return 0;

    SDL_memset(&hbmp, 0, sizeof(HeadBMP));
    SDL_memset(&ibmp, 0, sizeof(InfoBMP));

	// read head
	fread(&hbmp,sizeof(HeadBMP),1,InBMP);

	// verify signature and data offset
	if (hbmp.Sign != BMPSign ||
	    (hbmp.DataOffset<sizeof(HeadBMP)+sizeof(InfoBMP)) ||
	     hbmp.DataOffset>hbmp.SizeFile)
	  { fclose(InBMP); return 0; }

	// read info
	fread(&ibmp,sizeof(InfoBMP),1,InBMP);

	if (ibmp.ImgWidth==0 || ibmp.ImgHeight==0 ||
	    ibmp.BitsPixel!=24 || ibmp.Compression!=0) {
	   fclose(InBMP); return 0;
	}

	// no mem
	if (CreateSurf(S,ibmp.ImgWidth,ibmp.ImgHeight,16)==0)
    {
        fclose(InBMP);
        return 0;
	}

	// seek to data
	fseek(InBMP,hbmp.DataOffset,SEEK_SET);
	// alloc temporary
	tempLine = (unsigned char*)malloc(ibmp.ImgWidth*3);

	// read data
	if (tempLine!=NULL)
    {
        padd=(ibmp.ImgWidth*3)&3;
        for (j = ibmp.ImgHeight-1; j >= 0; j--)
        {
            Linedata = (short*)((*S)->rlfb+(j*ibmp.ImgWidth*2));
            fread(tempLine, ibmp.ImgWidth*3, 1, InBMP);
            if (padd) fseek(InBMP, 4-padd, SEEK_CUR);
            BfPos = 0;
            for (irow=0;irow<ibmp.ImgWidth;irow++)
            {
                Linedata[irow] = (tempLine[BfPos]>>3)|((tempLine[BfPos+1]>>2)<<5)| ((tempLine[BfPos+2]>>3)<<11);
                BfPos += 3;
            }
        }
        free(tempLine);
	}

	fclose(InBMP);

	return 1;

}
int  SaveMemBMP16(DgSurf *S,void *Out)
{
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP *hbmp;
	InfoBMP *ibmp;
	short *Linedata;
	unsigned char *tempLine;

	if (Out==NULL || (sizeBMPFile=SizeSaveBMP16(S))==0) return 0;

	hbmp=(HeadBMP*)(Out);
	ibmp=(InfoBMP*)((size_t)(Out)+sizeof(HeadBMP));

    SDL_memset(&hbmp, 0, sizeof(HeadBMP));
    SDL_memset(&ibmp, 0, sizeof(InfoBMP));

	// init header
	hbmp->Sign = BMPSign;
	hbmp->SizeFile = sizeBMPFile;
	hbmp->DataOffset = sizeof(HeadBMP)+sizeof(InfoBMP);
	// init info
	ibmp->SizeInfo = sizeof(InfoBMP);
	ibmp->ImgWidth = S->ResH;  ibmp->ImgHeight = S->ResV;
	ibmp->Planes = 1;
	ibmp->BitsPixel = 24;

	// compute padd
	padd=(ibmp->ImgWidth*3)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp->ImgWidth*3+padd;
	tempLine =
	  (unsigned char*)((size_t)(Out)+sizeof(HeadBMP)+sizeof(InfoBMP));

	// read data
	if (tempLine!=NULL)
	{
        for (j=ibmp->ImgHeight-1;j>=0;j--)
        {
            Linedata=(short*)(S->rlfb+(j*ibmp->ImgWidth*2));
            BfPos=0;
            // BGR 16 -> RGB 24
            for (irow=0;irow<S->ResH;irow++)
            {
                tempLine[BfPos] = (Linedata[irow]&0x1f)<<3;
                tempLine[BfPos+1] = (Linedata[irow]&0x7e0)>>3;
                tempLine[BfPos+2] = (Linedata[irow]&0xf800)>>8;
                BfPos += 3;
            }
            tempLine+=sizeline;
        }
	}

	return 1;
}

int  SaveBMP16(DgSurf *S, char *filename)
{
	FILE *OutBMP;
	int irow,j,padd,BfPos,sizeBMPFile,sizeline;
	HeadBMP hbmp;
	InfoBMP ibmp;
	short *Linedata;
	unsigned char *tempLine;
	if ((sizeBMPFile=SizeSaveBMP16(S))==0) return 0;

	if (fopen_s(&OutBMP, filename,"wb") != 0) return 0;

    SDL_memset(&hbmp, 0, sizeof(HeadBMP));
    SDL_memset(&ibmp, 0, sizeof(InfoBMP));

	// init header
	hbmp.Sign = BMPSign;
	hbmp.SizeFile = sizeBMPFile;
	hbmp.DataOffset = sizeof(HeadBMP)+sizeof(InfoBMP);
	// init info
	ibmp.SizeInfo = sizeof(InfoBMP);
	ibmp.ImgWidth = S->ResH;
	ibmp.ImgHeight = S->ResV;
	ibmp.Planes = 1;
	ibmp.BitsPixel = 24;

	// write header
	fwrite(&hbmp,sizeof(HeadBMP),1,OutBMP);
	// read info
	fwrite(&ibmp,sizeof(InfoBMP),1,OutBMP);

	// compute padd
	padd=(ibmp.ImgWidth*3)&3;
	if (padd>0) padd=4-padd;
	sizeline=ibmp.ImgWidth*3+padd;
	// alloc temporary
	tempLine = (unsigned char*)malloc(sizeline);

	// read data
	if (tempLine!=NULL) {
	  for (j=ibmp.ImgHeight-1;j>=0;j--) {
	    Linedata=(short*)(S->rlfb+(j*ibmp.ImgWidth*2));
	    //if (padd) fseek(InBMP,4-padd,SEEK_CUR);
	    BfPos=0;
	    // BGR 16 -> RGB 24
	    for (irow=0;irow<S->ResH;irow++) {
	      tempLine[BfPos]=(Linedata[irow]&0x1f)<<3;
	      tempLine[BfPos+1]=(Linedata[irow]&0x7e0)>>3;
	      tempLine[BfPos+2]=(Linedata[irow]&0xf800)>>8;
	      BfPos+=3;
	    }
	    fwrite(tempLine,sizeline,1,OutBMP);
	  }
	  free(tempLine);
	}

	fclose(OutBMP);
	return 1;
}

int  SizeSaveBMP16(DgSurf *S)
{
	int padd=0;
	if (S->rlfb==0 || S->BitsPixel!=16 || S->ResH<=0 || S->ResV<=0)
	  return 0;
	padd=(S->ResH*3)&3;
	if (padd>0) padd=4-padd;
	return sizeof(HeadBMP)+sizeof(InfoBMP)+(((S->ResH*3)+padd)*S->ResV);
}

// load a 8bpp BMP and convert it to 16 bpp
int LoadBMP8To16(DgSurf **S16,char *filename)
{
  char tmpBGRA[1024];
  DgSurf *SGIF8bpp;
  if (LoadBMP(&SGIF8bpp,filename,tmpBGRA)==0) return 0;
  if (CreateSurf(S16,SGIF8bpp->ResH,SGIF8bpp->ResV,16)==0) {
    DestroySurf(SGIF8bpp);
    return 0;
  }
  ConvSurf8ToSurf16Pal(*S16,SGIF8bpp,tmpBGRA);
  DestroySurf(SGIF8bpp);
  return 1;
}


// PCX

int  LoadMemPCX(DgSurf **S,void *In,void *PalBGR1024,int SizeIn)
{
    HeadPCX hpcx;
	char PalRGB[768];
	int ResHz,ResVt,i;

    memcpy(&hpcx,In,sizeof(HeadPCX));
	if (hpcx.Sign!=0xa || hpcx.Ver<5 || hpcx.BitPixel!=8) return 0;
	ResHz=hpcx.X2-hpcx.X1+1;
	ResVt=hpcx.Y2-hpcx.Y1+1;
	memcpy(&PalRGB,&((char*)(In))[SizeIn-768],768);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
    }

	if (CreateSurf(S,ResHz,ResVt,8)==0) return 0;
	if (hpcx.Comp==1)
	   InRLE((char*)(In)+sizeof(HeadPCX),(void*)((*S)->rlfb),(*S)->SizeSurf);
	else return 0;
	return 1;
}

int  LoadPCX(DgSurf **S, char *Fname,void *PalBGR1024)
{
    FILE *InPCX;
	HeadPCX hpcx;
	void *BuffIn = NULL;
	char PalRGB[768];
	int FinIn,ResHz,ResVt,i;

	if (fopen_s(&InPCX, Fname,"rb") != 0) return 0;
	fread(&hpcx,sizeof(HeadPCX),1,InPCX);
	if (hpcx.Sign!=0xa || hpcx.Ver<5 || hpcx.BitPixel!=8)
	  { fclose(InPCX); return 0; }
	ResHz=hpcx.X2-hpcx.X1+1;
	ResVt=hpcx.Y2-hpcx.Y1+1;
	fseek(InPCX,-769,SEEK_END);
	fseek(InPCX,1,SEEK_CUR);
	fread(&PalRGB,768,1,InPCX);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	FinIn=ftell(InPCX);
	if (CreateSurf(S,ResHz,ResVt,8)==0) { fclose(InPCX); return 0; }
  	fseek(InPCX,sizeof(HeadPCX),SEEK_SET);
	if (hpcx.Comp==1) {
	  BuffIn=malloc(FinIn-sizeof(HeadPCX)+1);
	  if (BuffIn==NULL)
	    { DestroySurf(*S); fclose(InPCX); return 0; }
	  fread(BuffIn,FinIn-sizeof(HeadPCX)+1,1,InPCX);
	  InRLE(BuffIn,(void*)((*S)->rlfb),ResHz*ResVt);
	 }
	 else {
	   free(BuffIn);
	   fclose(InPCX);
	   return 0;
	 }
   	free(BuffIn);
	fclose(InPCX);
	return 1;
}

int LoadMemPCX16(DgSurf **S16,void *In,int SizeIn)
{
    char tmpBGRA[1024];
    DgSurf *SPCX8bpp;
    if (LoadMemPCX(&SPCX8bpp,In,tmpBGRA,SizeIn)==0) return 0;
    if (CreateSurf(S16,SPCX8bpp->ResH,SPCX8bpp->ResV,16)==0)
    {
        DestroySurf(SPCX8bpp);
        return 0;
    }
    ConvSurf8ToSurf16Pal(*S16,SPCX8bpp,tmpBGRA);
    DestroySurf(SPCX8bpp);

    return 1;
}

int LoadPCX16(DgSurf **S16,char *filename)
{
    char tmpBGRA[1024];
    DgSurf *SPCX8bpp;
    if (LoadPCX(&SPCX8bpp, filename,tmpBGRA)==0) return 0;
    if (CreateSurf(S16,SPCX8bpp->ResH,SPCX8bpp->ResV,16)==0)
    {
        DestroySurf(SPCX8bpp);
        return 0;
    }
    ConvSurf8ToSurf16Pal(*S16,SPCX8bpp,tmpBGRA);
    DestroySurf(SPCX8bpp);

    return 1;
}

// GIF

int  LoadMemGIF(DgSurf **S,void *In,void *PalBGR1024,int SizeIn)
{	HeadGIF hgif;
	ExtBlock ExtBGif;
	DescImgGIF descimg;
	void *BuffIn,*BuffS,*BuffD;
	char PalRGB[768];
	unsigned char SizeExt,SizeBl;
	int CurInGIF = 0, ResHz = 0, ResVt = 0, i = 0, bytesOutLZW = 0, bytesInLZW = 0;

	if ((size_t)(SizeIn)<sizeof(HeadGIF)) return 0;
	memcpy(&hgif,In,sizeof(HeadGIF));
	CurInGIF=sizeof(HeadGIF);
	if (hgif.Sign!='8FIG' || (hgif.IndicRes&7)!=7) return 0;
	if ((sizeof(HeadGIF)+768)>(size_t)(SizeIn)) return 0;
	if (hgif.IndicRes&128) {
           memcpy(&PalRGB,(char*)(In)+CurInGIF,768);
           CurInGIF+=768;
	}
	for (;;) {
	   memcpy(&ExtBGif,(char*)(In)+CurInGIF,sizeof(ExtBlock));
	   if (ExtBGif.SignExt!='!') break;
	   CurInGIF+=sizeof(ExtBlock);
	   SizeExt=ExtBGif.Size;
	   for (;;) {
              if ((CurInGIF+=SizeExt)>SizeIn) return 0;
              memcpy(&SizeExt,(char*)(In)+CurInGIF,1); CurInGIF++;
	      if (SizeExt==0) break;
	   }
	}
	memcpy(&descimg,(char*)(In)+CurInGIF,sizeof(DescImgGIF));
	CurInGIF+=sizeof(DescImgGIF);
	if (CurInGIF>SizeIn) return 0;
	if (descimg.Sign!=','/* || (descimg.Indicateur&7)!=7*/)
	   return 0;

	if (descimg.Indicateur&128) {
           if (CurInGIF+768>SizeIn) return 0;
           memcpy(&PalRGB,(char*)(In)+CurInGIF,768);
           CurInGIF+=768;
          }
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	ResHz=descimg.ResHz; ResVt=descimg.ResVt;
	if (CreateSurf(S,ResHz,ResVt,8)==0) return 0;
	if ((BuffIn=malloc(SizeIn+1-CurInGIF))==NULL) return 0;
// Preparation du buffer
	SizeBl=((unsigned char*)((char*)(In)+CurInGIF+1))[0];
	memmove(BuffIn,&((char*)(In))[CurInGIF],SizeBl+2);
    bytesInLZW+=(int)SizeBl;
	BuffD=&((char*)(BuffIn))[SizeBl+2];
	BuffS=&((char*)(In))[CurInGIF+SizeBl+2];
	for (;;) {
	   SizeBl=((unsigned char*)(BuffS))[0];
	   if (SizeBl==0) break;
	   bytesInLZW+=(int)SizeBl;
	   BuffS = &((char*)BuffS)[1];
	   memmove(BuffD,BuffS,(int)SizeBl);
	   BuffS = &((char*)BuffS)[SizeBl];
	   BuffD = &((char*)BuffD)[SizeBl];
	}
	bytesOutLZW = InLZW((char*)(BuffIn)+2,(void*)((*S)->rlfb), ResHz*ResVt);
	free(BuffIn);
    if (bytesOutLZW < 0) {
        DestroySurf(*S);
        return 0;
    }
	return 1;
}

int  LoadGIF(DgSurf **S, char *Fname,void *PalBGR1024)
{	FILE *InGIF;
	HeadGIF hgif;
	ExtBlock ExtBGif;
	DescImgGIF descimg;
	void *BuffIn,*BuffS,*BuffD;
	char PalRGB[768];
	unsigned char SizeExt,BuffExt[255],SizeBl;
	int FinInGIF = 0, DebInGIF = 0, CurInGIF = 0, ResHz = 0, ResVt = 0,i = 0, bytesOutLZW = 0, bytesInLZW = 0;
	if (fopen_s(&InGIF, Fname,"rb") != 0) return 0;
	fread(&hgif,sizeof(HeadGIF),1,InGIF);
	if (hgif.Sign!='8FIG' || (hgif.IndicRes&7)!=7)
	  { fclose(InGIF); return 0; }
	if (hgif.IndicRes&128) fread(&PalRGB,768,1,InGIF);
   	CurInGIF=ftell(InGIF);
	for (;;) {
	   CurInGIF=ftell(InGIF);
	   fread(&ExtBGif,sizeof(ExtBlock),1,InGIF);
	   if (ExtBGif.SignExt!='!') break;
	   SizeExt=ExtBGif.Size;
	   for (;;) {
	      fread(&BuffExt,SizeExt,1,InGIF);
	      fread(&SizeExt,1,1,InGIF);
	      if (SizeExt==0) break;
	   }
	}
	fseek(InGIF,CurInGIF,SEEK_SET);
	fread(&descimg,sizeof(DescImgGIF),1,InGIF);
	if (descimg.Sign!=','/* || (descimg.Indicateur&7)!=7*/)
	  { return 0; }
	if (descimg.Indicateur&128) fread(&PalRGB,768,1,InGIF);
	for (i=0;i<256;i++) {
	   ((char*)(PalBGR1024))[i*4]=PalRGB[i*3+2];
	   ((char*)(PalBGR1024))[i*4+1]=PalRGB[i*3+1];
	   ((char*)(PalBGR1024))[i*4+2]=PalRGB[i*3];
	  }
	ResHz=descimg.ResHz; ResVt=descimg.ResVt;
	if (CreateSurf(S,ResHz,ResVt,8) ==0) {
	    fclose(InGIF); return 0;
	}

	DebInGIF=ftell(InGIF);
	fseek(InGIF,0,SEEK_END);
	FinInGIF=ftell(InGIF);
	fseek(InGIF,DebInGIF,SEEK_SET);
	BuffIn=SDL_malloc(FinInGIF-DebInGIF+4);

	if (BuffIn==NULL) { DestroySurf(*S); fclose(InGIF); return 0; }
	fread(BuffIn,FinInGIF-DebInGIF+1,1,InGIF);
	SizeBl=((unsigned char*)BuffIn)[1];
    bytesInLZW+=(int)SizeBl;
	BuffD=BuffS=&((char*)BuffIn)[SizeBl+2];
	for (;;) {
	   SizeBl=((unsigned char*)(BuffS))[0];
	   if (SizeBl==0) break;
	   bytesInLZW+=(int)SizeBl;
	   BuffS = &((char*)BuffS)[1];
	   memmove(BuffD,BuffS,(int)SizeBl);
	   BuffS = &((char*)BuffS)[SizeBl];
	   BuffD = &((char*)BuffD)[SizeBl];
	}
	bytesOutLZW = InLZW(&((char*)BuffIn)[2],(void*)(*S)->rlfb, ResHz*ResVt);
	SDL_free(BuffIn);
	fclose(InGIF);
    if (bytesOutLZW < 0) {
        DestroySurf(*S);
        return 0;
    }
	return 1;
}

// load from memory a 8bpp gif and convert it to 16 bpp
int LoadMemGIF16(DgSurf **S16,void *In,int SizeIn) {
  char tmpBGRA[1024];
  DgSurf *SGIF8bpp = NULL;
  if (LoadMemGIF(&SGIF8bpp,In,tmpBGRA,SizeIn)==0) return 0;
  if (CreateSurf(S16,SGIF8bpp->ResH,SGIF8bpp->ResV,16)==0) {
    DestroySurf(SGIF8bpp);
    return 0;
  }
  ConvSurf8ToSurf16Pal(*S16,SGIF8bpp,tmpBGRA);
  DestroySurf(SGIF8bpp);

  return 1;
}


// load a 8bpp gif and convert it to 16 bpp
int LoadGIF16(DgSurf **S16,char *filename) {
  char tmpBGRA[1024];
  DgSurf *SGIF8bpp;
  if (LoadGIF(&SGIF8bpp,filename,tmpBGRA)==0) return 0;
  if (CreateSurf(S16,SGIF8bpp->ResH,SGIF8bpp->ResV,16)==0) {
    DestroySurf(SGIF8bpp);
    return 0;
  }
  ConvSurf8ToSurf16Pal(*S16,SGIF8bpp,tmpBGRA);
  DestroySurf(SGIF8bpp);

  return 1;
}


