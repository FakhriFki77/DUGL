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

#ifndef DMATH3D_H_INCLUDED
#define DMATH3D_H_INCLUDED

#ifdef __cplusplus
extern "C" {
#endif

// 3D Math support =====================================================================

typedef union {
    struct { float x, y, z, d; };
    float v[4];
} DVEC4;

typedef union {
    struct { int x, y, z, d; };
    int v[4];
} DVEC4i;

typedef union {
    struct { float x, y; };
    float v[2];
} DVEC2;

typedef union {
    struct { int x, y; };
    int v[2];
} DVEC2i;

typedef union {
    struct { DVEC4 min; DVEC4 max; };
    DVEC4 v[2];
} DAAMinBBox;

typedef union {
    struct {
        DVEC4 front_bottom_left;    DVEC4 front_bottom_right;
        DVEC4 front_top_right;      DVEC4 front_top_left;
        DVEC4 back_bottom_left;     DVEC4 back_bottom_right;
        DVEC4 back_top_right;       DVEC4 back_top_left;
    };
    DVEC4 v[8];
} DAABBox;

typedef union {
    struct { DVEC4 rows[4]; };
    float rc[4][4];
    float raw[16];
} DMatrix4;

// create/Init/Destroy
void *CreateDVEC4();
void *CreateDVEC4Array(int count);
DVEC4 *CreateInitDVEC4(float x, float y, float z, float d);
DVEC4 *CreateInitDVEC4Array(DVEC4 *vec4init, int count);
DVEC4i *CreateInitDVEC4i(int x, int y, int z, int d);
DVEC4i *CreateInitDVEC4iArray(DVEC4i *vec4init, int count);
void DestroyDVEC4(void *vec4);
void *CreateDVEC2();
void *CreateDVEC2Array(int count);
void DestroyDVEC2(void *vec2);

// Math op : Mul/Add/Sub/Cross/Distance/Dot ..
void DistanceDVEC4(DVEC4 *v1, DVEC4 *v2, float *distanceRes);
void DistancePow2DVEC4(DVEC4 *v1, DVEC4 *v2, float *distancePow2Res);
void DotDVEC4(DVEC4 *v1, DVEC4 *v2, float *dotRes);
void LengthDVEC4(DVEC4 *vec4, float *lengthRes);
void NormalizeDVEC4(DVEC4 *vec4);
void CrossDVEC4(DVEC4 *v1, DVEC4 *v2, DVEC4 *vcrossRes);
void LerpDVEC4Res(float alpha, DVEC4 *v1, DVEC4 *v2, DVEC4 *vlerpRes); // vRes = v1 + ((v2 - v1) * alpha)
void LerpDVEC4DVEC2Res(float alpha, DVEC4 *v41, DVEC4 *v42, DVEC2 *v21, DVEC2 *v22, DVEC4 *v4lerpRes, DVEC2 *v2lerpRes); // vRes = v1 + ((v2 - v1) * alpha)
void MulValDVEC4(DVEC4 *vec4, float val);
void MulValDVEC4Res(DVEC4 *v, float val, DVEC4 *vres);
void MulValDVEC4Array(DVEC4 *vec4array, int count, float val);
void MulDVEC4Array(DVEC4 *vec4array, int count, DVEC4 *vmul);
void MulDVEC4(DVEC4 *v1, DVEC4 *v2);
void MulDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresMul);
void AddDVEC4(DVEC4 *v1, DVEC4 *v2);
void AddDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresAdd);
void AddDVEC4Array(DVEC4 *vec4array, int count, DVEC4 *vplus);
void SubDVEC4(DVEC4 *v1, DVEC4 *v2);
void SubDVEC4Res(DVEC4 *v1, DVEC4 *v2, DVEC4 *vresSub);
void MulVEC2ArrayVEC2ValDVec2iArrayRes(DVEC2 *vec2array, int count, DVEC2 *MulVal, DVEC2i *vec2iArrayRes);
void MulVEC2ArrayVEC2ValDVec2iArrayResNT(DVEC2 *vec2array, int count, DVEC2 *MulVal, DVEC2i *vec2iArrayRes);
// Conversion/Copy/Clip /////////////////////////////////////////
void DVEC42DVec4i(DVEC4i *vec4iDst, DVEC4 *vec4Src);
void DVec4i2DVEC4(DVEC4 *vec4Dst, DVEC4i *vec4iSrc);
void DVEC22DVec2i(DVEC2i *vec2iDst, DVEC2 *vec2Src);
void DVec2i2DVEC2(DVEC2 *vec2Dst, DVEC2i *vec2iSrc);
void DVEC4Array2DVec4i(DVEC4i *vec4iArrayDst, DVEC4 *vec4ArraySrc, int count);
void DVEC4Array2DVec4iNT(DVEC4i *vec4iArrayDst, DVEC4 *vec4ArraySrc, int count);
void DVEC4iArray2DVec4(DVEC4 *vec4ArrayDst, DVEC4i *vec4ArraySrc, int count);
void DVEC4iArray2DVec4NT(DVEC4 *vec4ArrayDst, DVEC4i *vec4ArraySrc, int count);
void ClipDVEC4Array(DVEC4 *vec4Array, int count, DVEC4 *vec4_min, DVEC4 *vec4_max);
void CopyDVEC4(void *vec4ArrayDst, void *vec4ArraySrc, int count);
void CopyDVEC4NT(void *vec4ArrayDst, void *vec4ArraySrc, int count);
void StoreDVEC4(void *vec4ArrayDst, void *vec4ElemSrc, int count);
void StoreDVEC4NT(void *vec4ArrayDst, void *vec4ElemSrc, int count);

// search/AABBox/Filtering/compare ///////////////////////////////////////
bool EqualDVEC4(DVEC4 *v1, DVEC4 *v2);
void FetchDAAMinBBoxDVEC4Array(DVEC4 *vec4Array, int count, DAAMinBBox *aaMinBboxRes);
void FetchDAABBoxDVEC4Array(DVEC4 *vec4Array, int count, DAABBox *aaBboxRes);
/* return min of the x, y, z, d components merged in res DVEC4 */
void DVEC4MinRes(DVEC4 *v1, DVEC4 *v2, DVEC4 *vec4_minRes);
/* return max of the x, y, z, d components merged in res DVEC4 */
void DVEC4MaxRes(DVEC4 *v1, DVEC4 *v2, DVEC4 *vec4_maxRes);
/* return min value of x, y, z components in minXYZRes */
void DVEC4MinXYZ(DVEC4 *v, float *minXYZRes);
/* return max value of x, y, z components in maxXYZRes */
void DVEC4MaxXYZ(DVEC4 *v, float *maxXYZRes);

// culling / collision / clipping //////////////////////////////////////
bool DVEC4InAAMinBBox(DVEC4 *vec4Pos, DAAMinBBox *aaMinBbox);
#define DVEC4_IN_MASK_X 0x0001
#define DVEC4_IN_MASK_Y 0x0010
#define DVEC4_IN_MASK_Z 0x0100
#define DVEC4_IN_MASK_D 0x1000
bool DVEC4MaskInAAMinBBox(DVEC4 *vec4Pos, DAAMinBBox *aaMinBbox, int Mask); // 0x1111 => (d,z,y,x) ex: 0x110 => test in for (z,y)

int DVEC4ArrayIdxCountInAAMinBBox(DVEC4 *vec4Array, int *idxsVec4, int countIdxs, DAAMinBBox *aaMinBbox);
int DVEC4ArrayIdxCountInMapAAMinBBox(DVEC4 *vec4Array, int *idxsVec4, int countIdxs, DAAMinBBox *aaMinBbox, char *InMap);
// DMatrix4 4x4 3x3 ///////////////////////////////////////////////

DMatrix4 *CreateDMatrix4();
DMatrix4 *CreateDMatrix4Array(size_t count);
void DestroyDMatrix4(DMatrix4 *matrix4);

void GetIdentityDMatrix4(DMatrix4 *mat4x4Dst);
void GetLookAtDMatrix4(DMatrix4 *mat4x4Dst, DVEC4 *eye, DVEC4 *center, DVEC4 *up);
void GetLookAtDMatrix4Val(DMatrix4 *mat4x4, float eye_x, float eye_y, float eye_z, float center_x, float center_y, float center_z, float up_x, float up_y, float up_z);
void GetPerspectiveDMatrix4(DMatrix4 *mat4x4, float fov, float aspect, float znear, float zfar);
void GetOrthoDMatrix4(DMatrix4 *mat4x4, float left, float right, float bottom, float top, float znear, float zfar);
void GetViewDMatrix4(DMatrix4 *mat4x4, DgView *view, float startX, float endX, float startY, float endY);
void GetRotDMatrix4(DMatrix4 *FMG, float Rx, float Ry, float Rz);
void GetXRotDMatrix4(DMatrix4 *FMX, float Rx);
void GetYRotDMatrix4(DMatrix4 *FMY, float Ry);
void GetZRotDMatrix4(DMatrix4 *FMZ, float Rz);
void GetTranslateDMatrix4(DMatrix4 *mat4x4Trans, DVEC4 *vecTrans);
void GetTranslateDMatrix4Val(DMatrix4 *mat4x4Trans, float tx, float ty, float tz);
void GetScaleDMatrix4(DMatrix4 *mat4x4Trans, DVEC4 *vecScale);
void GetScaleDMatrix4Val(DMatrix4 *mat4x4Trans, float sx, float sy, float sz);

void DMatrix4MulDMatrix4(DMatrix4 *mat4x4_left, DMatrix4 *mat4x4_right);
void DMatrix4MulDMatrix4Res(DMatrix4 *mat4x4_left, DMatrix4 *mat4x4_right, DMatrix4 *mat4x4_res);

void DMatrix4MulDVEC4Array(DMatrix4 *mat4x4, DVEC4 *vec4Array, int count);
void DMatrix4MulDVEC4ArrayRes(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayPersp(DMatrix4 *mat4x4, DVEC4 *vec4Array, int count);
void DMatrix4MulDVEC4ArrayPerspRes(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayPerspResNT(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayResNT(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4 *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayResDVec4i(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4i *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayResDVec4iNT(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC4i *vec4ArrayDst);
void DMatrix4MulDVEC4ArrayResDVec2i(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC2i *vec2iArrayDst);
void DMatrix4MulDVEC4ArrayResDVec2iNT(DMatrix4 *mat4x4, DVEC4 *vec4ArraySrc, int count, DVEC2i *vec2iArrayDst);


#ifdef __cplusplus
        }  // extern "C" {
#endif

#endif // DMATH3D_H_INCLUDED

