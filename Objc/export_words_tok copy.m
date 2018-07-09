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

#include <stdio.h>


int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *fm = [NSFileManager defaultManager];
	FILE *fp, *fpout;
	int data = -1;
	int msbyte = -1;
	int lsbyte = -1;
	int initPos = -1;
	
	if (argc < 2) {
		printf("usage: %s path/to/WORDS.TOK\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	
	if ((fp = fopen(argv[1], "r")) == NULL) {		
		fprintf(stderr, "Could not open input file %s\n", argv[1]);
		exit(EXIT_FAILURE);
	}
	
	if ((fpout = fopen("words.txt", "w")) == NULL) {
		fprintf(stderr, "Could not open output file 'words.txt'\n");
		exit(EXIT_FAILURE);
	}
	
	// Read byte 1 (second byte in the file, since the index starts at 0), to retrieve
	// the offset where the words section begins.  Example value might be 3E, which is
	// the hexadecimal value for 62.
	fseek(fp, 1, SEEK_SET);
	initPos = getc(fp);
	printf("Data at position 1: %x (%d)", initPos, initPos);

	
	// At the start of the file is a section that is always 26x2 bytes long. 
	// This section contains a two byte entry for every letter of the alphabet. 
	// It is essentially an index which gives the starting location of the words 
	// beginning with the corresponding letter.
	// fseek(fp, 52, SEEK_SET); // jump to position 52 in the file
	
	fseek(fp, initPos, SEEK_SET);
	
	// Get the indexes of the words, which are stored in the first 52 bytes
		
// 	short buffer[2];
// 	short short_data = -1;
// 	short buf[2];
	
	/*
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
	
	*/
	
	// data = getc(fp);
	
	// For position 54, the number 49 was returned, when printed as a character is
	// the number 1 in decimal.
	// If the number is 0, that is a nul, which might represent the nul character, as well
	// printf("data:: %d %c\n", data, data); 
	
	printf("\n-------------------------------------\n");
	
	NSMutableString *currentWord  = [[NSMutableString alloc] init];
	NSMutableString *previousWord = [[NSMutableString alloc] init];
	
	int loop_counter = 0;
	
	// while (( data = getc(fp)) != EOF) {
	while (true) {
	
		[previousWord setString: currentWord];
		[currentWord setString: @""];
	
		if (( data = getc(fp)) == EOF) {
			// break out of the outer loop
			break;
		}
	
		// Need to copy some portion of the previous word to the current word
		// printf("string length: %d %c\n", data, data);
		if (data <= [previousWord length]) {
			[currentWord setString: [previousWord substringToIndex: data]];
			// NSLog(@"previousWord substring
		}
		// NSLog(@"currentWord after copying substring %@ of length %d", currentWord, data);
//	data = getc(fp);
		
		while (true) {
		
			if (( data = getc(fp)) == EOF) {
				break;
			}
		
			if (data < 32) {

				int new_data = data ^ 127;
				[currentWord appendFormat:@"%c", new_data];

			} else if (data > 127) {
			
				int new_data = (data - 128) ^ 127;
				int other_data = data - 128; // data - 0x80
				// printf("new_data:: %d %c\n", new_data, new_data);
				// printf("%c [%c]", new_data, other_data);
				// strcpy(new_word, (char)new_data);
				// printf("new_word: %s", new_word);
				[currentWord appendFormat:@"%c", new_data];
				NSLog(@"currentWord: %@", currentWord);
				NSString *stringToWrite = [NSString stringWithFormat: @"%@\n", currentWord];
				fputs([stringToWrite cStringUsingEncoding: NSASCIIStringEncoding], fpout);

				break; // break out of the inner loop 
				
			} else if (data == 95) {
				[currentWord appendString: @" "];
			} else {
				// If the file is being parsed properly, you should never reach this condition 
				printf("data:: %c (%d / %x) \n", data, data, data);
			}
		}
		
		// Get two more bytes of data
		msbyte = getc(fp);
		lsbyte = getc(fp);
		
		int word_block_num = msbyte*256 + lsbyte;
		
		// printf("msbyte: %d lsbyte: %d -> %d ---------\n", msbyte, lsbyte, word_block_num);
		
		if (word_block_num >= 0) {
			// Add word to dictionary
		}
		
	}
	
	
	fclose(fp);
	fclose(fpout);
	
	[pool drain];
	return 0;
}