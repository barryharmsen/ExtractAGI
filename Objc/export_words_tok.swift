#!/usr/bin/swift
import Foundation

// Data extension based off of the following code sample:
// https://stackoverflow.com/questions/26227702/converting-nsdata-to-integer-in-swift
extension Data {
    enum Endianness {
        case BigEndian
        case LittleEndian
    }
    
    func scanValue<T: FixedWidthInteger>(at index: Data.Index, endianess: Endianness) -> T {
        let number: T = self.subdata(in: index..<index + MemoryLayout<T>.size).withUnsafeBytes({ $0.pointee })
        switch endianess {
        case .BigEndian:
            return number.bigEndian
        case .LittleEndian:
            return number.littleEndian
        }
    }
}

func foo() {
	print("bar");
}

/*
 * export_words_tok.swift
 *
 * To compile: swiftc export_words_tok.swift -o export_words_tok
 * Reference: https://jblevins.org/log/swift
 * https://github.com/edenwaith/ExtractAGI
*/

let argCount = CommandLine.argc

if argCount < 2 {
	print("Usage: export_words_tok path/to/WORDS.TOK");
} else {
	let filePath = CommandLine.arguments[1]

	print("hello world! \(filePath)")
	if let fileHandle = FileHandle(forReadingAtPath: filePath) {
	
		//print("Offset = \(fileHandle.offsetInFile)")
		//fileHandle.seekToEndOfFile()
		//print("Offset = \(fileHandle.offsetInFile)")
		
		fileHandle.seek(toFileOffset: 1)
		print("Offset = \(fileHandle.offsetInFile)")
	
		
		// foo();
		
		let wordsOffsetData:Data = fileHandle.readData(ofLength: 1)
		let wordsOffsetString = NSString(data: wordsOffsetData, encoding: String.Encoding.utf8.rawValue)
		if let wordsOffset: Int = wordsOffsetString?.integerValue {
			// wordsOffset is printing 0, but it should be the number 62
			print("wordsOffsetData: \(wordsOffsetData) wordsOffsetString: \(wordsOffsetString) | wordsOffset: \(wordsOffset)")
		}
//		let wordOffset = wordsOffsetData.scanValue(at: 0, endianess: .BigEndian) as UInt64
//		print("wordOffset: \(wordOffset)")
//		fileHandle.seek(toFileOffset: wordOffset)
		
//		var previousWord = ""
//		var currentWord = ""
		
		/*
		while true {
		
			previousWord = currentWord
			currentWord = ""
			
			// Can a guard statement be used here?
			let buffer:Int = fileHandle.readData(ofLength: 1) 
			print("buffer: \(buffer)")
			
//			guard !chunk.isEmpty else {
//            	break
//        	}
	
			// This isn't getting called...need further testing...
			if buffer.count == 0 {
				print("Buffer is empty.  EOF")
				break
			}
			
			// Need to copy a given substring of the previous word to the current word
			if buffer <= previousWord.count {
				// [currentWord setString: [previousWord substringToIndex: data]];
			}
	
			var dataString = String(data: buffer, encoding: .utf8) ?? ""
			print("dataString: \(dataString)")
		}
		
		*/

		print("Closing file")
		fileHandle.closeFile()
		
	}
}

