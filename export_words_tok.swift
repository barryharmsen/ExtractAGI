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
	
		print("Offset = \(fileHandle.offsetInFile)")
		fileHandle.seekToEndOfFile()
		print("Offset = \(fileHandle.offsetInFile)")
		fileHandle.seek(toFileOffset: 52)
		print("Offset = \(fileHandle.offsetInFile)")
	
		//var previousWord = ""
		//var currentWord = ""
		
		let buffer = fileHandle.readData(ofLength: 1) 
		print("buffer: \(buffer)")
	
		// This isn't getting called...need further testing...
		if buffer.count == 0 {
			print("Buffer is empty.  EOF")
		}
	
		var dataString = String(data: buffer, encoding: .utf8)
		print("dataString: \(dataString)")

		print("Closing file")
		fileHandle.closeFile()
		
	}
}