/*	Dust Ultimate Game Library (DUGL)
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
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>

#include "DUGL.h"
#include "intrndugl.h"

bool GetDGCORE(DGCORE *dgCore, int idxDgCore) {
    if (dgCore == NULL)
        return false;
    SDL_memset(dgCore, 0, sizeof(DGCORE));
    if (idxDgCore >= DGCORES_COUNT)
        return false;

    switch(idxDgCore) {
    case 0:
        dgCore->CurSurf = &CurSurf;
        dgCore->SrcSurf = &SrcSurf;
        dgCore->LastPolyStatus = &LastPolyStatus;

        dgCore->DgSetCurSurf = DgSetCurSurf;
        dgCore->DgGetCurSurf = DgGetCurSurf;
        dgCore->DgSetSrcSurf = DgSetSrcSurf;

        dgCore->DgClear16 = DgClear16;
        dgCore->ClearSurf16 = ClearSurf16;
        dgCore->DgPutPixel16 = DgPutPixel16;
        dgCore->DgCPutPixel16 = DgCPutPixel16;
        dgCore->DgGetPixel16 = DgGetPixel16;
        dgCore->DgCGetPixel16 = DgCGetPixel16;
        dgCore->line16 = line16;
        dgCore->linemap16 = linemap16;
        dgCore->lineblnd16 = lineblnd16;
        dgCore->linemapblnd16 = linemapblnd16;
        dgCore->Line16 = Line16;
        dgCore->LineMap16 = LineMap16;
        dgCore->LineBlnd16 = LineBlnd16;
        dgCore->LineMapBlnd16 = LineMapBlnd16;
        dgCore->InBar16 = InBar16;
        dgCore->SurfMaskCopyBlnd16 = SurfMaskCopyBlnd16;
        dgCore->SurfMaskCopyTrans16 = SurfMaskCopyTrans16;
        dgCore->ResizeViewSurf16 = ResizeViewSurf16;
        dgCore->MaskResizeViewSurf16 = MaskResizeViewSurf16;
        dgCore->TransResizeViewSurf16 = TransResizeViewSurf16;
        dgCore->MaskTransResizeViewSurf16 = MaskTransResizeViewSurf16;
        dgCore->BlndResizeViewSurf16 = BlndResizeViewSurf16;
        dgCore->MaskBlndResizeViewSurf16 = MaskBlndResizeViewSurf16;
        dgCore->PutSurf16 = PutSurf16;
        dgCore->PutMaskSurf16 = PutMaskSurf16;
        dgCore->PutSurfBlnd16 = PutSurfBlnd16;
        dgCore->PutMaskSurfBlnd16 = PutMaskSurfBlnd16;
        dgCore->PutSurfTrans16 = PutSurfTrans16;
        dgCore->PutMaskSurfTrans16 = PutMaskSurfTrans16;
        dgCore->Poly16 = Poly16;
        dgCore->RePoly16 = RePoly16;

        break;

    case 1:
        dgCore->CurSurf = &CurSurf_C2;
        dgCore->SrcSurf = &SrcSurf_C2;
        dgCore->LastPolyStatus = &LastPolyStatus_C2;

        dgCore->DgSetCurSurf = DgSetCurSurf_C2;
        dgCore->DgGetCurSurf = DgGetCurSurf_C2;
        dgCore->DgSetSrcSurf = DgSetSrcSurf_C2;

        dgCore->DgClear16 = DgClear16_C2;
        dgCore->ClearSurf16 = ClearSurf16_C2;
        dgCore->DgPutPixel16 = DgPutPixel16_C2;
        dgCore->DgCPutPixel16 = DgCPutPixel16_C2;
        dgCore->DgGetPixel16 = DgGetPixel16_C2;
        dgCore->DgCGetPixel16 = DgCGetPixel16_C2;
        dgCore->line16 = line16_C2;
        dgCore->linemap16 = linemap16_C2;
        dgCore->lineblnd16 = lineblnd16_C2;
        dgCore->linemapblnd16 = linemapblnd16_C2;
        dgCore->Line16 = Line16_C2;
        dgCore->LineMap16 = LineMap16_C2;
        dgCore->LineBlnd16 = LineBlnd16_C2;
        dgCore->LineMapBlnd16 = LineMapBlnd16_C2;
        dgCore->InBar16 = InBar16_C2;
        dgCore->Bar16 = Bar16_C2;
        dgCore->InBarBlnd16 = InBarBlnd16_C2;
        dgCore->BarBlnd16 = BarBlnd16_C2;
        dgCore->SurfMaskCopyBlnd16 = SurfMaskCopyBlnd16_C2;
        dgCore->SurfMaskCopyTrans16 = SurfMaskCopyTrans16_C2;
        dgCore->ResizeViewSurf16 = ResizeViewSurf16_C2;
        dgCore->MaskResizeViewSurf16 = MaskResizeViewSurf16_C2;
        dgCore->TransResizeViewSurf16 = TransResizeViewSurf16_C2;
        dgCore->MaskTransResizeViewSurf16 = MaskTransResizeViewSurf16_C2;
        dgCore->BlndResizeViewSurf16 = BlndResizeViewSurf16_C2;
        dgCore->MaskBlndResizeViewSurf16 = MaskBlndResizeViewSurf16_C2;
        dgCore->PutSurf16 = PutSurf16_C2;
        dgCore->PutMaskSurf16 = PutMaskSurf16_C2;
        dgCore->PutSurfBlnd16 = PutSurfBlnd16_C2;
        dgCore->PutMaskSurfBlnd16 = PutMaskSurfBlnd16_C2;
        dgCore->PutSurfTrans16 = PutSurfTrans16_C2;
        dgCore->PutMaskSurfTrans16 = PutMaskSurfTrans16_C2;
        dgCore->Poly16 = Poly16_C2;
        dgCore->RePoly16 = RePoly16_C2;

        break;

    case 2:
        dgCore->CurSurf = &CurSurf_C3;
        dgCore->SrcSurf = &SrcSurf_C3;
        dgCore->LastPolyStatus = &LastPolyStatus_C3;

        dgCore->DgSetCurSurf = DgSetCurSurf_C3;
        dgCore->DgGetCurSurf = DgGetCurSurf_C3;
        dgCore->DgSetSrcSurf = DgSetSrcSurf_C3;

        dgCore->DgClear16 = DgClear16_C3;
        dgCore->ClearSurf16 = ClearSurf16_C3;
        dgCore->DgPutPixel16 = DgPutPixel16_C3;
        dgCore->DgCPutPixel16 = DgCPutPixel16_C3;
        dgCore->DgGetPixel16 = DgGetPixel16_C3;
        dgCore->DgCGetPixel16 = DgCGetPixel16_C3;
        dgCore->line16 = line16_C3;
        dgCore->linemap16 = linemap16_C3;
        dgCore->lineblnd16 = lineblnd16_C3;
        dgCore->linemapblnd16 = linemapblnd16_C3;
        dgCore->Line16 = Line16_C3;
        dgCore->LineMap16 = LineMap16_C3;
        dgCore->LineBlnd16 = LineBlnd16_C3;
        dgCore->LineMapBlnd16 = LineMapBlnd16_C3;
        dgCore->InBar16 = InBar16_C3;
        dgCore->Bar16 = Bar16_C3;
        dgCore->InBarBlnd16 = InBarBlnd16_C3;
        dgCore->BarBlnd16 = BarBlnd16_C3;
        dgCore->SurfMaskCopyBlnd16 = SurfMaskCopyBlnd16_C3;
        dgCore->SurfMaskCopyTrans16 = SurfMaskCopyTrans16_C3;
        dgCore->ResizeViewSurf16 = ResizeViewSurf16_C3;
        dgCore->MaskResizeViewSurf16 = MaskResizeViewSurf16_C3;
        dgCore->TransResizeViewSurf16 = TransResizeViewSurf16_C3;
        dgCore->MaskTransResizeViewSurf16 = MaskTransResizeViewSurf16_C3;
        dgCore->BlndResizeViewSurf16 = BlndResizeViewSurf16_C3;
        dgCore->MaskBlndResizeViewSurf16 = MaskBlndResizeViewSurf16_C3;
        dgCore->PutSurf16 = PutSurf16_C3;
        dgCore->PutMaskSurf16 = PutMaskSurf16_C3;
        dgCore->PutSurfBlnd16 = PutSurfBlnd16_C3;
        dgCore->PutMaskSurfBlnd16 = PutMaskSurfBlnd16_C3;
        dgCore->PutSurfTrans16 = PutSurfTrans16_C3;
        dgCore->PutMaskSurfTrans16 = PutMaskSurfTrans16_C3;
        dgCore->Poly16 = Poly16_C3;
        dgCore->RePoly16 = RePoly16_C3;

        break;

    case 3:
        dgCore->CurSurf = &CurSurf_C4;
        dgCore->SrcSurf = &SrcSurf_C4;
        dgCore->LastPolyStatus = &LastPolyStatus_C4;

        dgCore->DgSetCurSurf = DgSetCurSurf_C4;
        dgCore->DgGetCurSurf = DgGetCurSurf_C4;
        dgCore->DgSetSrcSurf = DgSetSrcSurf_C4;

        dgCore->DgClear16 = DgClear16_C4;
        dgCore->ClearSurf16 = ClearSurf16_C4;
        dgCore->DgPutPixel16 = DgPutPixel16_C4;
        dgCore->DgCPutPixel16 = DgCPutPixel16_C4;
        dgCore->DgGetPixel16 = DgGetPixel16_C4;
        dgCore->DgCGetPixel16 = DgCGetPixel16_C4;
        dgCore->line16 = line16_C4;
        dgCore->linemap16 = linemap16_C4;
        dgCore->lineblnd16 = lineblnd16_C4;
        dgCore->linemapblnd16 = linemapblnd16_C4;
        dgCore->Line16 = Line16_C4;
        dgCore->LineMap16 = LineMap16_C4;
        dgCore->LineBlnd16 = LineBlnd16_C4;
        dgCore->LineMapBlnd16 = LineMapBlnd16_C4;
        dgCore->InBar16 = InBar16_C4;
        dgCore->Bar16 = Bar16_C4;
        dgCore->InBarBlnd16 = InBarBlnd16_C4;
        dgCore->BarBlnd16 = BarBlnd16_C4;
        dgCore->SurfMaskCopyBlnd16 = SurfMaskCopyBlnd16_C4;
        dgCore->SurfMaskCopyTrans16 = SurfMaskCopyTrans16_C4;
        dgCore->ResizeViewSurf16 = ResizeViewSurf16_C4;
        dgCore->MaskResizeViewSurf16 = MaskResizeViewSurf16_C4;
        dgCore->TransResizeViewSurf16 = TransResizeViewSurf16_C4;
        dgCore->MaskTransResizeViewSurf16 = MaskTransResizeViewSurf16_C4;
        dgCore->BlndResizeViewSurf16 = BlndResizeViewSurf16_C4;
        dgCore->MaskBlndResizeViewSurf16 = MaskBlndResizeViewSurf16_C4;
        dgCore->PutSurf16 = PutSurf16_C4;
        dgCore->PutMaskSurf16 = PutMaskSurf16_C4;
        dgCore->PutSurfBlnd16 = PutSurfBlnd16_C4;
        dgCore->PutMaskSurfBlnd16 = PutMaskSurfBlnd16_C4;
        dgCore->PutSurfTrans16 = PutSurfTrans16_C4;
        dgCore->PutMaskSurfTrans16 = PutMaskSurfTrans16_C4;
        dgCore->Poly16 = Poly16_C4;
        dgCore->RePoly16 = RePoly16_C4;

        break;
    }

    return true;
}
