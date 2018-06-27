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
	
	// At the start of the file is a section that is always 26x2 bytes long. 
	// This section contains a two byte entry for every letter of the alphabet. 
	// It is essentially an index which gives the starting location of the words 
	// beginning with the corresponding letter.
	//fseek(fp, 52, SEEK_SET); // jump to position 52 in the file
	
	int data = -1;
	
	// Get the indexes of the words, which are stored in the first 52 bytes
	
	printf("Storage size for int is %d and short is %d \n", sizeof(int), sizeof(short));
	
	short buffer[2];
	short short_data = -1;
	short buf[2];
	
	// https://cboard.cprogramming.com/c-programming/84251-read-2-bytes-file.html
	for (int i = 0; i < 26; i++) {
		if (fread(buf, sizeof(short), 1, fp) == 1)
   		{
      		// printf("%02x %02x\n", (int) buf[0], (int) buf[1]);
      		printf("%02x (%d)\n", buf[0], buf[0]);
   		}
	
//  		fread((void *)buffer, sizeof(short), 1, fp);
//  		printf("%d:: buffer: %s (%x)\n", i, buffer, buffer);
 		
//		short_data = getc(fp);
//		printf("%d) %d (%x)\n", i, short_data, short_data);
	}
	
	// data = getc(fp);
	
	// For position 54, the number 49 was returned, when printed as a character is
	// the number 1 in decimal.
	// If the number is 0, that is a nul, which might represent the nul character, as well
	// printf("data:: %d %c\n", data, data); 
	
	
	while (( data = getc(fp)) != EOF) {
	
//	data = getc(fp);
		
		if (data < 32) {
			int new_data = data ^ 127;
			// printf("new_data:: %d %c\n", new_data, new_data);
			printf("%c ", new_data);
		} else if (data > 127) {
			int new_data = (data - 128) ^ 127;
			// printf("new_data:: %d %c\n", new_data, new_data);
			printf("%c ", new_data);
		} else if (data == 95) {
			// printf("   _data:: %d  %c\n", data, data);
			printf("%c ", data);
		} else {
			//printf("    data:: %d %c\n", data, data);
			printf("%c ", data);
		}
	}
	
	
	fclose(fp);
	
	[pool drain];
	return 0;
}