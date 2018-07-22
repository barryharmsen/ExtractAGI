/*
 *	export_words_tok.m
 *
 *	Description: Reverse engineer the WORDS.TOK file from an AGI Sierra game.
 *	             The results are saved into two files: words.txt and words.json
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 25-28 June 2018
 *	To compile: gcc -w -framework Foundation export_view.m -o export_view
 *	To run: ./export_view path/to/dir.json
 *
 *	Resources:
 *	- VIEW specs: http://www.agidev.com/articles/agispec/agispecs-8.html
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_view.py
 *	- http://www.agidev.com/articles/agispec/examples/view/viewview.pas
 *	- http://www.agidev.com/articles/agispec/examples/files/volx2.c
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[pool release];
	return 0;
}