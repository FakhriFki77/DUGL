/*  Dust Ultimate Game Library (DUGL) - (C) 2023 Fakhri Feki */
/*  Sprites Sample */
/*  old History : DUGL DOS/DJGPP */
/*  3 september 2006 : first release */
/*  March 2007 : better fps calculation */
/*  History: */
/*  11 February 2023: First port */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <DUGL.h>

typedef struct {
    int x,  // pos x
        y,  // pos y
        xspeed; // delta x
    int type; // 0 the man, 1 the cat, the ball of the cat
} mySprite;

#define MAX_SPRITES  15000
int NbSprites = 0;
mySprite Sprites[MAX_SPRITES];

FONT F1;
unsigned char rouge,bleu,jaune,noir,blanc; // index of needed colors

int ScrResH = 800, ScrResV = 600;
int i,j; // counters

// used view *******
DgView SpritesView = { 0,0,ScrResH-1,ScrResV-1,0,40 },
       TextView = { 0,0,ScrResH-1,39,0,0 },
       AllView = { 0,0,ScrResH-1,ScrResV-1,0,0 };

// *** memory suface of the Sprites ****************************
DgSurf *ana1,  // sprites of the man
       *chat1, // cat
       *balleChat1;  // ball of the cat
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
    if (!LoadGIF16(&ana1,"../Asset/PICS/man1.gif")) {
        printf("man1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&chat1,"../Asset/PICS/cat1.gif")) {
        printf("cat1.gif error\n");
        exit(-1);
    }
    if (!LoadGIF16(&balleChat1,"../Asset/PICS/balcat1.gif")) {
        printf("balcat1.gif error\n");
        exit(-1);
    }
    // load the font
    if (!LoadFONT(&F1,"../Asset/FONT/HELLOC.chr")) {
        printf("HELLOC.chr error loading\n");
        exit(-1);
    }

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
    if (!DgInitMainWindowX("Sprites", ScrResH, ScrResV, 16, -1, -1, false, false, true)) {
        DgQuit();
        exit(-1);
    }

    InitSynch(SynchBuff,NULL,60);

    SetFONT(&F1);
    unsigned int OldTime = DgTime;
    NbSprites = 0;
    int randY = (ScrResV - 180);
    int PosSynch;
    //InitSynch(SynchBuff,&PosSynch,CurModeVtFreq);
    // start the main loop
    for (j=0;; j++) {
        DgCheckEvents();
        // synchronise
        Synch(SynchBuff,NULL);
        // average time
        float avgFps=SynchAverageTime(SynchBuff),
              lastFps=SynchLastTime(SynchBuff);

        // set the current active surface for drawing
        DgSetCurSurf(RendSurf);

        // clear all the current Surf, does not care of any view
        ClearSurf16(0x0); // clear with black
        // set the view of the sprites for the current drawing surf
        SetSurfView(&CurSurf, &SpritesView);
        // add a new sprite if we have not reached the max
        if (NbSprites < MAX_SPRITES) {
            Sprites[NbSprites].x = 0;
            Sprites[NbSprites].y = rand()%randY+20;
            Sprites[NbSprites].xspeed = rand()%10;
            Sprites[NbSprites].type = rand()%3;
            NbSprites++; // increase the number of sprites
        }
        // draw all the available sprites
        for (i=0; i< NbSprites; i++) {
            DgSurf *mySprite = NULL;
            int SpriteDType = PUTSURF_INV_HZ;
            // who is our sprite ?
            switch  (Sprites[i].type) {
            case 0 :
                mySprite = ana1;
                break;
            case 1 :
                mySprite = chat1;
                break;
            case 2 :
                mySprite = balleChat1;
            };
            // the sprite will be draw inversed horizontally if going back
            if (Sprites[i].xspeed<0)
                SpriteDType = PUTSURF_NORM;
            if (mySprite!=NULL)
                PutMaskSurf16(mySprite,Sprites[i].x,Sprites[i].y,SpriteDType);
        }
        // increase pos of the sprites
        for (i=0; i< NbSprites; i++) {
            Sprites[i].x+=Sprites[i].xspeed;
            if (Sprites[i].x>=SpritesView.MaxX || Sprites[i].x<=SpritesView.MinX)
                Sprites[i].xspeed = -Sprites[i].xspeed;
        }
        // display text
        SetSurfView(&CurSurf, &TextView);
        ClearText(); // clear test position to upper left
        SetTextCol(0xffff);
        char text[100];

        OutText16ModeFormat(AJ_MID, text, 100, "Sprites %04i, fps %03i",NbSprites,
                            (int)((avgFps>0.0)?(1.0/(avgFps)):-1));

        // exit if esc pressed
        if (IsKeyDown(KB_KEY_ESC)) break;

        DgUpdateWindow();
    }

    DgQuit();
    return 0;
}


