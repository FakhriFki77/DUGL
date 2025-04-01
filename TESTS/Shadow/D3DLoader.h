/*  Dust Ultimate Game Library (DUGL) - (C) 2025 Fakhri Feki */
/*  Experimental 3d loader */
#ifndef D3DLOADER_H_INCLUDED
#define D3DLOADER_H_INCLUDED

class D3DLoader {
public:
	static void LoadOBJ(char *filename, DVEC4 *vertices_array, int &vertices_count, const int MAX_VERTICES_COUNT, int *indexes,
								int &faces_count, int **faces, const int MAX_INDEXES_SIZE, const int MAX_FACE_INDEXES, const int MAX_FACES_COUNT,
								DVEC4 *normals_array, int *normals_count, int **nfaces, DVEC2 *uvs_array, int *uv_count, int **uvfaces, DSTRDic **materialDIC);
	static void LoadOBJMTL(char *obj_filename, char *mtl_filename, DSTRDic **materialDIC);
};


#endif // D3DLOADER_H_INCLUDED
