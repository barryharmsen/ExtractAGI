/*
 *	export_view.m
 *
 *	Description: Export the VIEW sprite objects from the volume files and save out the images.
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 24 July - 25 August 2018
 *	To compile: gcc -w -framework Foundation -framework AppKit export_view.m -o export_view
 *	To run: ./export_view path/to/dir.json path/to/agi/files
 *
 *	History:
 *	- Version 1.0: 25 August 2018 - Initial release
 *	- Version 1.0.1: 19 October 2018 - Updated the color palette to match CGA colors
 *
 *	Resources:
 *	- VIEW specs: http://www.agidev.com/articles/agispec/agispecs-8.html
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *	- https://en.wikipedia.org/wiki/Run-length_encoding
 *	- https://www.prepressure.com/library/compression-algorithm/rle
 *	- https://www.geeksforgeeks.org/run-length-encoding/
 *
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_view.py
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
		// 1. Get the set of VIEWs and their offsets from dir.json
		NSData *data = [NSData dataWithContentsOfFile:dirFilePath];
		NSDictionary *dirDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
		
		NSDictionary *viewDictionaries = dirDict[@"VIEWDIR"];
		
		if (viewDictionaries != nil) {

			/* 
			// Example of a value object
			22 =     {
				offset = 101177;
				vol = 1;
			};
    		*/
    		
    		// Create the export_views directory
			NSString *exportViewsDirPath = [NSString stringWithFormat:@"%@/export_views", agiDir];
			BOOL isDir = NO;
			
			if ([fm fileExistsAtPath: exportViewsDirPath isDirectory:&isDir] == NO) {
				NSError *error = nil;
				if ([fm createDirectoryAtPath: exportViewsDirPath withIntermediateDirectories:YES attributes: nil error:&error] == NO) {
					if (error != nil) {
						NSLog(@"Failure to create directory at %@ ()", exportViewsDirPath, [error localizedDescription]);
					}
				}
			}
    		
			[viewDictionaries enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *value, BOOL *stop) {
				// 2. Get the volume number and offset of each VIEW
				NSInteger offset = [[value objectForKey: @"offset"] integerValue];
				NSInteger vol = [[value objectForKey: @"vol"] integerValue];
				
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
				
				// printf("Big Endian: %d*256 + %d = %d\n", ms_byte, ls_byte, signature);
				
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
					// TODO: Use the descPosition value (if non-zero) and find the item description
					printf("Little endian: %d*256 + %d = %d\n", desc2, desc1, descPosition);
					int loop_offsets[numLoops+1]; // Array containing loop offsets
					
//					Loop Header					
// 					Byte  Meaning
// 					----- -----------------------------------------------------------
// 					  0   Number of cels in this loop
// 					 1-2  Position of first cel, relative to start of loop
// 					 3-4  Position of second cel (if any), relative to start of loop
// 					 5-6  Position of third cel (if any), relative to start of loop
// 					----- -----------------------------------------------------------

					// Get loop offsets
					for (int i = 0; i < numLoops; i++) {

						int loop_offset1 = getc(volFile);
						int loop_offset2 = getc(volFile);

						// Supposedly 5 is the length of the view header
						int loop_offset = loop_offset2*256 + loop_offset1 + offset + 5;

						// Save the offset for each loop for each view
						loop_offsets[i] = loop_offset;
					}
					
					// Gets cells for each loop
					for (int i = 0; i < numLoops; i++) {
					
						int loop_offset = loop_offsets[i];
						fseek(volFile, loop_offset, SEEK_SET);
						
						int num_cells = getc(volFile);
						int loop_positions[num_cells]; // = {0} // perhaps init this way
						
						for (int j = 0; j < num_cells; j++) {

                        	int loop_pos1 = getc(volFile);
                        	int loop_pos2 = getc(volFile);
                            int loop_pos = loop_pos2*256 + loop_pos1 + loop_offset;

                            loop_positions[j] = loop_pos;
						}
						
//						Cell Header
// 						Byte  Meaning
// 						----- -----------------------------------------------------------
// 						  0   Width of cel (remember that AGI pixels are 2 normal EGA
// 							  pixels wide so a cel of width 12 is actually 24 pixels
// 							  wide on screen)
// 						  1   Height of cel
// 						  2   Transparency and cel mirroring
// 						----- -----------------------------------------------------------
						for (int k = 0; k < num_cells; k++) {
						
							int cel_offset = loop_positions[k];
							fseek(volFile, cel_offset, SEEK_SET);
							
							int cel_width = getc(volFile);
							int cel_height = getc(volFile);
							int cel_settings = getc(volFile);
							int cel_mirror = cel_settings >> 4;
							int cel_transparency = cel_settings & 0b00001111;
							
							// Create the bitmap image from the image data
							int image_width = cel_width * 2;
							
							NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                   pixelsWide:image_width
                                                                   pixelsHigh:cel_height
                                                                bitsPerSample:8
                                                              samplesPerPixel:4
                                                                     hasAlpha:YES
                                                                     isPlanar:NO
                                                               colorSpaceName:NSCalibratedRGBColorSpace
                                                                   bytesPerRow:4 * image_width
                                                                  bitsPerPixel:32];
							
							// Loop through the data to construct the image
							int row = 0, col = 0;
							BOOL loopComplete = NO;

							while (loopComplete == NO) {
    
								int pixelByte = getc(volFile);

								if (pixelByte == 0) { // End of row
									row++;
									col = 0;
									
									if (row >= cel_height) {
										loopComplete = YES;
									}
								}
								
								if (loopComplete == NO) {
								
									int colorIndex = pixelByte >> 4;
									
									if (colorIndex < 0) {
										colorIndex = 0;
									}
									
									if (colorIndex > 15) {
										colorIndex = 15;
									}
									
									if (colorIndex == cel_transparency) {
										colorIndex = 16;
									}
									
									NSColor *pixelColor = colorPalette[colorIndex];
									int numPixels = pixelByte & 0b00001111; // number of pixels for this particular color
									
									// The width of each pixel is times 2 for these graphics
									for (int p = 0; p < numPixels*2; p++) {
										
										int x = col + p;
										int y = row;

										[bitmap setColor: pixelColor atX: x y: y];
									}
									
									col += (numPixels * 2);
								}
							}
                        	
                        	// TODO: Save the images as an animated GIF
                        	// Save the image
                        	NSString *imagePath = [NSString stringWithFormat:@"%@/export_views/%@_%d_%d.png", agiDir, key, i, k];
                        	NSData *data = [bitmap representationUsingType: NSPNGFileType properties: nil];
							[data writeToFile: imagePath atomically: NO];	
						}
					}
				}
				
				if (fclose(volFile) != 0) {
					perror("Error closing file");
				}
			}];

			// Open exportViewsDirPath in Finder
			[[NSWorkspace sharedWorkspace]openFile:exportViewsDirPath withApplication:@"Finder"];
			
		}
	
	} else {
		NSLog(@"Error: The file %@ does not exist.", dirFilePath);
	}
	
	[pool release];
	return 0;
}