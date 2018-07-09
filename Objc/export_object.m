/*
 *	export_object.m
 *
 *	Description: Reverse engineer the OBJECT file from an AGI Sierra game.
 *	             The results are saved into the file object.json
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 8 July 2018
 *	To compile: gcc -w -framework Foundation export_object.m -o export_object
 *
 *	The object file stores two bits of information about the inventory items used in an 
 *	AGI game. The starting room location and the name of the inventory item. It also has 
 *	a byte that determines the maximum number of animated objects.
 *
 *	Resources:
 *	- OBJECT specs: http://www.agidev.com/articles/agispec/agispecs-10.html#ss10.1
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_object.py
 *	- http://www.agidev.com/articles/agispec/examples/otherdata/object.pas
 *	- http://www.agidev.com/articles/agispec/examples/files/agifiles.c
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[pool release];
	return 0;
}