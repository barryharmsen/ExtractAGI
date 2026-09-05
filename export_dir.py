import struct
import json
import os


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)


game = config["game"]
source_dir = config["sourceDir"]
resources = {}

# Check if v2 or v3 directory format
# V3 had single DIR file, v2 has separate files for LOG, PIC, VIEW, SND
if os.path.isfile(source_dir + game + 'DIR'):
    game_version = 3
    resource_filename = '%s%sDIR' % (source_dir, game)

    # Get header from first 8 bytes, gives offset for each dir (LOG, PIC, VIEW, SND)
    # Byte 0 1 2 3 4 5 6 7
    #      L L P P V V S S
    with open(resource_filename, 'rb') as d:

        # Empty array to store the offsets
        offsets = []
        for offset in range(0, 4):
            # Read two bytes and add offset to array
            offsets.append(struct.unpack('<H', d.read(2))[0])
        # Append the filesize, this is the same as EOF and therefore the final offset
        offsets.append(int(os.path.getsize(resource_filename)))


        for dir in [('LOG', 0), ('PIC', 1), ('VIEW', 2), ('SND', 3)]:
            resources[dir[0]] = {}
            resources[dir[0]]['filename'] = resource_filename
            resources[dir[0]]['offset'] = offsets[dir[1]]
            resources[dir[0]]['entries'] = (offsets[dir[1]+1] - offsets[dir[1]]) / 3

# V2 game
else:
    game_version = 2
    dir_list = ['VIEW', 'PIC', 'LOG', 'SND']
    for dir in dir_list:
        resource_filename = '%s%sDIR' % (source_dir, dir)
        if os.path.isfile(resource_filename):
            resources[dir] = {}
            resources[dir]['filename'] = resource_filename
            resources[dir]['offset'] = 0
            resources[dir]['entries'] = int(os.path.getsize(resource_filename) / 3)


dirs = {}
dirs['game_version'] = game_version



for resource_type in resources:
    dir_filename = resources[resource_type]['filename']
    dir_offset = resources[resource_type]['offset']
    dir_entries = resources[resource_type]['entries']
    dirs[resource_type] = {}

    with open(dir_filename, 'rb') as d:
        d.seek(dir_offset)
        for i in range(0, dir_entries):
            byte1 = struct.unpack('B', d.read(1))[0]
            byte2 = struct.unpack('B', d.read(1))[0]
            byte3 = struct.unpack('B', d.read(1))[0]

            if byte1 != 255 and byte2 != 255 and byte3 != 255:
                # 4 most sign. bits give vol file, unless F, then not exists
                vol = (byte1 & 0b11110000) >> 4
                offset = (byte1 & 0b00001111) << 16
                offset = offset + (byte2 << 8)
                offset = offset + byte3

                dirs[resource_type][i] = {}
                dirs[resource_type][i]['vol'] = vol
                dirs[resource_type][i]['offset'] = offset


with open(config["exportDir"]["main"] + 'dir.json', 'w') as outfile:
    json.dump(dirs, outfile)
