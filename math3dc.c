/*  Dust Ultimate Game Library (DUGL)
    Copyright (C) 2025  Fakhri Feki

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

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

DVEC4 zeroDVEC4 __attribute__ ((aligned (16))) = { {0.0f, 0.0f, 0.0f, 0.0f } };

void *CreateDVEC4() {
    return SDL_SIMDAlloc(sizeof(DVEC4));
}

DVEC4 *CreateInitDVEC4(float x, float y, float z, float d) {
    DVEC4 *vec4 = (DVEC4 *)SDL_SIMDAlloc(sizeof(DVEC4));
    if (vec4 != NULL) {
        vec4->x = x; vec4->y = y; vec4->z = z; vec4->d = d;
    }
    return vec4;
}

void *CreateDVEC4Array(int count) {
    void *resDVEC4Array = SDL_SIMDAlloc(sizeof(DVEC4)*(size_t)(count));
    if (resDVEC4Array != NULL)
        StoreDVEC4(resDVEC4Array, &zeroDVEC4, count);
    return resDVEC4Array;
}

DVEC4 *CreateInitDVEC4Array(DVEC4 *vec4init, int count) {
    DVEC4 *vec4array = (DVEC4 *)SDL_SIMDAlloc(sizeof(DVEC4)*count);
    return vec4array;
}

DVEC4i *CreateInitDVEC4i(int x, int y, int z, int d) {
    DVEC4i *vec4 = (DVEC4i *)SDL_SIMDAlloc(sizeof(DVEC4i));
    if (vec4 != NULL) {
        vec4->x = x; vec4->y = y; vec4->z = z; vec4->d = d;
    }
    return vec4;
}

DVEC4i *CreateInitDVEC4iArray(DVEC4i *vec4init, int count) {
    DVEC4i *vec4array = (DVEC4i *)SDL_SIMDAlloc(sizeof(DVEC4i)*count);
    if (vec4array != NULL) {
        StoreDVEC4(vec4array, vec4init, count);
    }
    return vec4array;
}

void DestroyDVEC4(void *vec4) {
    SDL_SIMDFree(vec4);
}

void *CreateDVEC2() {
    return SDL_SIMDAlloc(sizeof(DVEC2));
}

void *CreateDVEC2Array(int count) {
    return SDL_SIMDAlloc(sizeof(DVEC2)*(size_t)(count));
}

void DestroyDVEC2(void *vec2) {
    SDL_SIMDFree(vec2);
}

// DMatrix4 ==========
DMatrix4 identityDMatrix4 __attribute__ ((aligned (16))) = {
    .raw = {
         1.0f, 0.0f, 0.0f, 0.0f,
         0.0f, 1.0f, 0.0f, 0.0f,
         0.0f, 0.0f, 1.0f, 0.0f,
         0.0f, 0.0f, 0.0f, 1.0f}
};

DMatrix4 *CreateDMatrix4() {
    DMatrix4 *resMat4 = (DMatrix4 *)SDL_SIMDAlloc(sizeof(DMatrix4));
    if (resMat4 != NULL)
        StoreDVEC4(resMat4, &zeroDVEC4, 4);
    return resMat4;
}

DMatrix4 *CreateDMatrix4Array(size_t count) {
    DMatrix4 *resArrayMat4 = (DMatrix4 *)SDL_SIMDAlloc(sizeof(DMatrix4));
    if (resArrayMat4 != NULL)
        StoreDVEC4(resArrayMat4, &zeroDVEC4, count*4);
    return (DMatrix4 *)SDL_SIMDAlloc(sizeof(DMatrix4)*count);
}

DMatrix4 *GetIdentityDMatrix4(DMatrix4 *mat4x4Dst) {
    CopyDVEC4(mat4x4Dst, &identityDMatrix4, 4);
    return mat4x4Dst;
}

DMatrix4 *GetLookAtDMatrix4Val(DMatrix4 *mat4x4, float eye_x, float eye_y, float eye_z, float center_x, float center_y, float center_z, float up_x, float up_y, float up_z) {
    DVEC4 *varray = (DVEC4 *)CreateDVEC4Array(3);
    if (varray == NULL)
        return mat4x4;
    DVEC4 *eye = &varray[0];
    DVEC4 *center = &varray[1];
    DVEC4 *up = &varray[2];
    eye->x = eye_x; eye->y = eye_y; eye->z = eye_z; eye->d = 0.0f;
    center->x = center_x; center->y = center_y; center->z = center_z; center->d = 0.0f;
    up->x = up_x; up->y = up_y; up->z = up_z; up->d = 0.0f;

    GetLookAtDMatrix4(mat4x4, eye, center, up);

    DestroyDVEC4(varray);
    return mat4x4;
}

DMatrix4 *GetLookAtDMatrix4(DMatrix4 *mat4x4, DVEC4 *eye, DVEC4 *center, DVEC4 *up) {
    DVEC4 *varray = (DVEC4*)CreateDVEC4Array(4);
    if (varray == NULL)
        return mat4x4;
    DMatrix4 *vTransMat = CreateDMatrix4();
    if (vTransMat == NULL) {
        DestroyDVEC4(varray);
        return mat4x4;
    }

    DVEC4 *negEye = &varray[0];
    DVEC4 *n = &varray[1];
    DVEC4 *u = &varray[2];
    DVEC4 *s = &varray[3];

    GetTranslateDMatrix4(vTransMat, MulValDVEC4Res(eye, -1.0f, negEye));

    *n = *eye;
    SubNormalizeDVEC4(n, center);

    CrossNormalizeDVEC4(up, n, s);

    CrossNormalizeDVEC4(n, s, u);

    mat4x4->raw[0] = s->x;  mat4x4->raw[4] = s->y;  mat4x4->raw[8]  = s->z;  mat4x4->raw[12] = 0.0f;
    mat4x4->raw[1] = u->x;  mat4x4->raw[5] = u->y;  mat4x4->raw[9]  = u->z;  mat4x4->raw[13] = 0.0f;
    mat4x4->raw[2] = n->x;  mat4x4->raw[6] = n->y;  mat4x4->raw[10] = n->z;  mat4x4->raw[14] = 0.0f;
    mat4x4->raw[3] = 0.0f;  mat4x4->raw[7] = 0.0f;  mat4x4->raw[11] = 0.0f;  mat4x4->raw[15] = 1.0f;

    DMatrix4MulDMatrix4(mat4x4, vTransMat);

    DestroyDVEC4(varray);
    DestroyDMatrix4(vTransMat);

    return mat4x4;
}

DMatrix4 *GetPerspectiveDMatrix4(DMatrix4 *mat4x4, float fov, float aspect, float znear, float zfar) {

    float y = SDL_tanf(fov * MDEG_TO_RAD_STEP / 2.0f);
    float x = y * aspect;
    float deltaFN = (zfar - znear);
    float zFNRat = -(zfar + znear) / deltaFN;
    float zFNVol = -(2.0f * zfar * znear) / deltaFN;


    mat4x4->raw[0] = 1.0f/x; mat4x4->raw[4] = 0.0f;   mat4x4->raw[8]  = 0.0f;   mat4x4->raw[12] = 0.0f;
    mat4x4->raw[1] = 0.0f;   mat4x4->raw[5] = 1.0f/y; mat4x4->raw[9]  = 0.0f;   mat4x4->raw[13] = 0.0f;
    mat4x4->raw[2] = 0.0f;   mat4x4->raw[6] = 0.0f;   mat4x4->raw[10] = zFNRat; mat4x4->raw[14] = zFNVol;
    mat4x4->raw[3] = 0.0f;   mat4x4->raw[7] = 0.0f;   mat4x4->raw[11] = -1.0f;  mat4x4->raw[15] = 0.0f;

    return mat4x4;
}

DMatrix4 *GetOrthoDMatrix4(DMatrix4 *mat4x4, float left, float right, float bottom, float top, float znear, float zfar) {
    float x = 2.0f / (right - left);
    float y = 2.0f / (top - bottom);
    float z = -2.0f / (zfar - znear);
    float tx = - ((right + left) / (right - left));
    float ty = - ((top + bottom) / (top - bottom));
    float tz = - ((zfar + znear) / (zfar - znear));

    mat4x4->raw[0] = x;      mat4x4->raw[4] = 0.0f;   mat4x4->raw[8]  = 0.0f;   mat4x4->raw[12] = -tx;
    mat4x4->raw[1] = 0.0f;   mat4x4->raw[5] = y;      mat4x4->raw[9]  = 0.0f;   mat4x4->raw[13] = -ty;
    mat4x4->raw[2] = 0.0f;   mat4x4->raw[6] = 0.0f;   mat4x4->raw[10] = z;      mat4x4->raw[14] = -tz;
    mat4x4->raw[3] = 0.0f;   mat4x4->raw[7] = 0.0f;   mat4x4->raw[11] = 0.0f;   mat4x4->raw[15] = 0.0f;

    return mat4x4;
}

DMatrix4 *GetViewDMatrix4(DMatrix4 *mat4x4, DgView *view, float startX, float endX, float startY, float endY)
{
    float propWidth = endX - startX;
    float propHeight = endY - startY;

    if (propWidth == 0.0f || propHeight == 0.0f)
        return mat4x4;

    int viewWidth = view->MaxX - view->MinX;
    int viewHeight = view->MaxY - view->MinY;

    DMatrix4 *vmatrix = CreateDMatrix4();

    DMatrix4MulDMatrix4(GetTranslateDMatrix4Val(mat4x4, (float)(view->MinX), (float)(view->MinY), 0.0f),
                       GetScaleDMatrix4Val(vmatrix, (float)(viewWidth), (float)(viewHeight), 1.0f));

    if (startX != 0.0f || startY != 0.0f) {
        DMatrix4MulDMatrix4(mat4x4, GetTranslateDMatrix4Val(vmatrix, -startX/propWidth, -startY/propHeight, 0.0f));
    }

    DMatrix4MulDMatrix4(mat4x4, GetScaleDMatrix4Val(vmatrix, 0.5f / propWidth, 0.5f / propHeight, 1.0f));

    DMatrix4MulDMatrix4(mat4x4, GetTranslateDMatrix4Val(vmatrix, 1.0f, 1.0f, 0.0f));

    DestroyDMatrix4(vmatrix);

    return mat4x4;
}


DMatrix4 *GetRotDMatrix4(DMatrix4 *FMG, float Rx, float Ry, float Rz) {
    float rx=MDEG_TO_RAD_STEP*Rx;
    float ry=MDEG_TO_RAD_STEP*Ry;
    float rz=MDEG_TO_RAD_STEP*Rz;
    float cx=SDL_cosf(rx),sx=SDL_sinf(rx),cy=SDL_cosf(ry),sy=SDL_sinf(ry),
         cz=SDL_cosf(rz),sz=SDL_sinf(rz),sx_sy=sx*sy,cx_sy=cx*sy;
    GetIdentityDMatrix4(FMG);
    FMG->rows[0].v[0]=cy*cz;
    FMG->rows[1].v[0]=cy*sz;
    FMG->rows[2].v[0]=-sy;
    FMG->rows[0].v[1]=(sx_sy*cz)-(cx*sz);
    FMG->rows[1].v[1]=(sx_sy*sz)+(cx*cz);
    FMG->rows[2].v[1]=sx*cy;
    FMG->rows[0].v[2]=(cx_sy*cz)+(sx*sz);
    FMG->rows[1].v[2]=(cx_sy*sz)-(sx*cz);
    FMG->rows[2].v[2]=cx*cy;
    return FMG;
}


DMatrix4 *GetXRotDMatrix4(DMatrix4 *FMX, float Rx) {
   float rx=MDEG_TO_RAD_STEP*Rx;
   float cosr = SDL_cosf(rx);
   float sinr = SDL_sinf(rx);
   GetIdentityDMatrix4(FMX);
   FMX->rows[1].v[1]=cosr; FMX->rows[1].v[2]=-sinr;
   FMX->rows[2].v[1]=sinr; FMX->rows[2].v[2]=cosr;
   return FMX;
}

DMatrix4 *GetYRotDMatrix4(DMatrix4 *FMY, float Ry) {
   float ry=MDEG_TO_RAD_STEP*Ry;
   float cosr = SDL_cosf(ry);
   float sinr = SDL_sinf(ry);
   GetIdentityDMatrix4(FMY);
   FMY->rows[0].v[0]=cosr; FMY->rows[0].v[2]=sinr;
   FMY->rows[2].v[0]=-sinr; FMY->rows[2].v[2]=cosr;
   return FMY;
}

DMatrix4 *GetZRotDMatrix4(DMatrix4 *FMZ, float Rz) {
   float rz=MDEG_TO_RAD_STEP*Rz;
   float cosr = SDL_cosf(rz);
   float sinr = SDL_sinf(rz);
   GetIdentityDMatrix4(FMZ);
   FMZ->rows[0].v[0]=cosr; FMZ->rows[0].v[1]=-sinr;
   FMZ->rows[1].v[0]=sinr; FMZ->rows[1].v[1]=cosr;
   return FMZ;
}

DMatrix4 *GetTranslateDMatrix4(DMatrix4 *mat4x4Trans, DVEC4 *vecTrans) {
   GetIdentityDMatrix4(mat4x4Trans);
   mat4x4Trans->rows[3] = *vecTrans;
   return mat4x4Trans;
}

DMatrix4 *GetScaleDMatrix4(DMatrix4 *mat4x4, DVEC4 *vecScale) {
   GetIdentityDMatrix4(mat4x4);
   mat4x4->rows[0].x = vecScale->x;
   mat4x4->rows[1].y = vecScale->y;
   mat4x4->rows[2].z = vecScale->z;
   return mat4x4;
}

DMatrix4 *GetTranslateDMatrix4Val(DMatrix4 *mat4x4Trans, float tx, float ty, float tz) {
   GetIdentityDMatrix4(mat4x4Trans);
   mat4x4Trans->rows[3].x = tx;
   mat4x4Trans->rows[3].y = ty;
   mat4x4Trans->rows[3].z = tz;
   return mat4x4Trans;
}

DMatrix4 *GetScaleDMatrix4Val(DMatrix4 *mat4x4Trans, float sx, float sy, float sz) {
   GetIdentityDMatrix4(mat4x4Trans);
   mat4x4Trans->rows[0].x = sx;
   mat4x4Trans->rows[1].y = sy;
   mat4x4Trans->rows[2].z = sz;
   return mat4x4Trans;
}

void DestroyDMatrix4(DMatrix4 *matrix4) {
    SDL_SIMDFree(matrix4);
}

bool IntersectRayPlane(DVEC4 *plane, DVEC4 *raypos, DVEC4 *raydir) {
    float ddir = 0.0f;
    float dpos = 0.0f;
    DotDVEC4(plane, raydir, &ddir);
    // plane normal and ray dir should in reverse direction or no interesection occur
    if (ddir <= 0.00005f ) {
        return false;
    }

    float t = -(*DotDVEC4(plane, raypos, &dpos)+plane->d) / ddir;

    if (t < 0.0f)
        return false;

    return true;
}

bool IntersectRayPlaneRes(DVEC4 *plane, DVEC4 *raypos, DVEC4 *raydir, DVEC4 *intrscPos) {
    float ddir = 0.0f;
    float dpos = 0.0f;
    DotDVEC4(plane, raydir, &ddir);

    if (ddir <= 0.00005f ) {
        return false;
    }

    float t = -(*DotDVEC4(plane, raypos, &dpos)+plane->d) / ddir;

    if (t < 0.0f)
        return false;

    RayProjectDVEC4Res(t, raypos, raydir, intrscPos);

    return true;
}
