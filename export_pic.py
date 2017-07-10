import json
import os
import glob
from PIL import Image
from lib import binary_file


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

game_name = config['game']

palette = [(0, 0, 0), (0, 0, 160), (0, 128, 0), (0, 160, 160),
           (160, 0, 0), (128, 0, 160), (160, 80, 0), (160, 160, 160),
           (80, 80, 80), (80, 80, 255), (0, 255, 80), (80, 255, 255),
           (255, 80, 80), (255, 80, 255), (255, 255, 80), (255, 255, 255)]

texture_start = [0, 24, 48, 196, 220, 101, 235, 72, 96, 189, 137, 4, 10, 244, 125,
                 109, 133, 176, 142, 149, 31, 34, 13, 223, 42, 120, 213, 115, 28,
                 180, 64, 161, 185, 60, 202, 88, 146, 52, 204, 206, 215, 66, 144,
                 15, 139, 127, 50, 237, 92, 157, 200, 153, 173, 78, 86, 166, 247,
                 104, 183, 37, 130, 55, 58, 81, 105, 38, 56, 82, 158, 154, 79, 167,
                 67, 16, 128, 238, 61, 89, 53, 207, 121, 116, 181, 162, 177, 150,
                 35, 224, 190, 5, 245, 110, 25, 197, 102, 73, 240, 209, 84, 169,
                 112, 75, 164, 226, 230, 229, 171, 228, 210, 170, 76, 227, 6, 111,
                 198, 74, 117, 163, 151, 225]

# Avoid having to do a lot of bit shifting later
texture_map = [0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
               1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
               0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0,
               0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0,
               0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0,
               0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1,
               0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0,
               0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0,
               0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
               1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0,
               0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,
               1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]


actions = {240: 'Change picture colour and enable picture draw.',
           241: 'Disable picture draw.',
           242: 'Change priority colour and enable priority draw.',
           243: 'Disable priority draw.',
           244: 'Draw a Y corner.',
           245: 'Draw an X corner.',
           246: 'Absolute line (long lines).',
           247: 'Relative line (short lines).',
           248: 'Fill.',
           249: 'Change pen size and style.',
           250: 'Plot with pen.',
           251: 'Unknown',
           252: 'Unknown',
           253: 'Unknown',
           254: 'Unknown',
           255: 'Unknown'}

# Load brushes
with open("brushes.json", "r") as infile:
    brushes = json.load(infile)


pics = {}

intermediate_save = True
overlay = Image.open('overlay_pic.png')

picture_color = palette[15]  # Picture draw color
picture_draw_enabled = False
priority_color = palette[4]  # Priority screen draw color
priority_draw_enabled = False
selected_action = 0


# Draw a single pixel on the screen
def draw_pixel(x, y, image, color):
    if (0 <= x <= 159) and (0 <= y <= 167):
        image[y * 160 + x] = color


# Draw a line from x1, y1 tot x2, y2
def draw_line(x1, y1, x2, y2, img, color):

    height = y2 - y1
    width = x2 - x1

    if height == 0:
        addX = 0
    else:
        addX = float(width) / abs(height)

    if width == 0:
        addY = 0
    else:
        addY = float(height) / abs(width)

    if not (height == 0 and width == 0):

        if (abs(width) > abs(height)):
            y = float(y1)
            if width == 0:
                addX = 0
            else:
                addX = width/abs(width)

            for x in range(x1, x2, addX):
                draw_pixel(line_round(x, addX), line_round(y, addY), img, color)
                y += addY

            draw_pixel(x2, y2, img, color)

        else:
            x = float(x1)
            if height == 0:
                addY = 0
            else:
                addY = height/abs(height)

            for y in range(y1, y2, addY):
                draw_pixel(line_round(x, addX), line_round(y, addY), img, color)
                x += addX

            draw_pixel(x2, y2, img, color)

    # single pixel
    else:
        draw_pixel(x1, y1, img, color)


# Plot with the brush
def draw_brush(center_x, center_y, picture, color, size, style, texture=-1):

    brush = brushes[style][str(size)]
    if texture >= 0:
        texture_index = texture_start[texture]
    else:
        texture_index = -1

    from_x = center_x - brush['center'][0]
    from_y = center_y - brush['center'][1]
    brush_shape = brush['bitmap']

    #print 'Left: (%s, %s), center: (%s, %s), style: %s, size: %s, shape: %s, color: %s, texture: %s, texture_index: %s' % (from_x, from_y, center_x, center_y, style, size, brush_shape, color, texture, texture_index)
    for y in range(len(brush_shape)):
        for x in range(len(brush_shape[y])):
            to_y = from_y + y
            to_x = from_x + x

            if brush_shape[y][x] == 1:
                if texture_index >= 0:
                    if texture_map[texture_index] == 1:
                        draw_pixel(to_x, to_y, picture, color)

                    texture_index = (texture_index + 1) % 254

                else:
                    draw_pixel(to_x, to_y, picture, color)


# Round, to get correct coordinate for pixel
def line_round(coord, direction):
    if direction < 0:
        if float(coord) - int(coord) <= 0.501:
            return int(coord)
        else:
            return (int(coord) + 1)
    else:
        if float(coord) - int(coord) <= 0.499:
            return int(coord)
        else:
            return (int(coord) + 1)

# Flood fill
def flood_fill(x, y, picture, color):

    if color != palette[15]:  # Why would they use this fill command? CHECK!

        stack = [(x, y)]

        while len(stack) > 0:

            x, y = stack.pop()
            if picture[y * 160 + x] != palette[15]:
                continue

            draw_pixel(x, y, picture, color)
            if x < 159:
                stack.append((x + 1, y))
            if x > 0:
                stack.append((x - 1, y))
            if y < 167:
                stack.append((x, y + 1))
            if y > 0:
                stack.append((x, y - 1))


def save_image(img_array, filename, width, height):
    img = Image.new('RGBA', (width, height))
    img.putdata(img_array)
    img = img.resize((width * 2 * config["imageScale"],
                      height * config["imageScale"]))
    #img.paste(im=overlay, box=(0, 0), mask=overlay)
    img.save(filename, "PNG")


with open(config["exportDir"]["main"] + 'dir.json') as dir_file:
    pic_dir = json.load(dir_file)
    game_version = pic_dir['game_version']

    for pic_index in pic_dir['PIC']:

        pic_offset = pic_dir['PIC'][pic_index]['offset']
        if game_version == 3:
            pic_vol = '%sVOL.%s' % (game_name, pic_dir['PIC'][pic_index]['vol'])
        else:
            pic_vol = 'VOL.%s' % pic_dir['PIC'][pic_index]['vol']

        print 'Index: %s, Offset: %s, Vol: %s' % (pic_index,
                                                  pic_offset,
                                                  pic_vol)

        filename = '%s%s' % (config["sourceDir"], pic_vol)


        with binary_file.file(filename, seek=pic_offset) as v:

            # signature should be 0x1234
            signature = v.get_bytes(2, format='>H')
            if signature == int('0x1234', 16):

                # Empty dictionary for picture
                pics[pic_index] = {}
                # Vol no, not sure why we need this
                vol = v.get_bytes(1)

                # resource lenght, LO-HI
                reslen = v.get_bytes(2, format='<H')

                res_compressed = False
                if game_version == 3:
                    reslen_compressed = v.get_bytes(2, format='<H')

                    print "Version3"

                    # Check if game resources are compressed
                    if reslen == reslen_compressed:
                        res_compressed = False
                    else:
                        res_compressed = True
                        reslen = reslen_compressed

                picture = [palette[15] for i in range(0, 160 * 168)]
                priority = [palette[4] for i in range(0, 160 * 168)]

                selected_action = 0
                brush_size = 0
                brush_style = 'circle'
                brush_solid = True

                # First byte should always be an action (value >= 240)
                selected_action = v.get_bytes(1)


                while v.get_position() < pic_offset + reslen:

                    if selected_action >= 240:

                        print "%s" % (actions[selected_action])

                        # Enable picture draw
                        if selected_action == 240:
                            picture_draw_enabled = True
                            picture_color = palette[v.get_nibble()] if res_compressed else palette[v.get_bytes(1)]
                            selected_action = v.get_bytes(1)

                        # Disable picture draw.
                        elif selected_action == 241:
                            picture_draw_enabled = False
                            selected_action = v.get_bytes(1)

                        # Enable priority draw.
                        elif selected_action == 242:
                            priority_draw_enabled = True
                            priority_color = palette[v.get_nibble()] if res_compressed else palette[v.get_bytes(1)]
                            selected_action = v.get_bytes(1)

                        # Disable priority draw
                        elif selected_action == 243:
                            priority_draw_enabled = False
                            selected_action = v.get_bytes(1)

                        # Corner drawing
                        elif selected_action == 244 or selected_action == 245:
                            from_x = v.get_bytes(1)
                            from_y = v.get_bytes(1)

                            if selected_action == 244:
                                line_direction = 'y'
                            else:
                                line_direction = 'x'

                            byte = v.get_bytes(1)

                            while byte < 240:
                                if line_direction == 'y':
                                    to_x = from_x
                                    to_y = byte
                                    line_direction = 'x'
                                else:
                                    to_x = byte
                                    to_y = from_y
                                    line_direction = 'y'

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)

                                byte = v.get_bytes(1)

                            selected_action = byte


                        # Absolute line (long lines).
                        elif selected_action == 246:

                            from_x = v.get_bytes(1)
                            from_y = v.get_bytes(1)

                            # Draw single dot
                            if picture_draw_enabled:
                                draw_line(from_x, from_y,
                                          from_x, from_y,
                                          picture, picture_color)

                            byte = v.get_bytes(1)

                            while byte < 240:
                                to_x = byte
                                to_y = v.get_bytes(1)

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)

                                from_x = to_x
                                from_y = to_y

                                byte = v.get_bytes(1)

                            selected_action = byte

                        # Relative line (short lines).
                        elif selected_action == 247:

                            from_x = v.get_bytes(1)
                            from_y = v.get_bytes(1)

                            if picture_draw_enabled:
                                draw_line(from_x, from_y,
                                          from_x, from_y,
                                          picture, picture_color)
                                # if priority_draw_enabled:
                                #    draw_line(from_x, from_y,
                                #              from_x, from_y,
                                #              priority, priority_color)

                            byte = v.get_bytes(1)

                            while byte < 240:
                                to_y = from_y + (1 if not(byte & 0b00001000) else -1) * (byte & 0b0111)
                                to_x = from_x + (1 if not(byte & 0b10000000) else -1) * ((byte >> 4) & 0b0111)

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)

                                from_x = to_x
                                from_y = to_y
                                byte = v.get_bytes(1)

                            selected_action = byte

                        # Fill
                        elif selected_action == 248:

                            byte = v.get_bytes(1)

                            while byte < 240:
                                from_x = byte
                                from_y = v.get_bytes(1)

                                if picture_draw_enabled:
                                    flood_fill(from_x, from_y,
                                               picture, picture_color)

                                byte = v.get_bytes(1)

                            selected_action = byte

                        # Set brush style
                        elif selected_action == 249:

                            byte = v.get_bytes(1)

                            while byte < 240:
                                brush_size = byte & 0b00000111
                                brush_style = 'rectangle' if ((byte & 0b00010000) >> 4) == 1 else 'circle'
                                brush_solid = True if ((byte & 0b00100000) >> 5) == 0 else False

                                print byte, brush_size, brush_style, brush_solid

                                byte = v.get_bytes(1)

                            selected_action = byte

                        # Plot with pen
                        elif selected_action == 250:

                            byte = v.get_bytes(1)

                            while byte < 240:
                                if brush_solid:
                                    to_x = byte
                                    to_y = v.get_bytes(1)
                                    if picture_draw_enabled:
                                        draw_brush(to_x, to_y, picture,
                                                   picture_color, brush_size,
                                                   brush_style)
                                else:
                                    texture = byte >> 1
                                    to_x = v.get_bytes(1)
                                    to_y = v.get_bytes(1)
                                    if picture_draw_enabled:
                                        draw_brush(to_x, to_y, picture,
                                                   picture_color, brush_size,
                                                   brush_style, texture=texture)

                                byte = v.get_bytes(1)

                            selected_action = byte

                        # Else
                        else:
                            byte = v.get_bytes(1)

                            while byte < 240:
                                print 'OTHER ACTION: %s' % byte
                                byte = v.get_bytes(1)

                            selected_action = byte

                    i = v.get_position()

                    if intermediate_save:
                        fname = "%s%s_VIEWDRAW_%s_%s.png" % (config["exportDir"]["pic"],
                                                        config["game"],
                                                        pic_index.zfill(3), str(i).zfill(6))

                        if picture_draw_enabled:
                            save_image(picture, fname, 160, 168)


                fname = "%s%s_VIEWDRAW_%s_%s.png" % (config["exportDir"]["pic"],
                                                config["game"],
                                                pic_index.zfill(3), str(i).zfill(6))


                save_image(picture, fname, 160, 168)

                print "Ended at %s" % i


                if intermediate_save:
                    mask = '%s%s_VIEWDRAW_%s_*.png' % (config["exportDir"]["pic"],
                                                       config["game"],
                                                       pic_index.zfill(3))
                    scale = '%sx%s' % ((320 * config["imageScale"]),
                                       (320 * config["imageScale"]))
                    output = '%s%s_VIEWDRAW_%s.gif' % (config["exportDir"]["pic"],
                                                       config["game"],
                                                       pic_index.zfill(3))
                    imagick = 'convert -distort Barrel "0.0 0.0 0.04 0.96" -delay 10 -loop 1 -layers OptimizePlus %s -scale %s %s' % (mask, scale, output)
                    os.system(imagick)
                    for filename in glob.glob(mask):
                        os.remove(filename)
