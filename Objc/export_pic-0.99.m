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
 *	- Version 1.0:  January 2019 - Initial release
 *
 *	Resources:
 *	- PICTURE specs: http://www.agidev.com/articles/agispec/agispecs-7.html
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_pic.py
 *	- http://www.agidev.com/articles/agispec/examples/picture/showpic.c
 *	- http://www.agidev.com/articles/agispec/examples/files/volx2.c
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h> // Used for NSBitmapImageRep

void drawLine(int x1, int y1, int x2, int y2, NSMutableArray *pictureArray, NSColor *color);
int lineRound(float coord, float direction);
void floodFill(int x, int y, NSMutableArray *imgDataArray, NSColor *color, NSArray *colorPalette);
void saveImage(NSArray *imgDataArray, NSString *filePath, int width, int height);

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
    						
	NSDictionary *actions = @{ @240: @"Change picture color and enable picture draw.",
							   @241: @"Disable picture draw.",
							   @242: @"Change priority color and enable priority draw.",
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
				
				NSMutableArray *pictureArray  = [NSMutableArray new];
				NSMutableArray *priorityArray = [NSMutableArray new];
			
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
					
// 					NSMutableArray *pictureArray  = [NSMutableArray new];
// 					NSMutableArray *priorityArray = [NSMutableArray new];
					
					for (int i = 0; i < lastIndex; i++) {
						// Set the default colors for the picture and priority arrays
						pictureArray[i]  = colorPalette[15];
						priorityArray[i] = colorPalette[4];
					}
					
					for (int i = 0; i < reslen; i++) {
					
						int byteVal = getc(volFile);
						// printf("\t byteVal:: %d ", byteVal);
						
						// An action is being set
						if (byteVal >= 240) { // Action values are from 240 - 255
						
							selectedAction = byteVal;
                            NSLog(@"New selectedAction:: %d (%x)", selectedAction, selectedAction);
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

							// Corner drawing (244 - y corner, 245 - x corner)
							// 244/0xF4 : Draw y corner
							else if (selectedAction == 244 || selectedAction == 245) {
							// else if (selectedAction == 244) {
							
								/*
								NSLog(@"Draw Y corner: %d ----------", byteVal);
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
								} else if (to_y == -1) {
									to_y = byteVal;
									
									if (pictureDrawEnabled == YES) {
										// temp blue color
										// NSColor *tempColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
										NSLog(@"  1. Draw Y Corner (%d, %d, %d, %d)", from_x, from_y, from_x, from_y);
										drawLine(from_x, from_y, from_x, to_y, pictureArray, pictureColor);
									}
								} else if (to_x == -1) {
									to_x = byteVal;
									to_y = from_y;
									
									if (pictureDrawEnabled == YES) {
										// temp blue color
										// NSColor *tempColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 1.0 alpha: 1.0];
										NSLog(@"  2. Draw Y Corner (%d, %d, %d, %d)", from_x, from_y, to_x, to_y);
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);
									}
								}
								*/
							
							
								NSLog(@"Draw %d corner: %d ----------", selectedAction, byteVal);
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
										// temp orange color
										// NSColor *tempColor = [NSColor colorWithCalibratedRed: 241.0/255.0 green: 151.0/255.0 blue: 55.0/255.0 alpha: 1.0];
										// drawLine(from_x, from_y, to_x, to_y, pictureArray, tempColor);
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);
										from_x = to_x;
										from_y = to_y;
									}
								}
								
							
							} 
							
							/*
							// 245/0xF5 : Draw x corner
							else if (selectedAction == 245) {
								NSLog(@"Draw X corner: %d ----------", byteVal);
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
								} else if (to_x == -1) {
									to_x = byteVal;
									// to_y = from_y; // the to and from y coordinates are the same here
									if (pictureDrawEnabled == YES) {
										// temp red color
										// NSColor *tempColor = [NSColor colorWithCalibratedRed: 255.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0];
										NSLog(@"  1. Draw X Corner (%d, %d, %d, %d)", from_x, from_y, to_x, from_y);
										drawLine(from_x, from_y, to_x, from_y, pictureArray, pictureColor);
									}
								} else if (to_y == -1) {
									to_x = from_x;
									to_y = byteVal;
									if (pictureDrawEnabled == YES) {
										// temp orange color
										// NSColor *tempColor = [NSColor colorWithCalibratedRed: 241.0/255.0 green: 151.0/255.0 blue: 55.0/255.0 alpha: 1.0];
										NSLog(@"  2. Draw X Corner (%d, %d, %d, %d)", from_x, from_y, to_x, to_y);
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);
									}
								}
							}
							*/
							
							// Absolute line (long lines)
							else if (selectedAction == 246) {
							
								if (from_x == -1) {
								
									from_x = byteVal;
									point_xy = 'x';
									
								} else if (from_y == -1) {
								
									from_y = byteVal;
									point_xy = 'y';
									
									if (pictureDrawEnabled == YES) {
										// Draw a single dot
										drawLine(from_x, from_y, from_x, from_y, pictureArray, pictureColor);	
									}
									
								} else if (to_x == -1) {
								
									to_x = byteVal;
									point_xy = 'x';
									
								} else if (to_y == -1) {
								
									to_y = byteVal;
									point_xy = 'y';
									
									// Draw line
									if (pictureDrawEnabled == YES) {
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);
									}
									
								} else if (point_xy == 'y') {
								
									from_x = to_x;
									to_x = byteVal;
									point_xy = 'x';
									
								} else if (point_xy == 'x') {
									
									from_y = to_y;
									to_y = byteVal;
									point_xy = 'y';
									
									// Draw line
									if (pictureDrawEnabled == YES) {
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);
									}
									
								}

							}
							
							// Relative line (short lines)
							else if (selectedAction == 247) {
							
								if (from_x == -1) {
									from_x = byteVal;
								} else if (from_y == -1) {
									from_y = byteVal;
									
									// It may be debatable whether or not to bother drawing here
									// unless this is just trying to draw the staring dot
									if (pictureDrawEnabled == YES) {
										drawLine(from_x, from_y, from_x, from_y, pictureArray, pictureColor);	
									}
								} else {

									if (!(byteVal & 0b00001000)) { // 0x08 = 0b00001000
										to_y = from_y + 1 * (byteVal & 0b0111); // 0x07 = 0b0111
									} else {
										to_y = from_y + -1 * (byteVal & 0b0111);
									}
									
									if (!(byteVal & 0b10000000)) {
										to_x = from_x + 1 * ((byteVal >> 4) & 0b0111);
									} else {
										to_x = from_x + -1 * ((byteVal >> 4) & 0b0111);
									}
									
									printf("Short line:: to_x: %d to_y: %d\n", to_x, to_y);
									
									if (pictureDrawEnabled == YES) {
										drawLine(from_x, from_y, to_x, to_y, pictureArray, pictureColor);	
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
										floodFill(from_x, from_y, pictureArray, pictureColor, colorPalette);
										from_x = -1;
										from_y = -1;
									}
								}

							}
							
							else {
								NSLog(@"Other selectedAction:: %d", selectedAction);
							}
						}
					}
				
				}
				
				// Save the file
				NSString *filePath = [NSString stringWithFormat:@"%@/export_pics/%@_pic.png", agiDir, key];
				saveImage(pictureArray, filePath, 160, 168);
			}];
			
			// Open exportPicsDirPath in Finder
			[[NSWorkspace sharedWorkspace]openFile:exportPicsDirPath withApplication:@"Finder"];
		}
	}
	
	[pool release];
	return 0;
}

#pragma mark - Drawing Subroutines

void drawLine(int x1, int y1, int x2, int y2, NSMutableArray *pictureArray, NSColor *color) {

	int height = y2 - y1;
	int width  = x2 - x1;
	float addX = 0.0;
	float addY = 0.0;
	
	if (height == 0) {
		addX = 0;
	} else {
		addX = (float)width / abs(height); 
	}
	
	if (width == 0) {
		addY = 0.0;
	} else {
		addY = (float)height / abs(width);
	}
	
	printf("drawLine:: (%d, %d, %d, %d) | Dim: (%d x %d) | Deltas: (%f, %f)\n", x1, y1, x2, y2, width, height, addX, addY);
	
	if (height == 0 && width == 0) {
	
		// Single pixel
		printf("Drawing a single pixel: (%d, %d, %d, %d)\n", x1, y1, x2, y2);
		pictureArray[y1 * 160 + x1] = color;
		
	} else {
	
		if (abs(width) > abs(height)) {
		
			float y = (float)y1;
			
			if (width == 0) {
				addX = 0;
			} else {
				addX = width/abs(width);
			}
			
			printf("Width: %d to %d (%f) \n", x1, x2, addX);
			
			for (float x=(float)x1; x!=x2; x+=addX) {
			 	// pset(round(x, addX), round(y, addY));
			 	pictureArray[lineRound(y, addY) * 160 + lineRound(x, addX)] = color;
			 	y+=addY;
			}
			
// 			if (addX < 0) {
// 				for (int x = x1; x > x2; x+= addX) {
// 					pictureArray[lineRound(y, addY) * 160 + lineRound(x, addX)] = color;
//                 	y += addY;
// 				}
// 			} else {
// 				for (int x = x1; x < x2; x+= addX) {
// 					pictureArray[lineRound(y, addY) * 160 + lineRound(x, addX)] = color;
//                 	y += addY;
// 				}
// 			}
			
			pictureArray[y2 * 160 + x2] = color;
			
		} else {
		
			float x = (float)x1;
			
			if (height == 0) {
				addY = 0;
			} else {
				addY = height / abs(height);
			}
			
			if (addY < 0) {
				// orange
				// color = [NSColor colorWithCalibratedRed: 241.0/255.0 green: 151.0/255.0 blue: 55.0/255.0 alpha: 1.0];
				for (int y = y1; y > y2; y+=addY) {
					pictureArray[lineRound(y, addY) * 160 + lineRound(x, addX)] = color;
					x += addX;
				}
			} else {
				// purple
				// color = [NSColor colorWithCalibratedRed: 136.0/255.0 green: 47.0/255.0 blue: 141.0/255.0 alpha: 1.0];
				for (int y = y1; y < y2; y+=addY) {
					pictureArray[lineRound(y, addY) * 160 + lineRound(x, addX)] = color;
					x += addX;
				}
			}
			
			pictureArray[y2 * 160 + x2] = color;
			
			printf("Height: %d to %d (%f)\n", y1, y2, addY);
		
		}
		
// 		if (abs(width) > abs(height)):
//             y = float(y1)
//             if width == 0:
//                 addX = 0
//             else:
//                 addX = width/abs(width)
// 
//             for x in range(x1, x2, addX):
//                 img[line_round(y, addY) * 160 + line_round(x, addX)] = color
//                 y += addY
// 
//             img[y2 * 160 + x2] = color
// 
//         else:
//             x = float(x1)
//             if height == 0:
//                 addY = 0
//             else:
//                 addY = height/abs(height)
// 
//             for y in range(y1, y2, addY):
//                 img[line_round(y, addY) * 160 + line_round(x, addX)] = color
//                 x += addX
// 
//             img[y2 * 160 + x2] = color
            
	} 
// 	 else {
// 		// Single pixel
// 		printf("Drawing a single pixel: (%d, %d, %d, %d)\n", x1, y1, x2, y2);
// 		pictureArray[y1 * 160 + x1] = color;
// 	}
}


// Round, to get correct coordinate for pixel

// Debating whether direction should be an int or float
int lineRound(float coord, float direction) {
	if (direction < 0.0) {
		if ((float)coord - (int)coord <= 0.501) {
			return (int)coord;
		} else {
			return (int)coord+1;
		}
	} else {
		if ((float)coord - (int)coord <= 0.499) {
			return (int)coord;
		} else {
			return (int)coord+1;
		}
	}
}

BOOL okToFill(int x, int y, NSColor *defaultColor)
{
//    if (!picDrawEnabled && !priDrawEnabled) return FALSE;
//    if (picColour == 15) return FALSE;
//    if (!priDrawEnabled) return (picGetPixel(x, y) == 15);
//    if (priDrawEnabled && !picDrawEnabled) return (priGetPixel(x, y) == 4);
//    return (picGetPixel(x, y) == 15);
//    
//    
//    imgDataArray[pointY * 160 + pointX] != colorPalette[15]
	return YES;
   
}

/*
 * Flood fill from the locations given. Arguments are given in groups of two bytes which 
 * give the coordinates of the location to start the fill at. If picture drawing is 
 * enabled then it flood fills from that location on the picture screen to all pixels 
 * locations that it can reach which are white in color. The boundary is given by any 
 * pixels which are not white.
 */
void floodFill(int x, int y, NSMutableArray *imgDataArray, NSColor *color, NSArray *colorPalette) {
	NSLog(@"Flood fill: (%d, %d)", x, y);
	
	// TODO: Re-implement
	// This is getting closer, but until the rest of the line drawing is fixed,
	// Do not implement this yet
	// return; // temp code
	
	if (color != colorPalette[15]) { // Hmmm....is this necessary?
	
		NSMutableArray *stack = [NSMutableArray new];
		
		// Add current x, y coordinates as a CGPoint to an array
		[stack addObject: [NSValue valueWithPoint:CGPointMake(x, y)]];
		
		// Loop while the array is not empty
		while ([stack count] > 0) {
			// Pop the last element from the array and then remove from the array
			CGPoint point = [[stack lastObject] pointValue]; // Or NSPoint?
			[stack removeLastObject];
			
			int pointX = (int)point.x;
			int pointY = (int)point.y;
			
			// if the imgDataArray[y * 160 + x] is != palette[15] color, continue
			// This is debateable...One example says that the color should be 15, another
			// one says it shouldn't be 15 to continue...
			if (imgDataArray[pointY * 160 + pointX] == colorPalette[15]) {
				// Set imgDataArray[y * 160 + x] to the given color
				imgDataArray[pointY * 160 + pointX] = color;
				printf("Set location %d to a new color\n", pointY*160+pointX);
				
				if (pointX < 159 && imgDataArray[pointY * 160 + pointX+1] == colorPalette[15]) {
					[stack addObject: [NSValue valueWithPoint:CGPointMake(pointX+1, pointY)]];
				}
		
				if (pointX > 0 && imgDataArray[pointY * 160 + pointX-1] == colorPalette[15]) {
					[stack addObject: [NSValue valueWithPoint:CGPointMake(pointX-1, pointY)]];
				}
		
				if (pointY < 167 && imgDataArray[(pointY+1) * 160 + pointX] == colorPalette[15]) {
					[stack addObject: [NSValue valueWithPoint:CGPointMake(pointX, pointY+1)]];
				}
		
				if (pointY > 0 && imgDataArray[(pointY-1) * 160 + pointX+1] == colorPalette[15]) {
					[stack addObject: [NSValue valueWithPoint:CGPointMake(pointX, pointY-1)]];
				}
			}
		}
	}
}


void saveImage(NSArray *imgDataArray, NSString *filePath, int width, int height) {

	int image_width = width * 2;
							
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
										   pixelsWide:image_width
										   pixelsHigh:height
										bitsPerSample:8
									  samplesPerPixel:4
											 hasAlpha:YES
											 isPlanar:NO
									   colorSpaceName:NSCalibratedRGBColorSpace
										   bytesPerRow:4 * image_width
										  bitsPerPixel:32];
										  
	long imageSize = width * height;
	
	for (int i = 0; i < imageSize; i++) {
		int x = (i % width)*2; // Need to double the width of the image from 160 to 320
		int y = i / width;
		NSColor *pixelColor = imgDataArray[i];
		
		[bitmap setColor:pixelColor atX:x y:y];
		[bitmap setColor:pixelColor atX:x+1 y:y];
	}

	NSData *data = [bitmap representationUsingType: NSPNGFileType properties: nil];
	
	if ([data writeToFile: filePath atomically: YES] == NO) {
		NSLog(@"There was an error saving to file %@", filePath);
	} else {
		NSLog(@"Saved to file %@", filePath);
	}
}