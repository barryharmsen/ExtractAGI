import json
import os
import glob
from PIL import Image

gif_width = 500
gif_height = 500


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

with open(config["exportDir"]["main"] + 'view.json', 'r') as outfile:
    views = json.load(outfile)

overlay = Image.open('overlay.png')

for view in views['views']:
    print 'View: %s' % view

    for loop in views['views'][view]['loops']:

        max_width = 0
        max_height = 0

        cell_count = len(views['views'][view]['loops'][loop]['cells'])

        # Determine max height and width for view
        for cell in views['views'][view]['loops'][loop]['cells']:
            width = views['views'][view]['loops'][loop]['cells'][cell]['width']
            height = views['views'][view]['loops'][loop]['cells'][cell]['height']

            if width > max_width:
                max_width = width

            if height > max_height:
                max_height = height

        print "Loop: %s, Cell Count: %s, Max Width: %s, Max Height: %s" % (loop, cell_count, max_width, max_height)
        image_stitch = Image.new('RGBA', (max_width * cell_count, max_height), (0, 0, 0, 0))

        image_map_filename = '%s%s_SPRITEMAP_%s_%s.png' % (config["exportDir"]["view"], config['game'], view, loop)
        image_gif_filename = '%s%s_ANIM_%s_%s.gif' % (config["exportDir"]["view"], config['game'],  view, loop)
        image_gif_frame_root = '%s%s_FRAME_%s_%s' % (config["exportDir"]["view"], config['game'], view, loop)


        # Stitch images together
        for cell in views['views'][view]['loops'][loop]['cells']:
            image_file = '%s%s' % (config["exportDir"]["view"], views['views'][view]['loops'][loop]['cells'][cell]['filename'])
            height = views['views'][view]['loops'][loop]['cells'][cell]['height']
            image = Image.open(image_file)
            left = max_width * int(cell)
            top = max_height - height

            image_stitch.paste(im=image, box=(left, top))

            if cell_count > 1:
                # Create animated gif (shitty implementation, but works for now)
                image_frame = Image.new('RGB', (max_width + 20, max_height + 20), (220, 220, 220))
                #image_frame = Image.new('RGB', (gif_width, gif_height), (240, 240, 240))
                paste_left = int((gif_width - max_width) / 2)
                paste_top = int((gif_height - max_height) / 2) + top

                image_frame.paste(im=image, box=(10, top + 10), mask=image)
                #image_frame.paste(im=image, box=(paste_left, paste_top), mask=image)
                #image_frame.paste(im=overlay, box=(0,0), mask=overlay)
                image_frame_filename = '%s_%s.png' % (image_gif_frame_root, cell.zfill(3))
                image_frame.save(image_frame_filename, 'PNG')

        # Save image map
        image_stitch.save(image_map_filename, 'PNG')

        if cell_count > 1:
            # Create moving GIF
            mask = '%s_*.png' % (image_gif_frame_root)
            #scale = '%sx%s' % (max_width + 20, max_height + 20)
            scale = '%sx%s' % (gif_width, gif_height)
            #imagick = 'convert -virtual-pixel transparent +distort Perspective "0,0 0,0 400,0 400,22 400,300 400,320, 0,300 0,300" -delay 15 -loop 0 %s -scale %s %s' % (mask, scale, image_gif_filename)
            imagick = 'convert -delay 15 -loop 0 %s -scale %s %s' % (mask, scale, image_gif_filename)

            os.system(imagick)
            for filename in glob.glob(mask):
                os.remove(filename)
