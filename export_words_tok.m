/*
 *	export_words_tok.m
 *
 *	Description: Reverse engineer the WORDS.TOK file from an AGI Sierra game.
 * 	Author: Chad Armstrong
 *	Date: 25 June 2018
 *	To compile: gcc -w -framework Foundation export_words_tok.m -o export_words
 *
 *	Resources:
 *	WORDS.TOK specs: http://www.agidev.com/articles/agispec/agispecs-10.html#ss10.2
 */

#import <Foundation/Foundation.h>
// #import <AppKit/AppKit.h>

/*
#include <sys/param.h>
#include <sys/ucred.h>
#include <sys/mount.h>
*/
#include <stdio.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if (argc < 2) {
		printf("usage: %s path/to/WORDS.TOK\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	
	NSFileManager *fm = [NSFileManager defaultManager];
	FILE *fp;
	
	if ((fp = fopen(argv[1], "r")) == NULL) {		
		fprintf(stderr, "Could not open input file %s\n", argv[1]);
		exit(EXIT_FAILURE);
	}
	
	fseek(fp, 52, SEEK_SET); // jump to position 52 in the file
	
	int data = -1;
	
	data = getc(fp);
	
	// For position 54, the number 49 was returned, when printed as a character is
	// the number 1 in decimal.
	// If the number is 0, that is a nul, which might represent the nul character, as well
	printf("data:: %d %c\n", data, data); 
	
	
	while (( data = getc(fp)) != EOF) {
	
//	data = getc(fp);
		
		if (data < 32) {
			int new_data = data ^ 127;
			printf("new_data:: %d %c\n", new_data, new_data);
		} else if (data > 127) {
			int new_data = (data - 128) ^ 127;
			printf("new_data:: %d %c\n", new_data, new_data);
		} else if (data == 95) {
			printf("   _data:: %d  %c\n", data, data);
		} else {
			printf("    data:: %d %c\n", data, data);
		}
	}
	
	fclose(fp);
	
	[pool drain];
	return 0;
}