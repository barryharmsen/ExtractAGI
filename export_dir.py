import struct
import json
import os

game = 'MH2'

dir_list = ['VIEW', 'PIC', 'LOG', 'SND']
dirs = {}


for dir in dir_list:

    dirs[dir] = {}
    
    dir_filename = "Original\\" + game + "\\" + dir + "DIR"
    dir_entries = os.path.getsize(dir_filename) / 3

    with open(dir_filename, 'rb') as d:
        for i in range(0, dir_entries):

            byte1 = struct.unpack('B', d.read(1))[0] 
            byte2 = struct.unpack('B', d.read(1))[0] 
            byte3 = struct.unpack('B', d.read(1))[0] 
            
            if byte1 != 255 and byte2 != 255 and byte3 != 255:
                vol = (byte1 & 0b11110000) >> 4 # 4 most sign. bits give vol file, unless F, then not exists
                offset = (byte1 & 0b00001111) << 16
                offset = offset + (byte2 << 8)
                offset = offset + byte3

                dirs[dir][i] = {}
                dirs[dir][i]['vol'] = vol
                dirs[dir][i]['offset'] = offset
                #dirs[dir][i]['byte1'] = byte1
                #dirs[dir][i]['byte2'] = byte2
                #dirs[dir][i]['byte3'] = byte3


with open("Exports\\" + game + '\\'+ game + '_dir.json', 'w') as outfile:
    json.dump(dirs, outfile)
    


  
