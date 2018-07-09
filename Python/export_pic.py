import struct
import json
import os
from PIL import Image


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

palette = [(0, 0, 0), (0, 0, 160), (0, 128, 0), (0, 160, 160),
           (160, 0, 0), (128, 0, 160), (160, 80, 0), (160, 160, 160),
           (80, 80, 80), (80, 80, 255), (0, 255, 80), (80, 255, 255),
           (255, 80, 80), (255, 80, 255), (255, 255, 80), (255, 255, 255)]

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

pics = {}

intermediate_save = False

picture_color = palette[15]  # Picture draw color
picture_draw_enabled = False
priority_color = palette[4]  # Priority screen draw color
priority_draw_enabled = False
selected_action = 0


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
                img[line_round(y, addY) * 160 + line_round(x, addX)] = color
                y += addY

            img[y2 * 160 + x2] = color

        else:
            x = float(x1)
            if height == 0:
                addY = 0
            else:
                addY = height/abs(height)

            for y in range(y1, y2, addY):
                img[line_round(y, addY) * 160 + line_round(x, addX)] = color
                x += addX

            img[y2 * 160 + x2] = color

    # single pixel
    else:
        img[y1 * 160 + x1] = color


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


def flood_fill(x, y, picture, color):

    if color != palette[15]:  # Why would they use this fill command? CHECK!

        stack = [(x, y)]

        while len(stack) > 0:

            x, y = stack.pop()
            if picture[y * 160 + x] != palette[15]:
                continue

            picture[y * 160 + x] = color
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
    img.save(filename, "PNG")


with open(config["exportDir"]["main"] + 'dir.json') as dir_file:
    pic_dir = json.load(dir_file)

    for pic_index in pic_dir['PIC']:

        pic_offset = pic_dir['PIC'][pic_index]['offset']
        pic_vol = pic_dir['PIC'][pic_index]['vol']

        print 'Index: %s, Offset: %s, Vol: %s' % (pic_index,
                                                  pic_offset,
                                                  pic_vol)

        filename = config["sourceDir"] + "VOL.%s" % (pic_vol)

        with open(filename, 'rb') as v:
            v.seek(pic_offset, 0)

            # signature should be 0x1234
            signature = struct.unpack('>H', v.read(2))[0]

            if signature == int('0x1234', 16):

                # Empty dictionary for picture
                pics[pic_index] = {}
                # Vol no, not sure why we need this
                vol = struct.unpack('B', v.read(1))[0]
                # resource lenght, LO-HI
                reslen = struct.unpack('<H', v.read(2))[0]

                picture = [palette[15] for i in range(0, 160 * 168)]
                priority = [palette[4] for i in range(0, 160 * 168)]

                for i in range(0, reslen):

                    byte = struct.unpack('B', v.read(1))[0]

                    # print "%s - %s" % (byte, "{0:b}".format(byte))

                    if byte >= 240:
                        selected_action = byte

                        # print "%s: %s" % (i, actions[selected_action])

                        if intermediate_save:
                            fname = config["exportDir"]["pic"] + "%s_%s.png" \
                                    % (pic_index, i)
                            save_image(picture, fname, 160, 168)

                        # Enable picture draw
                        if selected_action == 240:
                            picture_draw_enabled = True
                        # Disable picture draw.
                        elif selected_action == 241:
                            picture_draw_enabled = False
                        # Enable priority draw.
                        elif selected_action == 242:
                            priority_draw_enabled = True
                        # Disable priority draw
                        elif selected_action == 243:
                            priority_draw_enabled = False

                        # Reset coordinates
                        from_x = -1
                        from_y = -1
                        to_x = -1
                        to_y = -1
                        point_xy = 'z'

                    else:
                        # Change picture colour.
                        if selected_action == 240:
                            picture_color = palette[byte]

                        # Change priority colour
                        elif selected_action == 242:
                            priority_color = palette[byte]

                        # Corner drawing
                        elif selected_action == 244 or selected_action == 245:
                            if from_x == -1:
                                from_x = byte
                            elif from_y == -1:
                                from_y = byte

                                # Determine starting direction based on action
                                if selected_action == 244:
                                    point_xy = 'y'
                                else:
                                    point_xy = 'x'

                            else:
                                if point_xy == 'y':
                                    to_x = from_x
                                    to_y = byte
                                    point_xy = 'x'
                                else:
                                    to_x = byte
                                    to_y = from_y
                                    point_xy = 'y'

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)
                                    from_x = to_x
                                    from_y = to_y

                        # Absolute line (long lines).
                        elif selected_action == 246:
                            if from_x == -1:
                                from_x = byte
                                point_xy = 'x'
                            elif from_y == -1:
                                from_y = byte
                                point_xy = 'y'

                                # Draw single dot
                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              from_x, from_y,
                                              picture, picture_color)

                            elif to_x == -1:
                                to_x = byte
                                point_xy = 'x'
                            elif to_y == -1:
                                to_y = byte
                                point_xy = 'y'
                                # Draw line

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)
                                # if priority_draw_enabled:
                                #    draw_line(from_x, from_y,
                                #              to_x, to_y,
                                #              priority, priority_color)

                            elif point_xy == 'y':
                                from_x = to_x
                                to_x = byte
                                point_xy = 'x'
                            elif point_xy == 'x':
                                from_y = to_y
                                to_y = byte
                                point_xy = 'y'
                                # Draw line

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)
                                # if priority_draw_enabled:
                                #    draw_line(from_x, from_y,
                                #              to_x, to_y,
                                #              priority, priority_color)

                        # Relative line (short lines).
                        elif selected_action == 247:
                            if from_x == -1:
                                from_x = byte
                            elif from_y == -1:
                                from_y = byte
                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              from_x, from_y,
                                              picture, picture_color)
                                # if priority_draw_enabled:
                                #    draw_line(from_x, from_y,
                                #              from_x, from_y,
                                #              priority, priority_color)
                            else:
                                to_y = from_y + (1 if not(byte & 0b00001000) else -1) * (byte & 0b0111)
                                to_x = from_x + (1 if not(byte & 0b10000000) else -1) * ((byte >> 4) & 0b0111)

                                # print "%s : (%s, %s) to (%s, %s)" % \
                                # ("{0:b}".format(byte), from_x, from_y, \
                                #                        to_x, to_y)

                                if picture_draw_enabled:
                                    draw_line(from_x, from_y,
                                              to_x, to_y,
                                              picture, picture_color)
                                # if priority_draw_enabled:
                                #    draw_line(from_x, from_y,
                                #              to_x, to_y,
                                #              priority, priority_color)

                                from_x = to_x
                                from_y = to_y

                        # Fill
                        elif selected_action == 248:
                            if from_x == -1:
                                from_x = byte
                            elif from_y == -1:
                                from_y = byte

                                if picture_draw_enabled:

                                    flood_fill(from_x, from_y,
                                               picture, picture_color)
                                    from_x = -1
                                    from_y = -1

                fname = config["exportDir"]["pic"] + "%s_pic.png" % (pic_index)
                save_image(picture, fname, 160, 168)
