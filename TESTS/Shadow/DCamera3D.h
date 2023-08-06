/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */

#ifndef DCAMERA3D_H_INCLUDED
#define DCAMERA3D_H_INCLUDED

class DCamera3D {
private:
	DVEC4 *m_eyePosition;
	DVEC4 *m_target;
	DVEC4 *m_up;
	DVEC4 *m_eyeToTarget;
	DVEC4 *m_move;
	DVEC4 *m_pan;
	DMatrix4 *m_matTransform;
	DMatrix4 *m_matProject;
	DMatrix4 *m_matCamRot;
	float m_fov, m_aspect, m_znear, m_zfar; // frustum
	float m_vminx, m_vminy, m_vmaxx, m_vmaxy; // frustum View
	void allocMembers();
public:
	DCamera3D();
	~DCamera3D();
	DMatrix4 *GetTransform() { return m_matTransform; };
	DMatrix4 *GetProject() { return m_matProject; };
	DVEC4 *GetPosition() { return m_eyePosition; };
	void SetFrustum(float fov, float aspect, float znear, float zfar);
	void GetFrustum(float &fov, float &aspect, float &znear, float &zfar);
	void SetPosition(float x, float y, float z);
	void SetPosition(DVEC4 *vpos);
	void SetTarget(float x, float y, float z);
	void SetTarget(DVEC4 *vposTarget);

	void Rotate(float xRot, float yRot, float zRot);
	void RotateAroundTarget(float xRot, float yRot, float zRot);
	void MoveForwardBackward(float dist);
	void MoveUpDown(float dist);
};


#endif // DCAMERA3D_H_INCLUDED
