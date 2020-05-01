/*
 *	FindAGIGameID.c
 *	Description: Check to see if an AGI Sierra game is either version 2 or 3.
 *	Author: Chad Armstrong
 *	Date: 29 April 2020
 *	To compile: gcc -Wall -o FindAGIGameID FindAGIGameID.c
 *	To run: ./FindAGIGameID
 *
 *	References:
 *	- https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/glob.3.html
 *	- https://developer.blackberry.com/playbook/native/reference/com.qnx.doc.neutrino.lib_ref/topic/g/glob.html
 *	- https://github.com/edenwaith/qt-agi-studio/blob/master/src/game.cpp
 */

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <glob.h>

// Handle any errors from glob()
int globErrorHandler(const char* epath, int eerno)
{
	printf("glob() error at %s \n", strerror(eerno) );
	
	return 0;  // Let glob() continue
}


// Compare the prefix for VOL.0 and DIR - if they are same and non-NULL
// it is a V3 game
char * FindAGIV3GameID(const char *name)
{
	char *ptr;
	char *cfilename;
	char *ID1 = "V2"; // default for V2 AGI games
	char tmp[100];
	char dirString[10]="", volString[10]="";

	glob_t globbuf;
	memset(&globbuf, 0, sizeof(globbuf)); // Initialize globbuf
  
	// Look for any files which end with "DIR".  For V3 AGI games, there will
	// be only one DIR file which will have a prefix of the game (KQ4, GR, MH, MH2).
	// If this is a V2 AGI game, there are 4 DIR files (LOGDIR, PICDIR, SNDDIR, VIEWDIR)
	sprintf(tmp,"%s/*DIR", name);

	// If glob does not return 0, then there was an error 
	if (glob (tmp, GLOB_ERR | GLOB_NOSORT, globErrorHandler, &globbuf)) 
	{
		globfree(&globbuf);
		return ID1;
	}

	cfilename = globbuf.gl_pathv[0];

	if ((ptr = strrchr(cfilename,'/'))) 
	{
		ptr++;
	}
	else 
	{
		ptr = cfilename;
	}

	strncpy (dirString, ptr, strlen (ptr) - 3);

	globfree(&globbuf);
  
  
  	// Search for any files which end with "VOL.0".  V3 games will prefix the VOL
  	// files with the game's prefix rubric (e.g. KQ4VOL.0).
  	sprintf(tmp,"%s/*VOL.0",name);

	if (glob (tmp, GLOB_ERR | GLOB_NOSORT, globErrorHandler, &globbuf)) 
	{
    	globfree(&globbuf);
    	return ID1;
	}

	cfilename = globbuf.gl_pathv[0];

	// Locate the character '/' in the string
	if ((ptr = strrchr(cfilename,'/'))) 
	{
		ptr++;
	}
	else 
	{
		ptr = cfilename;
	}

	strncpy (volString, ptr, strlen (ptr) - 5);

	globfree(&globbuf);
  
	if ((strcmp(volString, dirString) == 0) && (volString != NULL)) 
	{
		printf("volString is %s \n", volString);
		ID1 = volString;
	}

	return ID1;
}


int main( int argc, char *argv[] )
{
	char *path = ".";
	
	if (argc >= 2)
	{
		path = argv[1];
	}

	printf("Game ID: %s\n", FindAGIV3GameID(path));
	
	return 0;
}