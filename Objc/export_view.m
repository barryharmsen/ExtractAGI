/*
 *	export_view.m
 *
 *	Description: Export the VIEW sprite objects from the volume files and save out the images.
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 24-25 July 2018
 *	To compile: gcc -w -framework Foundation -framework AppKit export_view.m -o export_view
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
#import <AppKit/AppKit.h> // Used for NSBitmapImageRep

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
	
	/*
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
	*/
           					  
    NSArray *colorPalette = @[	[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 160.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 80.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 0.0 green: 160.0/255.0 blue: 160.0/255.0 alpha: 1.0], // Teal
								[NSColor colorWithCalibratedRed: 160.0/255.0 green: 0.0 blue: 0.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 128.0/255.0 green: 0.0 blue: 160.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 160.0/255.0 green: 80.0/255.0 blue: 0.0 alpha: 1.0], // Wood brown
								[NSColor colorWithCalibratedRed: 160.0/255.0 green: 160.0/255.0 blue: 160.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 80.0/255.0 green: 80.0/255.0 blue: 80.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 80.0/255.0 green: 80.0/255.0 blue: 1.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 0.0 green: 1.0 blue: 80.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 80.0/255.0 green: 1.0 blue: 1.0 alpha: 1.0], // Light blue
								[NSColor colorWithCalibratedRed: 1.0 green: 80.0/255.0 blue: 80.0/255.0 alpha: 1.0],
								[NSColor colorWithCalibratedRed: 1.0 green: 80.0/255.0 blue: 1.0 alpha: 1.0], // Light purple
								[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 80.0/255.0 alpha: 1.0], // Yellow
    							[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0] // White
    						];
	
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
						// Double-check on the 5 offset value.  
						// Supposedly 5 is the length of the view header
						int loop_offset = loop_offset2*256 + loop_offset1 + offset + 5;
						printf("\t view_offset: %d\n", loop_offset);
						// TODO: Save this offset so it can be accessed later
						// Save the offset for each loop for each view
						loop_offsets[i] = loop_offset;
					}
					
					// Gets cells for each loop
					for (int i = 0; i < numLoops; i++) {
					
						int loop_offset = loop_offsets[i];
						fseek(volFile, loop_offset, SEEK_SET);
						
						int num_cells = getc(volFile);
						printf("\t num_cells: %d\n", num_cells);
						// getc(volFile);
						
						int loop_positions[num_cells]; // = {0} // perhaps init this way
						
						for (int j = 0; j < num_cells; j++) {
						// loop_pos = struct.unpack('<H', v.read(2))[0] \
                                   + loop_offset
                        	int loop_pos1 = getc(volFile);
                        	int loop_pos2 = getc(volFile);
                            int loop_pos = loop_pos2*256 + loop_pos1 + loop_offset;
                            // printf("\t loop_pos: %d\n", loop_pos);
                            loop_positions[j] = loop_pos;
						}
						
// 						Byte  Meaning
// 						----- -----------------------------------------------------------
// 						  0   Width of cel (remember that AGI pixels are 2 normal EGA
// 							  pixels wide so a cel of width 12 is actually 24 pixels
// 							  wide on screen)
// 						  1   Height of cel
// 						  2   Transparency and cel mirroring
// 						----- -----------------------------------------------------------
						// Double-check that num_cells is still the right number of loops
						for (int k = 0; k < num_cells; k++) {
							int cel_offset = loop_positions[k];
							fseek(volFile, cel_offset, SEEK_SET);
							
							int cel_width = getc(volFile);
							int cel_height = getc(volFile);
							int cel_settings = getc(volFile);
							int cel_mirror = cel_settings >> 4;
							int cel_transparency = cel_settings & 0b00001111;
							
							printf("\t Cell %d: (%d x %d) %d %d %d\n", k, cel_width, cel_height, cel_settings, cel_mirror, cel_transparency);

							// TODO: Get the cell transparency color
							
							// Create the bitmap image from the image data
							// NSBitmapImageRep *bitmap = [NSBitmapImageRep initWithBitmapDataPlanes:pixelsWide:pixelsHigh:bitsPerSample:samplesPerPixel:hasAlpha:isPlanar:colorSpaceName:bitmapFormat:bytesPerRow:bitsPerPixel
							int image_width = cel_width * 2;
							
							NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                   pixelsWide:image_width
                                                                   pixelsHigh:cel_height
                                                                bitsPerSample:8
                                                              samplesPerPixel:4
                                                                     hasAlpha:YES
                                                                     isPlanar:NO
                                                               colorSpaceName:NSCalibratedRGBColorSpace // @"NSDeviceRGBColorSpace" // NSCalibratedRGBColorSpace
                                                                   bytesPerRow:4 * image_width
                                                                  bitsPerPixel:32];
							
							// Loop through the data to construct the image
							 
							int row = 0, col = 0;
							BOOL loopComplete = NO;
							printf("\t Starting to loop through the cel data: (%d x %d)\n", image_width, cel_height);
							while (loopComplete == NO) {
							// NSColor *pixelColor = [NSColor colorWithCalibratedRed: 1.0 green: 0.0 blue: 0.0 alpha: 1.0];
							// [bitmap setColor: pixelColor atX: x y: y];
							// [nsBitmapImageRepObj setPixel:zColourAry atX:x y:y];      
								int byte = getc(volFile);
								printf("\t byte: %d row: %d col: %d ", byte, row, col);
								if (byte == 0) { // End of row
									row++;
									col = 0;
									
									if (row >= cel_height) {
										loopComplete = YES;
										printf("\nLoop is complete\n");
										// break;
									}
								}
								
								if (loopComplete == NO) {
									int colorIndex = byte >> 4;
									
									// TODO: Implement
									// if the color == color_transparency
									
									
									
									if (colorIndex < 0) {
										colorIndex = 0;
									}
									
									if (colorIndex > 15) {
										colorIndex = 15;
									}
									
									NSColor *pixelColor = colorPalette[colorIndex]; //  palette[color];
									int numPixels = byte & 0b00001111; // number of pixels for this particular color
									
									printf("\t colorIndex: %d numPixels: %d \n", colorIndex, numPixels);
									
									// The width of each pixel is times 2 for these graphics
									for (int p = 0; p < numPixels*2; p++) {
									// cell_image[row * (cell_width * 2) + (col + p)] = color_rgb
										int y = row;
										int x = col + p;
										
										// NSColor *redColor = [NSColor colorWithCalibratedRed:1.0 green: 0.0 blue: 0.0 alpha: 1.0];
										[bitmap setColor: pixelColor atX: x y: y];
									}
									
									col += (numPixels * 2);
									
								}
							}
                        	
                        	// TODO: Create the export_views directory
                        	
                        	
                        	// Save the image
                        	NSString *imagePath = [NSString stringWithFormat:@"%@/export_views/%@_%d_%d.png", agiDir, key, i, k];
                        	NSLog(@"imagePath: %@", imagePath);
                        	
//                         	NSData *sRGBPNGData = [[bm bitmapImageRepByConvertingTosRGBColorSpace] PNGRepresentationAsProgressive:NO];
// [sRGBPNGData writeToFile:@"foo/bar.png" atomically:YES];

                        	NSData *data = [bitmap representationUsingType: NSPNGFileType properties: nil];
							[data writeToFile: imagePath atomically: NO];
							
                        	
						}
						
					
					}
					

				}
				
				
				if (fclose(volFile) != 0) {
					perror("Error closing file");
				}
				
			}];

		}
	
	} else {
		NSLog(@"Error: The file %@ does not exist.", dirFilePath);
	}
	
	[pool release];
	return 0;
}