import struct
import json
import os
from PIL import Image

palette = [(0,0,0), (0,0, 160), (0, 255, 80), (0, 160, 160), (160, 0, 0), (128, 0, 160), (160, 80, 0), (160, 160, 160), (80, 80, 80), (80, 80, 255), (0, 255, 80), (80,255, 255), (255, 80, 80), (255, 80, 255), (255, 255, 80), (255, 255, 255)]
game = 'MG'

views = {}

with open('Exports\\' + game + '\\'+ game + '_dir.json') as dir_file:    
    view_dir = json.load(dir_file)

    for view_index in view_dir['VIEW']:
        view_offset = view_dir['VIEW'][view_index]['offset']
        view_vol = view_dir['VIEW'][view_index]['vol']

        filename = "Original\%s\VOL.%s" % (game, view_vol)

        with open(filename, 'rb') as v:
            v.seek(view_offset, 0)

            signature = struct.unpack('>H', v.read(2))[0]       # signature should be 0x1234

            if signature == int('0x1234', 16):

                views[view_index] = {}                          # Empty dictionary for view
                
                vol = struct.unpack('B', v.read(1))[0]          # Vol no, not sure why we need this
                reslen = struct.unpack('<H', v.read(2))[0]      # resource lenght, LO-HI

                v.seek(2, 1)
                no_of_loops = struct.unpack('B', v.read(1))[0]  # Number of loops in view
                desc_pos = struct.unpack('<H', v.read(2))[0]    # Position of description    


                views[view_index]['no_of_loops'] = no_of_loops
                views[view_index]['size'] = reslen
                views[view_index]['vol'] = vol
                views[view_index]['loops'] = {}
            
                for i in range(0, no_of_loops):                 # Get loop positions
                    loop_pos = struct.unpack('<H', v.read(2))[0] + view_offset + 5 # 5 = length of view header
                    views[view_index]['loops'][i] = {}
                    views[view_index]['loops'][i]['pos'] = loop_pos
                    


                for loop in views[view_index]['loops']:         # Get cells for each loop
                    loop_offset = views[view_index]['loops'][loop]['pos'] 
                    v.seek(loop_offset, 0)
                    
                    no_of_cells = struct.unpack('B', v.read(1))[0]
                    views[view_index]['loops'][loop]['no_of_cells'] = no_of_cells
                    views[view_index]['loops'][loop]['cells'] = {}

                    for i in range(0, no_of_cells):

                        loop_pos = struct.unpack('<H', v.read(2))[0] + loop_offset
                        
                        views[view_index]['loops'][loop]['cells'][i] = {}
                        views[view_index]['loops'][loop]['cells'][i]['pos'] = loop_pos


                    for cell in views[view_index]['loops'][loop]['cells']:
                        cell_offset = views[view_index]['loops'][loop]['cells'][cell]['pos']

                        v.seek(cell_offset, 0)
                        cell_width = struct.unpack('B', v.read(1))[0]
                        cell_height = struct.unpack('B', v.read(1))[0]
                        cell_settings = struct.unpack('B', v.read(1))[0]

                        cell_mirroring = cell_settings >> 4
                        cell_transparency = cell_settings & 0b00001111

                        views[view_index]['loops'][loop]['cells'][cell]['width'] = cell_width
                        views[view_index]['loops'][loop]['cells'][cell]['height'] = cell_height
                        views[view_index]['loops'][loop]['cells'][cell]['mirroring'] = cell_mirroring
                        views[view_index]['loops'][loop]['cells'][cell]['transparency'] = cell_transparency

                        cell_transparent_rgb = palette[cell_transparency] + (0,) # Add transparency
                        cell_image = [cell_transparent_rgb for x in range(2 * cell_width * cell_height)] # Double cell width, because 1 horizontal pixel should be rendered as 2
                        

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
                            if color == cell_transparency: # Assign transparent pallette color if matches cell transparency.
                                color_rgb = cell_transparent_rgb
                            else:
                                color_rgb = palette[color]
                            pixels = byte & 0b00001111

                            for p in range(0, (pixels * 2)):
                                cell_image[row * (cell_width * 2) + (col + p)] = color_rgb

                            col += (pixels * 2)


                        cell_filename = "%s_%s_%s.png" % (view_index, loop, cell)
                        img = Image.new('RGBA', ((cell_width * 2), cell_height))
                        img.putdata(cell_image)
                        img.save("Exports\\" + game + "\\VIEW\\" + cell_filename, "PNG")

                        views[view_index]['loops'][loop]['cells'][cell]['filename'] = cell_filename


with open("Exports\\" + game + '\\'+ game + '_VIEW.json', 'w') as outfile:
    json.dump(views, outfile)

                 



                    

                
                
                
                
                

            

            


            
            

        


