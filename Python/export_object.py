import struct
import json
import os

# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

key = [65, 118, 105, 115, 32, 68, 117, 114, 103, 97, 110]  # Avis Durgan
key_index = 0

objects = {}

with open(config["sourceDir"] + "OBJECT", "rb") as w:
    with open("temp/OBJECT_DECRYPT", "wb") as d:

        while True:

            b = w.read(1)

            if not b:
                break

            byte = struct.unpack('B', b)[0] ^ key[key_index]

            key_index += 1
            key_index = key_index % len(key)

            d.write(struct.pack('B', byte))


with open("Temp/OBJECT_DECRYPT", "rb") as w:

    b = w.read(2)
    # Offset of start of inventory names
    offset_names = struct.unpack('<H', b)[0]

    b = w.read(1)
    # Maximum number of animated objects (whatever that is)
    max_animated = struct.unpack('B', b)[0]

    for i in range(3, offset_names + 1, 3):

        object_id = (i / 3) - 1
        objects[object_id] = {}

        w.seek(i, 0)
        b = w.read(2)
        # Offset of object name, offset starts at entry for object 0,
        # not at start of file
        object_offset = struct.unpack('<H', b)[0] + 3
        b = w.read(1)
        # Starting room of object
        object_room = struct.unpack('B', b)[0]
        objects[object_id]['room'] = object_room
        w.seek(object_offset, 0)

        # print "%s: Object: %s, Offset: %s, Room: %s" %
        # (i, object_id, object_offset, object_room)
        object_name = ''

        while True:
            b = w.read(1)
            byte = struct.unpack('B', b)[0]

            if byte != 0:
                object_name = object_name + chr(byte)
            else:
                # print object_name
                break

        objects[object_id]['name'] = object_name


with open(config["exportDir"]["main"] + 'objects.json', 'w') as outfile:
    json.dump(objects, outfile)
    os.remove("Temp/OBJECT_DECRYPT")
