/*
 *	export_dir.m
 *
 *	Description: Reverse engineer the WORDS.TOK file from an AGI Sierra game.
 *	             The results are saved into two files: words.txt and words.json
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 5 July 2018
 *	To compile: gcc -w -framework Foundation export_dir.m -o export_dir
 *
 *	Resources:
 *	- WORDS.TOK specs: http://www.agidev.com/articles/agispec/agispecs-10.html#ss10.2
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_dir.py
 *	- http://www.agidev.com/articles/agispec/examples/otherdata/words.pas
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *sourceDir = nil;
	
	// Set the source directory path.  If one hasn't been specified, assume the cwd
	if (argc >= 2) {
		sourceDir = [NSString stringWithUTF8String:argv[1]];
	} else {
		sourceDir = @"./";
	}
	
	NSLog(@"sourceDir:: %@", sourceDir);
	
	NSArray *fileList = @[@"VIEWDIR", @"PICDIR", @"LOGDIR", @"SNDDIR"];
	NSMutableDictionary *directories = [NSMutableDictionary new];
	
	for (NSString *fileName in fileList) {
		
		NSString *dirFilePath = [sourceDir stringByAppendingPathComponent: fileName];
		NSLog(@"dirFilePath:: %@", dirFilePath);
	}
	
	[pool drain];
	return 0;
}