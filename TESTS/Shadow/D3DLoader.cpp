/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */
/*  Experimental 3d OBJ loader */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <DUGL.h>
#include "D3DLoader.h"


void D3DLoader::LoadOBJ(char *filename, DVEC4 *vertices_array, int &vertices_count, const int MAX_VERTICES_COUNT, int *indexes,
								int &faces_count, int **faces, const int MAX_INDEXES_SIZE, const int MAX_FACE_INDEXES, const int MAX_FACES_COUNT,
								DVEC4 *normals_array, int *normals_count, int **nfaces, DVEC2 *uvs_array, int *uv_count, int **uvfaces, DSTRDic **materialDIC) {
	*materialDIC = NULL;
	DFileBuffer *File3DBuffer = CreateDFileBuffer(0);
	DSplitString *ListInfoLine = CreateDSplitString(0, 0);
	DSplitString *ListInfoIndex = CreateDSplitString(0, 0);
	if (File3DBuffer == NULL || ListInfoLine == NULL || ListInfoIndex == NULL)
		return;
	if (!OpenFileDFileBuffer(File3DBuffer, filename, "rt"))
	{
		DestroyDFileBuffer(File3DBuffer);
		DestroyDSplitString(ListInfoLine);
		DestroyDSplitString(ListInfoIndex);
		return;
	}
	int curPosIndexes = 0;
	int fIndexes[MAX_FACE_INDEXES];
	int fNIndexes[MAX_FACE_INDEXES];
	int fUVIndexes[MAX_FACE_INDEXES];
	int faceIndexesCount = 0;
	int nfaceIndexesCount = 0;
	int uvfaceIndexesCount = 0;
	int *facePtr = nullptr;
	bool faceIndexesOk = false;
	bool nfaceIndexesOk = false;
	bool uvfaceIndexesOk = false;
	bool extractNormalsAndNFaces = (normals_array != nullptr && normals_count != nullptr && nfaces != nullptr);
	faces_count = 0;
	vertices_count = 0;
	for(;;) {
		if (GetLineDFileBuffer(File3DBuffer, ListInfoLine->globStr, ListInfoLine->maxCountStrings) == 0 && IsEndOfFileDFileBuffer(File3DBuffer)) break;
		TrimGlobStringDSplitString(ListInfoLine);
		// ignore if empty or contain comments
		if (ListInfoLine->globStr[0] == '\0' || ListInfoLine->globStr[0] == '#')
			continue;

		if (splitDSplitString(ListInfoLine, NULL, ' ', false) > 0) {
			// new vertex
			if (strcmp(ListInfoLine->ListStrings[0], "v") == 0 && ListInfoLine->countStrings >= 4 && (vertices_count < MAX_VERTICES_COUNT)) {
				vertices_array[vertices_count].x = atof(ListInfoLine->ListStrings[1]);
				vertices_array[vertices_count].y = atof(ListInfoLine->ListStrings[2]);
				vertices_array[vertices_count].z = atof(ListInfoLine->ListStrings[3]);
				vertices_array[vertices_count].d = 0.0f;
				vertices_count++;
			} else if (extractNormalsAndNFaces && strcmp(ListInfoLine->ListStrings[0], "vt") == 0 && ListInfoLine->countStrings == 3 && (*uv_count < MAX_VERTICES_COUNT)) {
				uvs_array[*uv_count].x = atof(ListInfoLine->ListStrings[1]);
				uvs_array[*uv_count].y = atof(ListInfoLine->ListStrings[2]);
				(*uv_count)++;
			}else if (extractNormalsAndNFaces && strcmp(ListInfoLine->ListStrings[0], "vn") == 0 && ListInfoLine->countStrings == 4 && (*normals_count < MAX_VERTICES_COUNT)) {
				normals_array[*normals_count].x = atof(ListInfoLine->ListStrings[1]);
				normals_array[*normals_count].y = atof(ListInfoLine->ListStrings[2]);
				normals_array[*normals_count].z = atof(ListInfoLine->ListStrings[3]);
				normals_array[*normals_count].d = 0.0f;
				NormalizeDVEC4(&normals_array[*normals_count]);
				(*normals_count)++;
			} else if (strcmp(ListInfoLine->ListStrings[0], "f") == 0 && ListInfoLine->countStrings <= (unsigned int)(MAX_FACE_INDEXES+1) /*&& ListInfoLine.m_countStrings > 6*/) {
				faceIndexesOk = true;
				nfaceIndexesOk = true;
				uvfaceIndexesOk = true;
				faceIndexesCount = 0;
				nfaceIndexesCount = 0;
				uvfaceIndexesCount = 0;

				for (unsigned int iext = 0; iext < ListInfoLine->countStrings-1; iext++) {
					if (splitDSplitString(ListInfoIndex, ListInfoLine->ListStrings[iext+1], '/', true) > 0) {
						// face Indexes
						if (ListInfoIndex->countStrings >= 1) {
							fIndexes[iext] = atoi(ListInfoIndex->ListStrings[0]);
							if (fIndexes[iext] == 0 || (fIndexes[iext] > 0 && fIndexes[iext] > vertices_count) || (fIndexes[iext] < 0 && (-fIndexes[iext]>vertices_count))) {
								faceIndexesOk = false;
							} else if (fIndexes[iext] > 0) {
								faceIndexesCount++;
								fIndexes[iext]--; // convert to 0 -> n-1
							} else { // fIndexes[iext] < 0
								faceIndexesCount++;
								fIndexes[iext] = vertices_count + fIndexes[iext]; // convert to 0 -> n-1
							}
						}
						else
							faceIndexesOk = false;
						// uv face Indexes
						if (extractNormalsAndNFaces && uvfaceIndexesOk && ListInfoIndex->countStrings >= 2) {
							fUVIndexes[iext] = atoi(ListInfoIndex->ListStrings[1]);
							if (fUVIndexes[iext] == 0 || (fUVIndexes[iext] > 0 && fUVIndexes[iext] > *uv_count) || (fUVIndexes[iext] < 0 && -fUVIndexes[iext]>*uv_count)) {
								uvfaceIndexesOk = false;
							} else if (fUVIndexes[iext] > 0) {
								uvfaceIndexesCount++;
								fUVIndexes[iext]--; // convert to 0 -> n-1
							} else { // (fUVIndexes[iext] < 0)
								uvfaceIndexesCount++;
								fUVIndexes[iext] = *uv_count + fUVIndexes[iext];
							}
						}
						else
							nfaceIndexesOk = false;
						// normals face Indexes
						if (extractNormalsAndNFaces && nfaceIndexesOk && ListInfoIndex->countStrings >= 3) {
							fNIndexes[iext] = atoi(ListInfoIndex->ListStrings[2]);
							if (fNIndexes[iext] == 0 || (fNIndexes[iext] > 0 && fNIndexes[iext] > *normals_count) || (fNIndexes[iext] < 0 && -fNIndexes[iext]>*normals_count)) {
								nfaceIndexesOk = false;
							} else if (fNIndexes[iext] > 0) {
								nfaceIndexesCount++;
								fNIndexes[iext]--; // convert to 0 -> n-1
							} else { // (fNIndexes[iext] < 0)
								nfaceIndexesCount++;
								fNIndexes[iext] = *normals_count + fNIndexes[iext];
							}
						}
						else
							nfaceIndexesOk = false;

					}	else
							faceIndexesOk = false;
					if (!faceIndexesOk) {
						printf("invalide face %i, vertices %i, bad index %i\n", faces_count, vertices_count, fIndexes[iext]);
						break;
					}
				}
				if (faceIndexesOk && (curPosIndexes+(faceIndexesCount+1)) < MAX_INDEXES_SIZE && faces_count < MAX_FACES_COUNT) {
					facePtr = &indexes[curPosIndexes];
					facePtr[0] = faceIndexesCount;
					memcpy(&facePtr[1], fIndexes, sizeof(int)*faceIndexesCount);
					faces[faces_count] = facePtr;
					curPosIndexes += faceIndexesCount +1;
					// extract texture uv if available
					if (extractNormalsAndNFaces && uvfaceIndexesOk && uvfaceIndexesCount == faceIndexesCount &&
							(curPosIndexes+(uvfaceIndexesCount+1)) < MAX_INDEXES_SIZE) {
						facePtr = &indexes[curPosIndexes];
						facePtr[0] = nfaceIndexesCount;
						memcpy(&facePtr[1], fUVIndexes, sizeof(int)*uvfaceIndexesCount);
						uvfaces[faces_count] = facePtr;
						curPosIndexes += faceIndexesCount +1;
					} else if (nfaces != nullptr) {
						uvfaces[faces_count] = nullptr;
					}
					// extract normals face if available and asked
					if (extractNormalsAndNFaces && nfaceIndexesOk && nfaceIndexesCount == faceIndexesCount &&
							(curPosIndexes+(nfaceIndexesCount+1)) < MAX_INDEXES_SIZE) {
						facePtr = &indexes[curPosIndexes];
						facePtr[0] = nfaceIndexesCount;
						memcpy(&facePtr[1], fNIndexes, sizeof(int)*nfaceIndexesCount);
						nfaces[faces_count] = facePtr;
						curPosIndexes += faceIndexesCount +1;
					} else if (nfaces != nullptr) {
						nfaces[faces_count] = nullptr;
					}
					faces_count++;
				}
			} else if (strcmp(ListInfoLine->ListStrings[0], "mtllib") == 0 && ListInfoLine->countStrings == 2) {
				LoadOBJMTL(filename, ListInfoLine->ListStrings[1], materialDIC);
			}
		}
		if (faces_count == MAX_FACES_COUNT) break;
	}

	CloseFileDFileBuffer(File3DBuffer);
	DestroyDFileBuffer(File3DBuffer);
	DestroyDSplitString(ListInfoLine);
	DestroyDSplitString(ListInfoIndex);
}

void D3DLoader::LoadOBJMTL(char *obj_filename, char *mtl_filename, DSTRDic **materialDIC) {
	*materialDIC = CreateDSTRDic(0, 12);
	if (*materialDIC != NULL) {
		DFileBuffer *File3DBuffer = CreateDFileBuffer(0);
		if (!OpenFileDFileBuffer(File3DBuffer, mtl_filename, "rt")) {
			DestroyDSTRDic(*materialDIC);
			DestroyDFileBuffer(File3DBuffer);
			*materialDIC = NULL;
			return;
		}
		DSplitString *ListInfoLine = CreateDSplitString(0, 0);

		for(;;) {
			if (GetLineDFileBuffer(File3DBuffer, ListInfoLine->globStr, ListInfoLine->maxGlobLength) == 0 && IsEndOfFileDFileBuffer(File3DBuffer)) break;
			TrimGlobStringDSplitString(ListInfoLine);
			// ignore if empty or contain comments
			if (ListInfoLine->globStr[0] == '\0' || ListInfoLine->globStr[0] == '#')
				continue;
			if (splitDSplitString(ListInfoLine, NULL, ' ', false) > 0) {
			}
		}

		DestroyDSplitString(ListInfoLine);
		CloseFileDFileBuffer(File3DBuffer);
	}
}
