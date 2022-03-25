/*  Dust Ultimate Game Library (DUGL) - (C) 2022 Fakhri Feki */
/*  Sample of DSTRDic C Dictionnary <char*,void*> : */
/* 	console app to compare performance of DSTRDic<char*,void*> against std::map<std::string,void*> */

/*  History : */
/*  25 march 2022 : first release */

// on my system DSTRDic is about 10 times, 4 times and 5 times faster !
//0 - Timing std::map
//0 - Creating std::map Dictionnary
//1571 - Inserting 1.50 milions (key, value) in 1.57 sec
//2518 - searching for random 1 milions (key, value) in 0.95 sec
//2567 - traversing all 1.50 milions elements  (key, value) in 0.05 sec
//2569 - Timing DSTRDic
//2571 - Creating DSTRDic Dictionnary
//2704 - Inserting 1.50 milions (key, value) in 0.13 sec
//2894 - searching for random 1 milions (key, value) in 0.19 sec
//2904 - traversing all 1.50 milions elements  (key, value) in 0.01 sec

#include <map>
#include <string>

#include <stdio.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include "DUGL.h"


int main (int argc, char ** argv)
{
    // init the lib
    if (!DgInit()) {
		printf("DUGL init error\n"); exit(-1);
	}

    // install timer
    DgInstallTimer(1000);

    if (DgTimerFreq == 0)
    {
       DgQuit();
       printf("Timer error\n");
       exit(-1);
    }

	// std::map

    std::map<std::string,void*> mapData;
	char intstr[10];
    unsigned int countKeyVal = 1500000;
    unsigned int lastDgTime = 0;
    printf("%i - Timing std::map\n", DgTime);
    printf("%i - Creating std::map Dictionnary\n", DgTime);
    lastDgTime = DgTime;
    for (unsigned int idic=0;idic<countKeyVal;idic++) {
		itoa(idic+123456, intstr, 10);
		mapData.insert(std::make_pair(intstr, (void*)(idic+1+123456))); // inserting an integer instead of void *
    }
    printf("%i - Inserting %0.2f milions (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
    lastDgTime = DgTime;
    int valptr = 0;
    for (int idic=0;idic<1000000;idic++) {
		itoa((rand()%countKeyVal)+123456, intstr, 10);
		auto fit = mapData.find(intstr);
		if (fit != mapData.end()) {
			valptr = (int)fit->second;
		}
    }
    printf("%i - searching for random 1 milions (key, value) in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
    lastDgTime = DgTime;
	for (auto i = mapData.begin(); i != mapData.end(); i++) {
		valptr = (int)i->second;
	}
    printf("%i - traversing all %0.2f milions elements  (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));

    // DSTRDic

    printf("%i - Timing DSTRDic\n", DgTime);
	DSTRDic *strDIC =CreateDSTRDic(0, 18); // hash Table in 18bits or 256k elements without collision
	printf("%i - Creating DSTRDic Dictionnary \n", DgTime);
    lastDgTime = DgTime;
	for (unsigned int idic=0;idic<countKeyVal;idic++) {
		itoa(idic+123456, intstr, 10);
		InsertDSTRDic(strDIC, intstr, (void*)(idic+1+123456), false);
	}
    printf("%i - Inserting %0.2f milions (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
    lastDgTime = DgTime;
    valptr = 0;
	for (unsigned int idic=0;idic<1000000;idic++) {
		itoa((rand()%countKeyVal)+123456, intstr, 10);
		valptr = (int)keyValueDSTRDic(strDIC, intstr);
	}
    printf("%i - searching for random 1 milions (key, value) in %0.2f sec\n", DgTime, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
    lastDgTime = DgTime;
    char *strv = NULL;
    void *datav = NULL;
    bool hasElem = false;
    for (hasElem = GetFirstValueDSTRDic(strDIC, &strv, &datav); hasElem; hasElem = GetNextValueDSTRDic(strDIC, &strv, &datav)) {
		valptr = (int)datav;
    }
    printf("%i - traversing all %0.2f milions elements  (key, value) in %0.2f sec\n", DgTime, float(countKeyVal)/1000000.0f, (float)(DgTime-lastDgTime)/(float)(DgTimerFreq));
	DestroyDSTRDic(strDIC);

    DgQuit();
    return 0;
}
