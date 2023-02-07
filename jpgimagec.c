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

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <jpeglib.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

// JPEG ////////////////////////////////////////////////////////////////////

// jpeg error handling

struct my_error_mgr {
    struct jpeg_error_mgr pub;    /* "public" fields */

    jmp_buf setjmp_buffer;    /* for return to caller */
};

typedef struct my_error_mgr * my_error_ptr;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

METHODDEF(void)
my_error_exit (j_common_ptr cinfo) {
    /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
    my_error_ptr myerr = (my_error_ptr) cinfo->err;

    /* Always display the message. */
    /* We could postpone this until after returning, if we chose. */
    //(*cinfo->err->output_message) (cinfo);

    /* Return control to the setjmp point */
    longjmp(myerr->setjmp_buffer, 1);
}

int GetJpegImg(DgSurf **S,j_decompress_ptr cinfo) {
    JSAMPROW row_pointer[1];
    int irow,iscan;
    short *outScan;
    unsigned char *ScanPtr;
    int BfPos;
    char cgray;

    // read the jpeg image header
    jpeg_read_header(cinfo, TRUE);

    // valid jpeg
    if (cinfo->image_width<=0 || cinfo->image_height<=0) {
        jpeg_destroy_decompress(cinfo);
        return 0;
    }

    // no mem ? no RGB ? no grayscale
    if ((CreateSurf(S,cinfo->image_width,cinfo->image_height,16)==0) ||
            ((cinfo->num_components!=3) && (cinfo->num_components!=1)) ) {
        jpeg_destroy_decompress(cinfo);
        return 0;
    }
    // start decompress
    jpeg_start_decompress(cinfo);
    // alloc RGB 24bpp scanline
    row_pointer[0] =
        (unsigned char *)malloc(cinfo->output_width*cinfo->num_components);
    ScanPtr=row_pointer[0];
    // RGB 24bpp ?
    if (cinfo->num_components==3) {
        // get image scanlines
        for (iscan=0; cinfo->output_scanline<cinfo->image_height; iscan++) {

            jpeg_read_scanlines(cinfo,row_pointer, 1);
            outScan=(short*)((*S)->rlfb+((*S)->ScanLine*iscan));
            BfPos=0;
            // RGB 24 -> BGR 16 (565)
            for (irow=0; irow<(int)cinfo->image_width; irow++) {
                outScan[irow]=(ScanPtr[BfPos+2]>>3)|((ScanPtr[BfPos+1]>>2)<<5)|
                              ((ScanPtr[BfPos]>>3)<<11);
                BfPos+=3;
            }
        }
    }
    // gray scale 8bpp ?
    if (cinfo->num_components==1) {
        // get image scanlines
        for (iscan=0; cinfo->output_scanline<cinfo->image_height; iscan++) {

            jpeg_read_scanlines(cinfo,row_pointer, 1);
            outScan=(short*)((*S)->rlfb+((*S)->ScanLine*iscan));
            // gray 8bpp -> BGR 16 (565)
            for (irow=0; irow<(int)cinfo->image_width; irow++) {
                cgray=ScanPtr[irow];
                outScan[irow]=(cgray>>3)|((cgray>>2)<<5)|((cgray>>3)<<11);
            }
        }
    }
    // free ressources
    jpeg_finish_decompress(cinfo);
    jpeg_destroy_decompress(cinfo);

    free(row_pointer[0]);
    return 1;

}

int LoadJPG16(DgSurf **S,char *filename) {
    FILE *jpgFile; // source
    int retGet;
    // init jpeg
    struct jpeg_decompress_struct cinfo;
//   struct jpeg_error_mgr jerr;
    struct my_error_mgr jerr;

    // open jpeg file
    if ((jpgFile = fopen(filename,"rb")) == NULL)
        return 0;

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* libjpeg will jump here if any error occured */
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        fclose(jpgFile);
        return 0;
    }
    jpeg_create_decompress(&cinfo);

    // attach the file as source
    jpeg_stdio_src(&cinfo, jpgFile);

    retGet=GetJpegImg(S,&cinfo);
    // close file
    fclose(jpgFile);

    return retGet;
}

// LoadMemJpeg16 -------------------------------------

int LoadMemJPG16(DgSurf **S,void *buffJpeg,int sizeBuff) {
    // init jpeg
    struct jpeg_decompress_struct cinfo;
//   struct jpeg_error_mgr jerr;
    struct my_error_mgr jerr;
    int retGet;

    // valid buffer ? size ?
    if (buffJpeg==NULL || sizeBuff<=1)
        return 0;

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* libjpeg will jump here if any error occured */
    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        return 0;
    }
    jpeg_create_decompress(&cinfo);

    // attach the file as source
    jpeg_mem_src(&cinfo, (unsigned char*)buffJpeg,sizeBuff);

    retGet=GetJpegImg(S,&cinfo);

    return retGet;
}


int SaveJPG16(DgSurf *S,char *filename,int quality) {
    FILE *jpgFile; // destination
    int irow,iscan,BfPos;
    // init jpeg
    struct jpeg_compress_struct cinfo;
    //   struct jpeg_error_mgr jerr;
    struct my_error_mgr jerr;
    // scanline jpeg data to compress
    JSAMPROW row_pointer[1];
    unsigned char *ScanPtr;
    unsigned short *InScan;

    // invalid Surf
    if (S==NULL) return 0;

    // alloc line data
    row_pointer[0] = (unsigned char *)malloc(S->ResH*3);
    ScanPtr=row_pointer[0];

    // non mem ?
    if (row_pointer[0]==NULL)
        return 0;

    // open jpeg file
    if ((jpgFile = fopen(filename,"wb")) == NULL)
        return 0;

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* libjpeg will jump here if any error occured */
    if (setjmp(jerr.setjmp_buffer)) {
        free(row_pointer[0]);
        jpeg_destroy_compress(&cinfo);
        fclose(jpgFile);
        return 0;
    }
    // create the compress
    jpeg_create_compress(&cinfo);
    // specify destination
    jpeg_stdio_dest(&cinfo,jpgFile);
    // setting parameter
    cinfo.image_width=S->ResH;
    cinfo.image_height=S->ResV;
    cinfo.input_components=3;
    cinfo.in_color_space=JCS_RGB;
    // set defaults
    jpeg_set_defaults(&cinfo);
    // set quality
    jpeg_set_quality(&cinfo,quality, TRUE);

    // start compressing
    jpeg_start_compress(&cinfo,TRUE);

    for (iscan=0; cinfo.next_scanline<cinfo.image_height; iscan++) {

        InScan=(unsigned short*)(S->rlfb+(S->ScanLine*iscan));
        BfPos=0;
        // BGR 16 -> RGB 24
        for (irow=0; irow<S->ResH; irow++) {
            ScanPtr[BfPos+2]=(InScan[irow]&0x1f)<<3;
            ScanPtr[BfPos+1]=(InScan[irow]&0x7e0)>>3;
            ScanPtr[BfPos+0]=(InScan[irow]&0xf800)>>8;
            BfPos+=3;
        }
        jpeg_write_scanlines(&cinfo,row_pointer,1);
    }

    // free ressources
    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
    free(row_pointer[0]);
    fclose(jpgFile);
    return 1;
}

int SaveMemJPG16(DgSurf *S,void **OutJpg, int *SizeOutJpg, int quality) {
    int irow,iscan,BfPos;
    // init jpeg
    struct jpeg_compress_struct cinfo;
    //   struct jpeg_error_mgr jerr;
    struct my_error_mgr jerr;
    // scanline jpeg data to compress
    JSAMPROW row_pointer[1];
    unsigned char *ScanPtr;
    unsigned short *InScan;

    // invalid Surf
    if (S==NULL) return 0;

    // alloc line data
    row_pointer[0] = (unsigned char *)malloc(S->ResH*3);
    ScanPtr=row_pointer[0];

    // non mem ?
    if (row_pointer[0]==NULL)
        return 0;

    /* We set up the normal JPEG error routines, then override error_exit. */
    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = my_error_exit;
    /* libjpeg will jump here if any error occured */
    if (setjmp(jerr.setjmp_buffer)) {
        free(row_pointer[0]);
        jpeg_destroy_compress(&cinfo);
        return 0;
    }
    // create the compress
    jpeg_create_compress(&cinfo);
    // specify destination
    jpeg_mem_dest(&cinfo, (unsigned char **) OutJpg, (unsigned long*) SizeOutJpg);
    // setting parameter
    cinfo.image_width=S->ResH;
    cinfo.image_height=S->ResV;
    cinfo.input_components=3;
    cinfo.in_color_space=JCS_RGB;
    // set defaults
    jpeg_set_defaults(&cinfo);
    // set quality
    jpeg_set_quality(&cinfo,quality, TRUE);

    // start compressing
    jpeg_start_compress(&cinfo,TRUE);

    for (iscan=0; cinfo.next_scanline<cinfo.image_height; iscan++) {

        InScan=(unsigned short*)(S->rlfb+(S->ScanLine*iscan));
        BfPos=0;
        // BGR 16 -> RGB 24
        for (irow=0; irow<S->ResH; irow++) {
            ScanPtr[BfPos+2]=(InScan[irow]&0x1f)<<3;
            ScanPtr[BfPos+1]=(InScan[irow]&0x7e0)>>3;
            ScanPtr[BfPos+0]=(InScan[irow]&0xf800)>>8;
            BfPos+=3;
        }

        jpeg_write_scanlines(&cinfo,row_pointer,1);
    }

    // free ressources
    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
    free(row_pointer[0]);

    return 1;
}



