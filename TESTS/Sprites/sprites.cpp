/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */
/*  Sprites Sample */
/*  old History : DUGL DOS/DJGPP */
/*  3 september 2006 : first release */
/*  March 2007 : better fps calculation */
/*  History: */
/*  11 February 2023: First port */
/*  12 February 2023: Few optimizations - First demonstration of DUGL Multi Cores rendering by splitting screen */
/*     into left and right view and setting a DWorker to render each view, boosting fps by ~50% */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <DUGL.h>

typedef struct {
    int     x,  // pos x
            y,  // pos y
            xspeed; // delta x
    DgSurf *sprite;
} mySprite;

#define MAX_SPRITES  10000
int NbSprites = 0;
mySprite Sprites[MAX_SPRITES];

FONT F1;
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors

int ScrResH = 800, ScrResV = 600;

// render DWorker's
// required for dual core rendering
unsigned int renderLeftViewWorkerID = 0;
unsigned int renderRighViewtWorkerID = 0;
void RenderLeftViewFunc(void *, int );
void RenderRightViewFunc(void *, int );

// app controle
bool ExitApp = false;
bool dualCoreRender = true;
bool PauseMove = false;
// used view *******
DgView SpritesView = { 0,0,ScrResH-1,ScrResV-1,0,50 },
       SpritesLeftView = { 0, 0, ScrResH/2-1, ScrResV-1, 0,50 },
       SpritesRightView = { 0, 0, ScrResH-1,  ScrResV-1, ScrResH/2,50 },
       TextView = { 0,0,ScrResH-1,49,0,0 },
       AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

// *** memory suface of the Sprites ****************************
DgSurf *sprites[3];
// *** memory surf rendering
int toggleMemRender = 1;
// synch buffer - to compute fps
char SynchBuff[SIZE_SYNCH_BUFF];

int main(int argc,char *argv[]) {
    // init the lib
    if (!DgInit()) {
        printf("DUGL init error\n");
        exit(-1);
    }
    // load GFX the 3 Sprites
    if (!LoadGIF16(&sprites[0],"../Asset/PICS/man1.GIF")) {
        printf("man1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&sprites[1],"../Asset/PICS/cat1.GIF")) {
        printf("cat1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&sprites[2],"../Asset/PICS/balcat1.GIF")) {
        printf("balcat1.gif error\n");
        exit(-1);
    }
    // load the font
    if (!LoadFONT(&F1,"../Asset/FONT/HELLOC.chr")) {
        printf("HELLOC.chr error loading\n");
        exit(-1);
    }

    renderLeftViewWorkerID = CreateDWorker(RenderLeftViewFunc, nullptr);
    renderRighViewtWorkerID = CreateDWorker(RenderRightViewFunc, nullptr);

    DgInstallTimer(500);
    if (DgTimerFreq == 0) {
        DgQuit();
        printf("Timer error\n");
        exit(-1);
    }
    if (!InstallKeyboard()) {
        DgQuit();
        printf("keyboard error\n");
        exit(-1);
    }

    // init video mode
    if (!DgInitMainWindowX("Sprites", ScrResH, ScrResV, 16, -1, -1, false, false, false)) {
        DgQuit();
        exit(-1);
    }

    InitSynch(SynchBuff,NULL,60);

    SetFONT(&F1);
    NbSprites = 0;
    int randY = (ScrResV - 180);
    // start the main loop
    for (int j=0;; j++) {
        DgCheckEvents();
        // synchronise
        Synch(SynchBuff,NULL);
        // average time
        float avgFps=SynchAverageTime(SynchBuff);

        // sprites DATA handling progressing
        // add a new sprite if we have not reached the max
        if (!PauseMove) {
            if (NbSprites < MAX_SPRITES) {
                Sprites[NbSprites].x = 0;
                Sprites[NbSprites].y = rand()%randY+20;
                Sprites[NbSprites].xspeed = rand()%10;
                Sprites[NbSprites].sprite = sprites[rand()%3];
                NbSprites++; // increase the number of sprites
            }
            // increase pos of the sprites
            for (int i=0; i< NbSprites; i++) {
                Sprites[i].x+=Sprites[i].xspeed;
                if (Sprites[i].x>=SpritesView.MaxX || Sprites[i].x<=SpritesView.MinX)
                    Sprites[i].xspeed = -Sprites[i].xspeed;
            }
        }
        // sprites rendering **********
        if (!dualCoreRender) {
            // set the current active surface for drawing
            DgSetCurSurf(RendSurf);
            // set the view of the sprites for the current drawing surf
            SetSurfView(&CurSurf, &SpritesView);
            // clear sprites View
            ClearSurf16(0x0);
            // draw all the available sprites
            for (int i=0; i< NbSprites; i++) {
                PutMaskSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? PUTSURF_NORM : PUTSURF_INV_HZ);
            }
        } else {
            RunDWorker(renderLeftViewWorkerID, false);
            RunDWorker(renderRighViewtWorkerID, false);
            WaitDWorker(renderLeftViewWorkerID);
            WaitDWorker(renderRighViewtWorkerID);
        }
        // display text
        DgSetCurSurf(RendSurf);
        SetSurfView(&CurSurf, &TextView);
        ClearSurf16(0x0);
        ClearText(); // clear test position to upper left
        SetTextCol(RGB16(255,255,255));
        char text[100];

        OutText16ModeFormat(AJ_MID, text, 100, "Sprites %04i, fps %03i, '%s' Rendering, '%s'\n\n",NbSprites,
                            (int)((avgFps>0.0)?(1.0/(avgFps)):-1),
                            (!dualCoreRender)?"Single Core":"Dual Core",
                            (!PauseMove)?"Moving..":"Paused"
                            );
        SetTextCol(RGB16(255,255,0));
        OutText16Mode("Esc to Exit | Space to Toggle Pause | Tab to switch from Single/Dual Core rendering", AJ_SRC);

        // get key
        unsigned char keyCode;
        unsigned int keyFLAG;

        GetKey(&keyCode, &keyFLAG);
        switch (keyCode) {
        case KB_KEY_SPACE :
            PauseMove=!PauseMove;
            break;
        case KB_KEY_ESC:
            ExitApp = true;
            break;
        case KB_KEY_TAB:
            dualCoreRender = !dualCoreRender;
            break;
        }

        // exit if esc pressed
        if (ExitApp) break;

        DgUpdateWindow();
    }

    DestroyDWorker(renderLeftViewWorkerID);
    DestroyDWorker(renderRighViewtWorkerID);
    DgQuit();
    return 0;
}

void RenderLeftViewFunc(void *, int ) {
    DgSetCurSurf(RendSurf);
    SetSurfView(&CurSurf, &SpritesLeftView);
    ClearSurf16(0x0);

    // draw all the available sprites
    for (int i=0; i< NbSprites; i++) {
        PutMaskSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? PUTSURF_NORM : PUTSURF_INV_HZ);
    }
}

void RenderRightViewFunc(void *, int ) {
    DgSetCurSurf_C2(RendSurf);
    SetSurfView(&CurSurf_C2, &SpritesRightView);
    ClearSurf16_C2(0);

    // draw all the available sprites
    for (int i=0; i< NbSprites; i++) {
        PutMaskSurf16_C2(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? PUTSURF_NORM : PUTSURF_INV_HZ);
    }
}

