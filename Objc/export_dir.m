/*
 *	export_dir.m
 *
 *	Description: Reverse engineer the four DIR files from an AGI Sierra game.
 *	             The results are saved into the file dir.json
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 5-6 July 2018
 *	To compile: gcc -w -framework Foundation export_dir.m -o export_dir
 *
 *	Resources:
 *	- DIR specs: http://www.agidev.com/articles/agispec/agispecs-5.html#ss5.1
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_dir.py
 *	- http://www.agidev.com/articles/agispec/examples/files/agifiles.c
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *fileList = @[@"VIEWDIR", @"PICDIR", @"LOGDIR", @"SNDDIR"]; // list of the 4 "DIR" files
	NSMutableDictionary *directories = [NSMutableDictionary new];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *sourceDir = nil;
	
	// Set the source directory path.  If one hasn't been specified, assume the cwd
	if (argc < 2) {
		sourceDir = @"./";
	} else {
		sourceDir = [NSString stringWithUTF8String:argv[1]];
	}
	
	for (NSString *fileName in fileList) {
		
		NSError *error = nil;
		NSString *dirFilePath = [[sourceDir stringByAppendingPathComponent: fileName] stringByExpandingTildeInPath];

		if ([fm fileExistsAtPath: dirFilePath] == YES) {

			NSDictionary *fileAttr = [fm attributesOfItemAtPath: dirFilePath error: &error];
		
			if (error != nil) {
				NSLog(@"Error:: %@", [error localizedDescription]);
			} else {
			
				FILE *fp;
				NSMutableDictionary *directoryContents = [NSMutableDictionary new];
				double fileSize = [[fileAttr objectForKey:NSFileSize] doubleValue];
				
				// fileSize should be evenly divisible by 3
				int numDirEntries = fileSize / 3; // get the number of dir entries
				
				// Open up the file at the path dirFilePath
				if ((fp = fopen([dirFilePath UTF8String], "r")) == NULL) {		
					fprintf(stderr, "Could not open input file %s\n", [dirFilePath UTF8String]);
					break;
				}
				
				for (int i = 0; i < numDirEntries; i++) {
				
					int byte1 = getc(fp);
					int byte2 = getc(fp);
					int byte3 = getc(fp);
					
					if (byte1 != 255 && byte2 != 255 && byte3 != 255) {
						
						int vol = (byte1 & 0b11110000) >> 4; // same as (byte1 & 240) >> 4
						int offset = (byte1 & 0b00001111) << 16; // (byte1 & 15) << 16
						offset += (byte2 << 8);
						offset += byte3;
						
						NSString *key = [NSString stringWithFormat:@"%d", i];
						NSDictionary *dict = @{@"vol": [NSNumber numberWithInt: vol], 
											   @"offset": [NSNumber numberWithInt: offset]};
						[directoryContents setObject: dict forKey: key];
						
					}
				}
				
				[directories setObject: directoryContents forKey: fileName];
				
				fclose(fp);
			}
		} else {
			NSLog(@"Error: File does not exist at %@", dirFilePath);
		}
	}
	
	// Write dictionary contents to a file (JSON format)
	NSError *error = nil; 
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:directories 
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys 
                                                     error:&error];
                                                     
	if (error != nil) {
		NSLog(@"Error creating JSON data: %@", [error localizedDescription]);
	} else {
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

		BOOL succeed = [jsonString writeToFile:@"dir.json" atomically:YES encoding:NSUTF8StringEncoding error:&error];
		if (succeed == NO) {
			NSLog(@"Error saving file 'words.json': %@", [error localizedDescription]);
		}
	}
	
	[pool drain];
	return 0;
}