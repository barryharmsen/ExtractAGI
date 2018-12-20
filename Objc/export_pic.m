/*
 *	export_pic.m
 *
 *	Description: Export and draw the PICTURE backgrounds from the volume files and save out the images.
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 14 November 2018
 *	To compile: gcc -w -framework Foundation -framework AppKit export_pic.m -o export_pic
 *	To run: ./export_pic path/to/dir.json path/to/agi/files
 *
 *	History:
 *	- Version 1.0:  2018 - Initial release
 *
 *	Resources:
 *	- PICTURE specs: http://www.agidev.com/articles/agispec/agispecs-7.html
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_pic.py
 *	- http://www.agidev.com/articles/agispec/examples/view/viewview.pas
 *	- http://www.agidev.com/articles/agispec/examples/files/volx2.c
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h> // Used for NSBitmapImageRep

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (argc < 3) {
		printf("usage: %s path/to/dir.json path/to/agi/files\n", argv[0]);
		exit(EXIT_FAILURE);
	}
	
	NSString *dirFilePath = [[NSString stringWithUTF8String: argv[1]] stringByExpandingTildeInPath];;
	NSString *agiDir = [[NSString stringWithUTF8String: argv[2]] stringByExpandingTildeInPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	
// 	(0, 0, 0),      : 000000 : Black
// 	(0, 0, 170),    : 0000AA : Blue
// 	(0, 170, 0),    : 00AA00 : Green
// 	(0, 170, 170),  : 00AAAA : Cyan
// 	(170, 0, 0),    : AA0000 : Red
// 	(170, 0, 170),  : AA00AA : Magenta
// 	(170, 85, 0),   : AA5500 : Brown
// 	(170, 170, 170),: AAAAAA : Light grey
// 	(85, 85, 85),   : 555555 : Dark grey
// 	(85, 85, 255),  : 5555FF : Light blue
// 	(0, 255, 85),   : 00FF55 : Light green  
// 	(85, 255, 255), : 55FFFF : Light cyan
// 	(255, 85, 85),  : FF5555 : Light red
// 	(255, 85, 255), : FF55FF : Light magenta
// 	(255, 255, 85), : FFFF55 : Yellow
// 	(255, 255, 255) : FFFFFF : White
// 
// 	0   = 00
// 	85  = 55
// 	170 = AA
// 	255 = FF
           					  
    NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0], // Black
								[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Blue
								[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 0.0 alpha: 1.0], // Green
								[NSColor colorWithCalibratedRed: 0.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Cyan
								[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0], // Red
								[NSColor colorWithCalibratedRed: 170.0/255.0 green: 0.0 blue: 170.0/255.0 alpha: 1.0], // Magenta
								[NSColor colorWithCalibratedRed: 170.0/255.0 green: 85.0/255.0 blue: 0.0 alpha: 1.0], // Brown
								[NSColor colorWithCalibratedRed: 170.0/255.0 green: 170.0/255.0 blue: 170.0/255.0 alpha: 1.0], // Light grey
								[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Dark grey
								[NSColor colorWithCalibratedRed: 85.0/255.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light blue
								[NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Light green
								[NSColor colorWithCalibratedRed: 85.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // Light cyan
								[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 85.0/255.0 alpha: 1.0], // Light red
								[NSColor colorWithCalibratedRed: 1.0 green: 85.0/255.0 blue: 1.0 alpha: 1.0], // Light magenta
								[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 85.0/255.0 alpha: 1.0], // Yellow
    							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0], // White
    							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.0] // Clear
    						];
	
	// The export_dir program needs to be run first so the dir.json file exists which contains the
	// data where each of the views are stored on each of the volume files.
	if ([fm fileExistsAtPath: dirFilePath] == YES) {
		// 1. Get the set of PICTUREs and their offsets from dir.json
		NSData *data = [NSData dataWithContentsOfFile:dirFilePath];
		NSDictionary *dirDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
		
		NSDictionary *viewDictionaries = dirDict[@"PICDIR"];
		
		if (viewDictionaries != nil) {
			NSLog(@"viewDictionaries:: %@", viewDictionaries);
		}
	}
	
	[pool release];
	return 0;
}