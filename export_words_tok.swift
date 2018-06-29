#!/usr/bin/swift
import Foundation

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
	
		let wordsOffset = fileHandle.readData(ofLength: 1)
		fileHandle.seek(toFileOffset: wordsOffset)
		
		var previousWord = ""
		var currentWord = ""
		
		while true {
		
			previousWord = currentWord
			currentWord = ""
			
			// Can a guard statement be used here?
			let buffer = fileHandle.readData(ofLength: 1) 
			print("buffer: \(buffer)")
			
//			guard !chunk.isEmpty else {
//            	break
//        	}
	
			// This isn't getting called...need further testing...
			if buffer.count == 0 {
				print("Buffer is empty.  EOF")
				break
			}
	
			var dataString = String(data: buffer, encoding: .utf8)
			print("dataString: \(dataString)")
		}

		print("Closing file")
		fileHandle.closeFile()
		
	}
}