import struct
import json

game = 'DEMO'

words = {}

with open("Original\\" + game + "\WORDS.TOK", "rb") as w:
    
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
            
            byte = struct.unpack('B', b)[0]

            if byte < 32:
                CurrentWord = CurrentWord + chr(byte ^ 127)
            elif byte > 127:
                CurrentWord = CurrentWord + chr((byte - 128) ^127)
                break
            elif byte == 95:
                CurrentWord = CurrentWord + ' '

        # Get word number
        b = w.read(2)
        if not b:
            break
        wordno = struct.unpack('>H', b)[0]

        if wordno in words:
            words[wordno].append(CurrentWord)
        else:
            words[wordno] = []
            words[wordno].append(CurrentWord)


with open("exports\\" + game + '\\' + game + '_words.json', 'w') as outfile:
    json.dump(words, outfile)
