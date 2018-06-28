import struct
import json


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

words = {}

with open(config["sourceDir"] + "WORDS.TOK", "rb") as w:

    w.seek(52, 0)

    PreviousWord = ''
    CurrentWord = ''

    while True:

        PreviousWord = CurrentWord
        CurrentWord = ''

        b = w.read(1)

        # Break if EOF
        if not b:
            break

        byte = struct.unpack('B', b)[0]

        CurrentWord = PreviousWord[0:byte]

        # Get characters
        while True:
            b = w.read(1)

            if not b:
                break
                
			# Reference: https://docs.python.org/2/library/struct.html
            byte = struct.unpack('B', b)[0]

            if byte < 32:
                CurrentWord = CurrentWord + chr(byte ^ 127)
            elif byte > 127:
                CurrentWord = CurrentWord + chr((byte - 128) ^ 127)
                break # break out of this loop if the value is 128 or larger (0x80)
            elif byte == 95:
                CurrentWord = CurrentWord + ' '

        # Get word number
        b = w.read(2)
        if not b:
            break # if nothing else to read, break out of the outer loop
            
        # get the two bytes, but this is in big endian
        wordno = struct.unpack('>H', b)[0]

		# if the word number is already present, append the new word
        if wordno in words:
            words[wordno].append(CurrentWord)
        else: # otherwise, add the new entry
            words[wordno] = []
            words[wordno].append(CurrentWord)


with open(config["exportDir"]["main"] + 'words.json', 'w') as outfile:
    json.dump(words, outfile)
