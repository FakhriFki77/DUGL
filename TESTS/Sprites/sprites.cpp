/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */
/*  Sprites Sample */
/*  old History : DUGL DOS/DJGPP */
/*  3 september 2006 : first release */
/*  March 2007 : better fps calculation */
/*  History: */
/*  11 February 2023: First port */
/*  12 February 2023: Few optimizations - First demonstration of DUGL Multi Cores rendering by splitting screen */
/*     into left and right view and setting a DWorker to render each view, boosting fps by ~50% */
/*  24 February 2023: Adds quad core rendering capability - Fix bug of zero speed sprites */
/*  25 February 2023: Update Quad core rendering to use the new GetDGCORE function,
       use RenderContext to reduce rendering worker functions to only one function */
/*  2 March 2023: Detect/handle window close request */

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
//int ScrResH = 1024, ScrResV = 768;


// app controle
bool ExitApp = false;
bool dualCoreRender = false;
bool quadCoreRender = false;
bool PauseMove = false;
// used view *******
int TextViewHeight = 50;
int rendViewHeight = ScrResV - TextViewHeight;
DgView SpritesView = { 0,0,ScrResH-1,ScrResV-1,0,TextViewHeight },
       // dual core render
       SpritesLeftView = { 0, 0, ScrResH/2-1, ScrResV-1, 0, TextViewHeight },
       SpritesRightView = { 0, 0, ScrResH-1,  ScrResV-1, ScrResH/2, TextViewHeight },
       // quad core render
       SpritesTopLeftView = { 0, 0, ScrResH/2-1, ScrResV-1, 0, (rendViewHeight/2) + TextViewHeight },
       SpritesBottomLeftView = { 0, 0, ScrResH/2-1, (rendViewHeight/2-1) + TextViewHeight, 0, TextViewHeight },
       SpritesTopRightView = { 0, 0, ScrResH-1,  ScrResV-1, ScrResH/2, (rendViewHeight/2) + TextViewHeight },
       SpritesBottomRightView = { 0, 0, ScrResH-1, (rendViewHeight/2-1) + TextViewHeight, ScrResH/2, TextViewHeight },
       // utils view
       TextView = { 0,0,ScrResH-1,49,0,0 },
       AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

typedef struct {
    DgView *rendView;
    DGCORE rendCore;
} rendContext;

// render DWorker's
// required for dual core rendering
unsigned int renderLeftViewWorkerID = 0;
unsigned int renderRighViewtWorkerID = 0;
void RenderLeftViewFunc(void *, int );
void RenderRightViewFunc(void *, int );
// required for quad core rendering
unsigned int renderTopLeftViewWorkerID = 0;
unsigned int renderBottomLeftViewWorkerID = 0;
unsigned int renderTopRighViewtWorkerID = 0;
unsigned int renderBottomRighViewtWorkerID = 0;
void RenderViewFunc(void *myRendContext, int );
rendContext LeftTopViewRendContext;
rendContext LeftBottomViewRendContext;
rendContext RightTopViewRendContext;
rendContext RightBottomViewRendContext;

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

    // init dual core rendering
    renderLeftViewWorkerID = CreateDWorker(RenderLeftViewFunc, nullptr);
    renderRighViewtWorkerID = CreateDWorker(RenderRightViewFunc, nullptr);

    // init quad core rendering
    LeftTopViewRendContext.rendView = &SpritesTopLeftView;
    GetDGCORE(&LeftTopViewRendContext.rendCore, 0);
    LeftBottomViewRendContext.rendView = &SpritesBottomLeftView ;
    GetDGCORE(&LeftBottomViewRendContext.rendCore, 1);
    RightTopViewRendContext.rendView = &SpritesTopRightView;
    GetDGCORE(&RightTopViewRendContext.rendCore, 2);
    RightBottomViewRendContext.rendView = &SpritesBottomRightView;
    GetDGCORE(&RightBottomViewRendContext.rendCore, 3);

    renderTopLeftViewWorkerID = CreateDWorker(RenderViewFunc, &LeftTopViewRendContext);
    renderBottomLeftViewWorkerID = CreateDWorker(RenderViewFunc, &LeftBottomViewRendContext);
    renderTopRighViewtWorkerID = CreateDWorker(RenderViewFunc, &RightTopViewRendContext);
    renderBottomRighViewtWorkerID = CreateDWorker(RenderViewFunc, &RightBottomViewRendContext);

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
                Sprites[NbSprites].xspeed = rand()%10+1;
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
        if (!dualCoreRender && !quadCoreRender) {
            // set the current active surface for drawing
            DgSetCurSurf(RendSurf);
            // set the view of the sprites for the current drawing surf
            SetSurfView(&CurSurf, &SpritesView);
            // clear sprites View
            ClearSurf16(0);
            // draw all the available sprites
            for (int i=0; i< NbSprites; i++) {
                PutMaskSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? PUTSURF_NORM : PUTSURF_INV_HZ);
            }
        } else if (dualCoreRender) {
            RunDWorker(renderLeftViewWorkerID, false);
            RunDWorker(renderRighViewtWorkerID, false);
            WaitDWorker(renderLeftViewWorkerID);
            WaitDWorker(renderRighViewtWorkerID);
        } else { // quadCoreRender
            RunDWorker(renderTopLeftViewWorkerID, false);
            RunDWorker(renderBottomLeftViewWorkerID, false);
            RunDWorker(renderTopRighViewtWorkerID, false);
            RunDWorker(renderBottomRighViewtWorkerID, false);
            WaitDWorker(renderTopLeftViewWorkerID);
            WaitDWorker(renderBottomLeftViewWorkerID);
            WaitDWorker(renderTopRighViewtWorkerID);
            WaitDWorker(renderBottomRighViewtWorkerID);
        }
        // display text
        DgSetCurSurf(RendSurf);
        SetSurfView(&CurSurf, &TextView);
        ClearSurf16(0x0);
        ClearText(); // clear test position to upper left
        SetTextCol(RGB16(255,255,255));
        char text[100];

        OutText16ModeFormat(AJ_MID, text, 100, "Sprites %04i, fps %i, '%s' Rendering, '%s'\n\n",NbSprites,
                            (int)((avgFps>0.0)?(1.0f/(avgFps)):-1),
                            (!dualCoreRender && !quadCoreRender)?"Single Core":((dualCoreRender)?"Dual Core":"Quad Core"),
                            (!PauseMove)?"Moving..":"Paused"
                            );
        SetTextCol(RGB16(255,255,0));
        OutText16Mode("Esc to Exit | Space to Toggle Pause | Tab to switch from Single/Dual/Quad Core rendering", AJ_SRC);

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
            if (!dualCoreRender && !quadCoreRender)
                dualCoreRender = true;
            else if (dualCoreRender) {
                dualCoreRender = false;
                quadCoreRender = true;
            } else { // quadCoreRender == true
                dualCoreRender = false;
                quadCoreRender = false;
            }
            break;
        }

        // detect close Request
        if (DgWindowRequestClose == 1) {
            ExitApp = true;
        }

        // exit if esc pressed
        if (ExitApp) break;

        DgUpdateWindow();
    }

    DestroyDWorker(renderLeftViewWorkerID);
    DestroyDWorker(renderRighViewtWorkerID);

    DestroyDWorker(renderTopLeftViewWorkerID);
    DestroyDWorker(renderBottomLeftViewWorkerID);
    DestroyDWorker(renderTopRighViewtWorkerID);
    DestroyDWorker(renderBottomRighViewtWorkerID);

    DestroySurf(sprites[0]);
    DestroySurf(sprites[1]);
    DestroySurf(sprites[2]);

    DgQuit();
    return 0;
}

// dual core render

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

// quad core render

void RenderViewFunc(void *myRendContext, int ) {
    if (myRendContext == NULL)
        return;
    rendContext *rc = (rendContext*) myRendContext;
    rc->rendCore.DgSetCurSurf(RendSurf);
    SetSurfView(rc->rendCore.CurSurf, rc->rendView);
    rc->rendCore.ClearSurf16(0x0);

    // draw all the available sprites
    for (int i=0; i< NbSprites; i++) {
        rc->rendCore.PutMaskSurf16(Sprites[i].sprite, Sprites[i].x, Sprites[i].y, (Sprites[i].xspeed<0) ? PUTSURF_NORM : PUTSURF_INV_HZ);
    }
}
