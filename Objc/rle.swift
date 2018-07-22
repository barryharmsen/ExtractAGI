#!/usr/bin/swift
import Foundation

/*
 * rle.swift
 *
 * Author: Chad Armstrong
 * Date: 21 July 2018
 * Description: Example of encoding a string using Run Length Encoding
 * Example: The string aabbbaaaac will be encoded as 2a3b4a1c
 *
 * To compile: swiftc rle.swift -o rle
 * To run: ./rle string_to_encode
 *
 * References:
 * - https://en.wikipedia.org/wiki/Run-length_encoding
 * - https://www.prepressure.com/library/compression-algorithm/rle
 * - https://www.geeksforgeeks.org/run-length-encoding/
*/

let argCount = CommandLine.argc

if argCount < 2 {
	print("usage: ./rle string_to_encode");
} else {

	let stringToEncode = CommandLine.arguments[1]
	let charactersArray = Array(stringToEncode)
	let charactersArrayLength:Int = charactersArray.count
	var encodedString:String = ""	
	var index: Int = 0

	print("stringToEncode: \(stringToEncode)")

	while index < charactersArrayLength {
		// print("\(charactersArray[index])")
		let initialCharacter = charactersArray[index]
		var characterCounter: Int = 1
	
		while index+1 < charactersArrayLength && charactersArray[index] == charactersArray[index+1] {
			characterCounter += 1
			index += 1
		}
	
		let result = "\(characterCounter)\(initialCharacter)"
		encodedString.append(result)
		index += 1
	}
	
	print("encodedString:  \(encodedString)")
}