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

// void drawLine(int x1, int y1, int x2, int y2, NSBitmapRep *img, NSColor *color);
// void lineRound(coord, direction); // TODO: Figure out parameter types
// void floodFill(int x, int y, NSBitmapRep *picture, NSColor *color);
// void saveImage(NSArray *imgArray, NSString *filename, int width, intheight);

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
    						
	NSDictionary *actions = @{ @240: @"Change picture colour and enable picture draw.",
							   @241: @"Disable picture draw.",
							   @242: @"Change priority colour and enable priority draw.",
							   @243: @"Disable priority draw.",
							   @244: @"Draw a Y corner.",
							   @245: @"Draw an X corner.",
							   @246: @"Absolute line (long lines).",
							   @247: @"Relative line (short lines).",
							   @248: @"Fill.",
							   @249: @"Change pen size and style.",
							   @250: @"Plot with pen.",
							   @251: @"Unknown",
							   @252: @"Unknown",
							   @253: @"Unknown",
							   @254: @"Unknown",
							   @255: @"Unknown"};
							   
	
// 	NSMutableDictionary *pics = [NSMutableDictionary new];
// 	BOOL intermediateSave = NO;
// 	NSColor *pictureColor = colorPalette[15]; // Picture draw color
// 	BOOL pictureDrawEnabled = NO;
// 	NSColor *priorityColor = colorPalette[4]; // Priority screen draw color
// 	BOOL priorityDrawEnabled = NO;
// 	int selectedAction = 0;
	
	// The export_dir program needs to be run first so the dir.json file exists which contains the
	// data where each of the views are stored on each of the volume files.
	if ([fm fileExistsAtPath: dirFilePath] == YES) {
		// 1. Get the set of PICTUREs and their offsets from dir.json
		NSData *data = [NSData dataWithContentsOfFile:dirFilePath];
		NSDictionary *dirDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
		NSDictionary *picDictionaries = dirDict[@"PICDIR"];
		
		if (picDictionaries != nil) {
			// NSLog(@"picDictionaries:: %@", picDictionaries);
			
			// Create the export_pics directory
			NSString *exportPicsDirPath = [NSString stringWithFormat:@"%@/export_pics", agiDir];
			BOOL isDir = NO;
			
			if ([fm fileExistsAtPath: exportPicsDirPath isDirectory:&isDir] == NO) {
				NSError *error = nil;
				if ([fm createDirectoryAtPath: exportPicsDirPath withIntermediateDirectories:YES attributes: nil error:&error] == NO) {
					if (error != nil) {
						NSLog(@"Failure to create directory at %@ ()", exportPicsDirPath, [error localizedDescription]);
					}
				}
			}
			
			/*
			// A dictionary key-value pair
			32 =         {
            	offset = 121023;
            	vol = 1;
        	};
        	*/
			
			[picDictionaries enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *value, BOOL *stop) {
			
				NSMutableDictionary *pics = [NSMutableDictionary new];
				BOOL intermediateSave = NO;
				NSColor *pictureColor = colorPalette[15]; // Picture draw color
				BOOL pictureDrawEnabled = NO;
				NSColor *priorityColor = colorPalette[4]; // Priority screen draw color
				BOOL priorityDrawEnabled = NO;
				int selectedAction = 0;
			
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
				
				// Big Endian : High - Low (big endian)
				int ms_byte = getc(volFile); // most significant byte
				int ls_byte = getc(volFile); // least significant byte
				long signature = (ms_byte << 8) + ls_byte; // left bit shift by 8, same as multiplying by 256
				// long signature = ms_byte*256 + ls_byte;
				
				int from_x = -1;
                int from_y = -1;
                int to_x = -1;
                int to_y = -1;
            	char point_xy = 'z';

				
				if (signature == 0x1234) {
				
					int volNum = getc(volFile); // Volume number, unused
					// Get reslen, Low - High (little endian)
					ls_byte = getc(volFile);
					ms_byte = getc(volFile);
					long reslen = ms_byte*256 + ls_byte;
					
					printf("reslen:: %d\n", reslen);
					
					int lastIndex = 160 * 168;
					
					NSMutableArray *pictureArray  = [NSMutableArray new];
					NSMutableArray *priorityArray = [NSMutableArray new];
					
					for (int i = 0; i < lastIndex; i++) {
						// Set the default colors for the picture and priority arrays
						pictureArray[i]  = colorPalette[15];
						priorityArray[i] = colorPalette[4];
					}
					
					for (int i = 0; i < reslen; i++) {
					
						int byteVal = getc(volFile);
						printf("\t byteVal:: %d ", byteVal);
						
						// An action is being set
						if (byteVal >= 240) { // Action values are from 240 - 255
						
							selectedAction = byteVal;
                            
							if (intermediateSave == YES) {
							// TODO: Complete this section
								// NSString *filename = 
								// saveImage(pictureArray, filename, 160, 168);
								
								//fname = config["exportDir"]["pic"] + "%s_%s.png" \
                                    % (pic_index, i)
                            	//save_image(picture, fname, 160, 168)
							}
							
							if (selectedAction == 240) {
								// Enable picture draw
								pictureDrawEnabled = YES;
							
							} else if (selectedAction == 241) {
								// Disable picture draw
								pictureDrawEnabled = NO;
							
							} else if (selectedAction == 242) {
								// Enable priority draw
								priorityDrawEnabled = YES;
							
							} else if (selectedAction == 243) {
								// Disable priority draw
								priorityDrawEnabled = NO;
							}

							// Reset coordinates
							from_x = -1;
							from_y = -1;
							to_x = -1;
							to_y = -1;
							point_xy = 'z';
							
							
						} else { // Perform on the selected action
						
							// Change picture color
                        	if (selectedAction == 240) {
                            	pictureColor = colorPalette[byteVal];
                        	}

                        	// Change priority color
                       		else if (selectedAction == 242) {
                            	priorityColor = colorPalette[byteVal];
                            }

							// Corner drawing
							else if (selectedAction == 244 || selectedAction == 245) {
							
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
									
									// Determine starting direction based on action
									if (selectedAction == 244) {
										point_xy = 'y';
									} else {
										point_xy = 'x';
									}
								} else { // from_x and from_y have been set
								
									if (point_xy == 'y') {
										to_x = from_x;
										to_y = byteVal;
										point_xy = 'x';
									} else {
										to_x = byteVal;
										to_y = from_y;
										point_xy = 'y';
									}
									
									if (pictureDrawEnabled == YES) {
										// TODO: Enable drawLine method
										// drawLine(from_x, from_y, to_x, to_y, picture, pictureColor);
										from_x = to_x;
										from_y = to_y;
									}
								}
							}
							
							// Absolute line (long lines)
							else if (selectedAction == 246) {
								if (from_x == -1) {
									from_x = byteVal;
									point_xy = 'x';
								} else if (from_y == -1) {
									from_y = byteVal;
									point_xy = 'y';
								}
							}
							
							// Relative line (short lines)
							else if (selectedAction == 247) {
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
									
									if (pictureDrawEnabled == YES) {
										// TODO: Enable drawLine
										// drawLine(from_x, from_y, from_x, from_y, picture, pictureColor);	
									}
								} else {

									if (!(byteVal & 0b00001000)) {
										to_y = from_y + 1 * (byteVal & 0b0111);
									} else {
										to_y = from_y + -1 * (byteVal & 0b0111);
									}
									
									if (!(byteVal & 0b10000000)) {
										to_x = from_x + 1 * ((byteVal >> 4) & 0b0111);
									} else {
										to_x = from_x + -1 * ((byteVal >> 4) & 0b0111);
									}
									printf("to_x: %d to_y: %d\n", to_x, to_y);
									if (pictureDrawEnabled == YES) {
										// TODO: Enable drawLine
										// drawLine(from_x, from_y, to_x, to_y, picture, pictureColor);	
									}
									
									from_x = to_x;
                                	from_y = to_y;
								}
							}
							
							// Fill
							else if (selectedAction == 248) {
							
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
									
									if (pictureDrawEnabled == YES) {
										// TODO: add the floodFill method
										// floodFill(from_x, from_y, picture, pictureColor);
										from_x = -1;
										from_y = -1;
									}
								}

							}
						}
					}
				
				}
				
			}];
			
		}
	}
	
	[pool release];
	return 0;
}