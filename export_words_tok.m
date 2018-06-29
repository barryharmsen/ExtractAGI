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
	NSMutableString *currentWord  = [[NSMutableString alloc] init];
	NSMutableString *previousWord = [[NSMutableString alloc] init];
	NSMutableDictionary *wordsDictionary = [[NSMutableDictionary alloc] init];
		
	FILE *fp, *fpout;
	int data    = -1;
	int ms_byte = -1;
	int ls_byte = -1;
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
	
	// At the start of the file is a section that is always 26x2 bytes long. 
	// This section contains a two byte entry for every letter of the alphabet. 
	// It is essentially an index which gives the starting location of the words 
	// beginning with the corresponding letter.
	
	// Read byte 1 (second byte in the file, since the index starts at 0), to retrieve
	// the offset where the words section begins.  Example value might be 3E, which is
	// the hexadecimal value for 62.
	fseek(fp, 1, SEEK_SET);
	initPos = getc(fp);
	printf("Data at position 1: %x (%d)", initPos, initPos);

	// Jump to the offset for the first word.  Other examples might show jumping to offset
	// 52, but that may cause other errors, so refer to the offset value read from byte 1.
	fseek(fp, initPos, SEEK_SET);
		

	
	while (true) { // outer loop
	
		[previousWord setString: currentWord];
		[currentWord setString: @""];
	
		if (( data = getc(fp)) == EOF) {
			// Once the end of file has been reached, break out of the outer loop
			break;
		}
	
		// Need to copy a given substring of the previous word to the current word
		if (data <= [previousWord length]) {
			[currentWord setString: [previousWord substringToIndex: data]];
		}
		
		while (true) { // inner loop
		
			if (( data = getc(fp)) == EOF) {
				// If the end of file has been reached, break out of the inner loop
				break;
			}
		
			// The only values of interest are under 32, 95, or over 127.  
			// Ignore any values from 32 through 127.
			if (data < 32) {
				// A letter of the current word.
				int new_data = data ^ 127;
				[currentWord appendFormat:@"%c", new_data];

			} else if (data == 95) {
				// A space character
				[currentWord appendString: @" "];
				
			} else if (data > 127) {
			
				int new_data = (data - 128) ^ 127;
				[currentWord appendFormat:@"%c", new_data];
				NSLog(@"currentWord: %@", currentWord);
				NSString *stringToWrite = [NSString stringWithFormat: @"%@\n", currentWord];
				fputs([stringToWrite cStringUsingEncoding: NSASCIIStringEncoding], fpout);

				break; // break out of the inner loop 
				
			}
		}
		
		// Get two more bytes of data to determine how to group the words together
		ms_byte = getc(fp);
		ls_byte = getc(fp);
		
		// Determine the word group index
		int word_block_num = ms_byte*256 + ls_byte;
		
		
		// printf("ms_byte: %d ls_byte: %d -> %d ---------\n", ms_byte, ls_byte, word_block_num);
		
		if (word_block_num >= 0) {
		
			NSString *key = [NSString stringWithFormat:@"%d", word_block_num]; // NSDictionary keys must be objects not value types
			NSString *newWord = [currentWord copy]; // Copy the current word to a new string
			
			// Add word to dictionary
			if ([wordsDictionary objectForKey: key]) {
				// If the key exists, add the new word to the existing value array
				NSMutableArray *wordsArray = [[NSMutableArray alloc] initWithArray: [wordsDictionary objectForKey: key]];
				[wordsArray addObject: newWord];
				[wordsDictionary setObject: wordsArray forKey: key];
			} else {
				// If the key does not exist yet, add the current word in an array				
				[wordsDictionary setObject: @[newWord] forKey: key];
			}
		}
		
	}
	
	// Write dictionary contents to a file (JSON format)
	NSError *error = nil; 
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:wordsDictionary 
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys 
                                                     error:&error];
                                                     
    if (error != nil) {
    	NSLog(@"Error creating JSON data: %@", [error localizedDescription]);
    } else {
    	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

		BOOL succeed = [jsonString writeToFile:@"words.json" atomically:YES encoding:NSUTF8StringEncoding error:&error];
		if (succeed == NO) {
			NSLog(@"Error saving file 'words.json': %@", [error localizedDescription]);
		}
    }

	
	fclose(fp);
	fclose(fpout);
	
	[pool drain];
	return 0;
}