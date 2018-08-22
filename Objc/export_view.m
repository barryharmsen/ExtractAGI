/*
 *	export_view.m
 *
 *	Description: Export the VIEW sprite objects from the volume files and save out the images.
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 24-25 July 2018
 *	To compile: gcc -w -framework Foundation export_view.m -o export_view
 *	To run: ./export_view path/to/dir.json path/to/agi/files
 *
 *	Resources:
 *	- VIEW specs: http://www.agidev.com/articles/agispec/agispecs-8.html
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_view.py
 *	- http://www.agidev.com/articles/agispec/examples/view/viewview.pas
 *	- http://www.agidev.com/articles/agispec/examples/files/volx2.c
 *
 *	Items to write about in a blog follow up
 *	- Big/Little Endian
 *	- RLE
 *	- Saving data to an image file in Cocoa
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	if (argc < 3) {
		printf("usage: %s path/to/dir.json path/to/agi/files\n", argv[0]);
	}
	
	NSString *dirFilePath = [[NSString stringWithUTF8String: argv[1]] stringByExpandingTildeInPath];;
	NSString *agiDir = [[NSString stringWithUTF8String: argv[2]] stringByExpandingTildeInPath];
	NSFileManager *fm = [NSFileManager defaultManager];
	
// 	palette = [
// 	(0, 0, 0),      : 000000 : Black
// 	(0, 0, 160),    : 0000A0 : Dark blue
// 	(0, 255, 80),   : 00FF50 : Bright green grass
// 	(0, 160, 160),  : 00A0A0 : Teal
// 	(160, 0, 0),    : A00000 : Deep red
// 	(128, 0, 160),  : 8000A0 : Purple
// 	(160, 80, 0),   : A05000 : Wood brown
// 	(160, 160, 160),: A0A0A0 : Light grey
// 	(80, 80, 80),   : 505050 : Dark grey
// 	(80, 80, 255),  : 5050FF : Blue-purple
// 	(0, 255, 80),   : 00FF50 : More bright green...same as above??  
// 
// 	(80, 160, 0),   : 50A000 : Darker green -- how about this, instead?
// 
// 	(80, 255, 255), : 50FFFF : Light blue
// 	(255, 80, 80),  : FF5050 : Salmon
// 	(255, 80, 255), : FF50FF : Light purple
// 	(255, 255, 80), : FFFF50 : Yellow
// 	(255, 255, 255) : FFFFFF : White
// 
// 	0   = 00
// 	80  = 50
// 	128 = 80
// 	160 = A0
// 	255 = FF
	
	int colorPalette[16][3] = {	{0, 0, 0}, 		// Black
								{0, 0, 160}, 	// Dark blue
								{0, 255, 80}, 	// Bright green grass
								{0, 160, 160},	// Teal
    							{160, 0, 0}, 	// Deep red
    							{128, 0, 160}, 	// Purple
    							{160, 80, 0}, 	// Wood brown
    							{160, 160, 160}, // Light grey
           						{80, 80, 80}, 	// Dark grey
           						{80, 80, 255}, 	// Blue-purple
           						{0, 255, 80}, 	// Another bright green?? Perhaps should be (80, 160, 0) or transparent
           						{80, 255, 255},	// Light blue
           						{255, 80, 80}, 	// Salmon
           						{255, 80, 255},	// Light purple
           						{255, 255, 80},	// Yellow
           						{255, 255, 255} // White
           					  };
	
	if ([fm fileExistsAtPath: dirFilePath] == YES) {
		// 1. Get the set of VIEWs and their offsets from dir.json
		NSData *data = [NSData dataWithContentsOfFile:dirFilePath];
		NSDictionary *dirDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
		
		NSDictionary *viewDictionaries = dirDict[@"VIEWDIR"];
		
		if (viewDictionaries != nil) {
			// NSLog(@"viewDictionaries:: %@", viewDictionaries);
			/* 
			// Example of a value object
			22 =     {
				offset = 101177;
				vol = 1;
			};
    		*/
    		
			[viewDictionaries enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *value, BOOL *stop) {
				// 2. Get the volume number and offset of each VIEW
				NSInteger offset = [[value objectForKey: @"offset"] integerValue];
				NSInteger vol = [[value objectForKey: @"vol"] integerValue];
				// NSLog(@"%@) vol: %d offset: %d", key, vol, offset);
				
				// 3. Get the header info for each VIEW
				NSString *volumeName = [NSString stringWithFormat: @"VOL.%d", vol];
				NSString *volumePath = [agiDir stringByAppendingPathComponent: volumeName];
				FILE *volFile;
				
				if ((volFile = fopen([volumePath UTF8String], "r")) == NULL) {		
					fprintf(stderr, "Could not open input file %s\n", argv[1]);
					exit(EXIT_FAILURE);
				}
				
				fseek(volFile, offset, SEEK_SET);
				
				// Big Endian : High - Low
				int ms_byte = getc(volFile); 
				int ls_byte = getc(volFile);
				long signature = ms_byte*256 + ls_byte;
				
				// View Header
// 				Byte  Meaning
// 				----- -----------------------------------------------------------
// 				  0   Unknown (always seems to be either 1 or 2)
// 				  1   Unknown (always seems to be 1)
// 				  2   Number of loops
// 				 3-4  Position of description (more on this later)
// 					  Both bytes are 0 if there is no description
// 				 5-6  Position of first loop
// 				 7-8  Position of second loop (if any)
// 				 9-10 Position of third loop (if any)
// 				 ...  ...
// 				----- -----------------------------------------------------------
				if (signature == 0x1234) {
					// printf("%x %d\n", signature, signature);
					
					int volNum = getc(volFile); // volume number
					// Little Endian : Low - High
					int lowResByte = getc(volFile); // res len byte 1 // generally over 100
					int highResByte = getc(volFile); // res len byte 2 // usually 6 or less
					int reslen = highResByte*256 + lowResByte;
					
					// The documented View Header starts here
					int byteSix = getc(volFile); // 0 - 2 -- also vol #?
					int byteSeven = getc(volFile); // always 1
					
					int numLoops = getc(volFile); // Number of loops, not larger than 255
					
					int desc1 = getc(volFile); // description byte 1 -- 0 - 255
					int desc2 = getc(volFile); // description byte 2 -- 0 or 1
					int descPosition = desc2*256 + desc1;
					
					printf("key: %s bytes 3 - 6: %d %d %d (%d) %d %d %d %d %d (%d)\n", [key UTF8String], volNum, lowResByte, highResByte, reslen, byteSix, byteSeven, numLoops, desc1, desc2, descPosition);
					
//					Loop Header					
// 					Byte  Meaning
// 					----- -----------------------------------------------------------
// 					  0   Number of cels in this loop
// 					 1-2  Position of first cel, relative to start of loop
// 					 3-4  Position of second cel (if any), relative to start of loop
// 					 5-6  Position of third cel (if any), relative to start of loop
// 					----- -----------------------------------------------------------
					for (int i = 0; i < numLoops; i++) {
						int view_offset1 = getc(volFile);
						int view_offset2 = getc(volFile);
						int view_offset = view_offset2*256 + view_offset1 + offset + 5;
						printf("\t view_offset: %d\n", view_offset);
					}
					

				}
				
				
				fclose(volFile); // TODO: Check for failure on closing the file
				
			}];

		}
	
	} else {
		NSLog(@"Error: The file %@ does not exist.", dirFilePath);
	}
	
	[pool release];
	return 0;
}