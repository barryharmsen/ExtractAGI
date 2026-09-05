import struct
import json
import os
from PIL import Image, ImageOps

# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

palette = [(0, 0, 0), (0, 0, 160), (0, 255, 80), (0, 160, 160),
           (160, 0, 0), (128, 0, 160), (160, 80, 0), (160, 160, 160),
           (80, 80, 80), (80, 80, 255), (0, 255, 80), (80, 255, 255),
           (255, 80, 80), (255, 80, 255), (255, 255, 80), (255, 255, 255)]

views = {}
views["views"] = {}
views["imageScale"] = config["imageScale"]

with open(config["exportDir"]["main"] + 'dir.json') as dir_file:
    view_dir = json.load(dir_file)

    for view_index in view_dir['VIEW']:
        view_offset = view_dir['VIEW'][view_index]['offset']
        view_vol = view_dir['VIEW'][view_index]['vol']

        filename = config["sourceDir"] + "VOL.%s" % (view_vol)

        with open(filename, 'rb') as v:
            v.seek(view_offset, 0)

            # signature should be 0x1234
            signature = struct.unpack('>H', v.read(2))[0]

            if signature == int('0x1234', 16):

                # Empty dictionary for view
                views["views"][view_index] = {}
                # Vol no, not sure why we need this
                vol = struct.unpack('B', v.read(1))[0]
                # resource lenght, LO-HI
                reslen = struct.unpack('<H', v.read(2))[0]

                v.seek(2, 1)
                # Number of loops in view
                no_of_loops = struct.unpack('B', v.read(1))[0]
                # Position of description
                desc_pos = struct.unpack('<H', v.read(2))[0]

                views["views"][view_index]['no_of_loops'] = no_of_loops
                views["views"][view_index]['size'] = reslen
                views["views"][view_index]['vol'] = vol
                views["views"][view_index]['loops'] = {}

                # Get loop positions
                for i in range(0, no_of_loops):
                    # 5 = length of view header
                    loop_pos = struct.unpack('<H', v.read(2))[0] \
                               + view_offset + 5
                    views["views"][view_index]['loops'][i] = {}
                    views["views"][view_index]['loops'][i]['pos'] = loop_pos

                # Get cells for each loop
                for loop in views["views"][view_index]['loops']:
                    loop_offset = views["views"][view_index]['loops'][loop]['pos']
                    v.seek(loop_offset, 0)

                    no_of_cells = struct.unpack('B', v.read(1))[0]
                    views["views"][view_index]['loops'][loop]['no_of_cells'] = no_of_cells
                    views["views"][view_index]['loops'][loop]['cells'] = {}

                    for i in range(0, no_of_cells):

                        loop_pos = struct.unpack('<H', v.read(2))[0] \
                                   + loop_offset

                        views["views"][view_index]['loops'][loop]['cells'][i] = {}
                        views["views"][view_index]['loops'][loop]['cells'][i]['pos'] = loop_pos

                    for cell in views["views"][view_index]['loops'][loop]['cells']:
                        cell_offset = views["views"][view_index]['loops'][loop]['cells'][cell]['pos']

                        v.seek(cell_offset, 0)
                        cell_width = struct.unpack('B', v.read(1))[0]
                        cell_height = struct.unpack('B', v.read(1))[0]
                        cell_settings = struct.unpack('B', v.read(1))[0]

                        cell_mirrored = (cell_settings >> 4) > 0
                        cell_mirrored_loop = (cell_settings >> 4) & 0b00000111
                        cell_transparency = cell_settings & 0b00001111

                        views["views"][view_index]['loops'][loop]['cells'][cell]['width'] = cell_width * 2 * config["imageScale"]
                        views["views"][view_index]['loops'][loop]['cells'][cell]['height'] = cell_height * config["imageScale"]
                        views["views"][view_index]['loops'][loop]['cells'][cell]['transparency'] = cell_transparency
                        views["views"][view_index]['loops'][loop]['cells'][cell]['mirrored'] = cell_mirrored
                        if cell_mirrored and loop != cell_mirrored_loop:
                            views["views"][view_index]['loops'][loop]['cells'][cell]['mirroredLoop'] = cell_mirrored_loop

                        # Add transparency
                        cell_transparent_rgb = palette[cell_transparency] + (0,)
                        # Double cell width, because 1 horizontal pixel should be rendered as 2
                        cell_image = [cell_transparent_rgb for x in range(2 * cell_width * cell_height)]

                        row = 0
                        col = 0

                        while True:

                            byte = struct.unpack('B', v.read(1))[0]

                            # If 0 byte, go to next row
                            if byte == 0:
                                row += 1
                                col = 0
                                if row >= cell_height:
                                    break

                            color = byte >> 4
                            # Assign transparent pallette color
                            # if matches cell transparency.
                            if color == cell_transparency:
                                color_rgb = cell_transparent_rgb
                            else:
                                color_rgb = palette[color]
                            pixels = byte & 0b00001111

                            for p in range(0, (pixels * 2)):
                                cell_image[row * (cell_width * 2) + (col + p)] = color_rgb

                            col += (pixels * 2)

                        cell_filename = "%s_VIEW_%s_%s_%s.png" % (config['game'], view_index, loop, cell)
                        img = Image.new('RGBA', ((cell_width * 2), cell_height))
                        img.putdata(cell_image)
                        img = img.resize((cell_width * 2 * config["imageScale"],
                                          cell_height * config["imageScale"]))

                        # Flip image if it is mirrored from another loop
                        if cell_mirrored and loop != cell_mirrored_loop:
                            img = ImageOps.mirror(img)
                        img.save(config["exportDir"]["view"] + cell_filename, "PNG")

                        views["views"][view_index]['loops'][loop]['cells'][cell]['filename'] = cell_filename


with open(config["exportDir"]["main"] + 'view.json', 'w') as outfile:
    json.dump(views, outfile)
