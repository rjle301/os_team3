#ifndef PROGVGA_INC_C_
#define PROGVGA_INC_C_
#include <common.h>


/**
** User function VGA:   setvga256linear, writepixel, setvgatextmode, returnwidth, returnheight, settext, sleep
**
** Set mode to vga mode 13h, write a 10x10 pixel rect starting at the middle, wait 5 seconds, and then swap back to text mode.
**
** Invoked as:  progVGA
*/


USERMAIN( progVGA ) {


	ARG_PROC( 3, args, 5, argc, "progVGA" );

    setvga256linear();//Sets to linear text mode.


    unsigned x = getwidth()/2;
    unsigned y = getheight()/2;

    unsigned YELLOW = 0x6;//Taken from pagekey's definition of yellow. Hopefully this actually works

    for(int i = 0; i < 10;i++){
        for(int j = 0; j < 10; j++){
            writepixel(x, y, YELLOW);
        }
    }

    sleep(SEC_TO_MS(5));


    setvgatextmode();//Go from mode 13h to mode 3

	exit( 0 );

	return( 42 );  // shut the compiler up!

}

#endif