#include <stdio.h>
#include <stdlib.h>
#include "DUGL.h"
#include "DCamera3D.h"


DCamera3D::DCamera3D() {
	allocMembers();
	m_eyePosition->x = 0.0f; m_eyePosition->y = 10.0f; m_eyePosition->z = -100.0f;
	m_target->x = 0.0f; m_target->y = 10.0f; m_target->z = 0.0f;
	m_up->x = 0.0f; m_up->y = 1.0f; m_up->z = 0.0f;
	CopyDVEC4(m_eyeToTarget, m_eyePosition, 1);
	SubDVEC4(m_eyeToTarget, m_target);
	m_fov = 60.0f; m_aspect = 1.33f; m_znear = 1.0f; m_zfar = 1000.0f; // frustum
	m_vminx = -1.0f; m_vminy = -1.0f; m_vmaxx = 1.0f; m_vmaxy = 1.0f; // frustum View
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
	GetPerspectiveDMatrix4(m_matProject, m_fov, m_aspect, m_znear, m_zfar);
}

DCamera3D::~DCamera3D() {
	if (m_eyePosition != nullptr) DestroyDVEC4(m_eyePosition);
	if (m_matTransform != nullptr) DestroyDMatrix4(m_matTransform);
	m_eyePosition = nullptr;
	m_target = nullptr;
	m_up = nullptr;
	m_eyeToTarget = nullptr;
	m_move = nullptr;
	m_pan = nullptr;
	m_matTransform = nullptr;
	m_matProject = nullptr;
	m_matCamRot = nullptr;
}

void DCamera3D::allocMembers() {
	m_eyePosition = (DVEC4*)CreateDVEC4Array(6);
	m_target = &m_eyePosition[1];
	m_up = &m_eyePosition[2];
	m_eyeToTarget = &m_eyePosition[3];
	m_move = &m_eyePosition[4];
	m_pan = &m_eyePosition[5];

	m_matTransform = CreateDMatrix4Array(3);
	m_matProject = &m_matTransform[1];
	m_matCamRot =  &m_matTransform[2];
}

void DCamera3D::SetFrustum(float fov, float aspect, float znear, float zfar) {
	m_fov = fov; m_aspect = aspect; m_znear = znear; m_zfar = zfar;
	GetPerspectiveDMatrix4(m_matProject, m_fov, m_aspect, m_znear, m_zfar);
}

void DCamera3D::GetFrustum(float &fov, float &aspect, float &znear, float &zfar) {
	fov = m_fov; aspect = m_aspect; znear = m_znear; zfar = m_zfar;
}

void DCamera3D::SetPosition(float x, float y, float z) {
	m_eyePosition->x = x; m_eyePosition->y = y; m_eyePosition->z = z;
	CopyDVEC4(m_target, m_eyePosition, 1);
	AddDVEC4(m_target, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::SetPosition(DVEC4 *vpos) {
	CopyDVEC4(m_eyePosition, vpos, 1);
	CopyDVEC4(m_target, vpos, 1);
	AddDVEC4(m_target, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::SetTarget(float x, float y, float z) {
	m_target->x = x; m_target->y = y; m_target->z = z;
	CopyDVEC4(m_eyePosition, m_target, 1);
	SubDVEC4(m_eyePosition, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::SetTarget(DVEC4 *vposTarget) {
	CopyDVEC4(m_eyePosition, vposTarget, 1);
	CopyDVEC4(m_eyePosition, vposTarget, 1);
	SubDVEC4(m_eyePosition, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::Rotate(float xRot, float yRot, float zRot) {
	GetRotDMatrix4(m_matCamRot, xRot, yRot, zRot);
	DMatrix4MulDVEC4Array(m_matCamRot, m_eyeToTarget, 1);
	CopyDVEC4(m_target, m_eyePosition, 1);
	AddDVEC4(m_target, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::RotateAroundTarget(float xRot, float yRot, float zRot) {
	GetRotDMatrix4(m_matCamRot, -xRot, -yRot, -zRot);
	DMatrix4MulDVEC4Array(m_matCamRot, m_eyeToTarget, 1);
	CopyDVEC4(m_eyePosition, m_target, 1);
	SubDVEC4(m_eyePosition, m_eyeToTarget);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::MoveForwardBackward(float dist) {
	CopyDVEC4(m_move, m_eyeToTarget, 1);
	NormalizeDVEC4(m_move);
	MulValDVEC4(m_move, dist);
	AddDVEC4(m_eyePosition, m_move);
	AddDVEC4(m_target, m_move);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}

void DCamera3D::MoveUpDown(float dist) {
	CopyDVEC4(m_pan, m_up, 1);
	NormalizeDVEC4(m_pan);
	MulValDVEC4(m_pan, dist);
	AddDVEC4(m_eyePosition, m_pan);
	AddDVEC4(m_target, m_pan);
	GetLookAtDMatrix4(m_matTransform, m_eyePosition, m_target, m_up);
}
