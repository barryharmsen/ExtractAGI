/*
 *	export_object.m
 *
 *	Description: Reverse engineer the OBJECT file from an AGI Sierra game.
 *	             The results are saved into the file object.json
 * 	Author: Chad Armstrong (chad@edenwaith.com)
 *	Date: 8-9 July 2018
 *	To compile: gcc -w -framework Foundation export_object.m -o export_object
 *	To run: ./export_object path/to/OBJECT
 *
 *	The object file stores two bits of information about the inventory items used in an 
 *	AGI game. The starting room location and the name of the inventory item. It also has 
 *	a byte that determines the maximum number of animated objects.
 *
 *	Resources:
 *	- OBJECT specs: http://www.agidev.com/articles/agispec/agispecs-10.html#ss10.1
 *	- Reverse Engineering 80s Sierra AGI Games: https://www.youtube.com/watch?v=XWiR1qP8wp8
 *  
 *	Based off of code from:
 *	- https://github.com/barryharmsen/ExtractAGI/blob/master/export_object.py
 *	- http://www.agidev.com/articles/agispec/examples/otherdata/object.pas
 */

#import <Foundation/Foundation.h>

int main(int argc, char *argv[]) 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	const int encryption_key_length = 11;
	char encryption_key[encryption_key_length] = {65, 118, 105, 115, 32, 68, 117, 114, 103, 97, 110};  // In decimal this spells "Avis Durgan"
	int key_index = 0;
	FILE *fp;
	
	if (argc < 2) {
		printf("usage: %s path/to/OBJECT\n", argv[0]);
		return (EXIT_FAILURE);
	}
	
	if ((fp = fopen(argv[1], "r")) == NULL) {		
		fprintf(stderr, "Could not open input file %s\n", argv[1]);
		exit(EXIT_FAILURE);
	}
	
	// Retrieve the size of the file, and use that to size the storage array
	// Can also use fstat to get the file's size
	fseek(fp, 0L, SEEK_END);
	int file_size = ftell(fp);
	fseek(fp, 0L, SEEK_SET);
	
	int decrypted_contents[file_size];
	
	// Initialize the contents of the decrypted_contents array
	for (int i = 0; i < file_size; i++) {
		decrypted_contents[i] = 0;
	}
	
	int data = -1;
	int loop_index = 0;
	
	// Step 1: Decrypt the file by XOR-ing each byte against the encryption keys
	while (( data = getc(fp)) != EOF) {
		int decrypted_byte = data ^ encryption_key[key_index];
		decrypted_contents[loop_index] = decrypted_byte;
		
		loop_index++;
		key_index++;
		key_index = key_index % encryption_key_length;
	}	
	
	// Step 2: Sort and organize the object names
	
	// 	Byte  Meaning
	// 	----- -----------------------------------------------------------
	// 	 0-1  Offset of the start of inventory item names
	// 	  2   Maximum number of animated objects
	// 	----- -----------------------------------------------------------
	
	// Get two more bytes of data to determine the offset where the words begin
	int ls_byte = decrypted_contents[0];
	int ms_byte = decrypted_contents[1];
		
	// Determine the word group index
	int names_offset = ms_byte*256 + ls_byte + 3; // 3 is the offset for the first 3 bytes read
	int num_animated_objects = decrypted_contents[2]; // not currently used in this example
	
	// 	Following the first three bytes as a section containing a three byte entry for each 
	//	inventory item all of which conform to the following format:
	// 
	// 	 Byte  Meaning
	// 	----- -----------------------------------------------------------
	// 	 0-1  Offset of inventory item name i
	// 	  2   Starting room number for inventory item i or 255 carried
	// 	----- -----------------------------------------------------------
		
	NSMutableDictionary *objectsDictionary = [[NSMutableDictionary alloc] init];
	int decrypted_index = 3; // start at 3 since the first 3 bytes have already been read
	
	for (int i = 3; i < names_offset; i+=3) {
	
		ls_byte = decrypted_contents[decrypted_index];
		ms_byte = decrypted_contents[decrypted_index+1];
		
		int room_num = decrypted_contents[decrypted_index+2];
		int object_name_offset = ms_byte*256 + ls_byte + 3;
		int object_name_index = object_name_offset;
		
		decrypted_index += 3;
		
		NSMutableString *currentObject = [[NSMutableString alloc] init];
		
		while (decrypted_contents[object_name_index] > 0) {
			[currentObject appendFormat:@"%c", decrypted_contents[object_name_index]];
			object_name_index++;
		}
		
		NSString *key        = [NSString stringWithFormat:@"%d", (i-3)/3];
		NSNumber *roomNum    = [NSNumber numberWithInt: room_num];
		NSDictionary *object = @{@"name": [currentObject copy], @"room": roomNum};
		
		[objectsDictionary setObject: object forKey: key];
	}
	
	// Write dictionary contents to a file (JSON format)
	NSError *error = nil; 
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objectsDictionary 
                                                   options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys 
                                                     error:&error];
                                                     
	if (error != nil) {
		NSLog(@"Error creating JSON data: %@", [error localizedDescription]);
	} else {
		NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

		BOOL succeed = [jsonString writeToFile:@"object.json" atomically:YES encoding:NSUTF8StringEncoding error:&error];
		if (succeed == NO) {
			NSLog(@"Error saving file 'object.json': %@", [error localizedDescription]);
		} else {
			NSLog(@"Successfully created the file 'object.json'");
		}
	}
	
	fclose(fp);
	
	[pool release];
	return 0;
}