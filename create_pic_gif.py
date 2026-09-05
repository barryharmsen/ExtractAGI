import struct
import json
import os
from PIL import Image
from images2gif import writeGif


# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)


os.chdir(config["exportDir"]["pic"])

for filename in os.listdir("."):
    parts = filename.split('_')
    vol = parts[0].rjust(5, '0')
    sub = parts[1].split('.')[0].rjust(10, '0')
    filename_to = '%s_%s.png' % (vol, sub)
    os.rename(filename, filename_to)


#imgFiles = sorted((fn for fn in os.listdir('.') if fn.endswith('.png')))


#for i in range(0, len(imgFiles), 50):
#    imgBatch = imgFiles[i:i + 50]
#    images = [Image.open(fn) for fn in imgBatch]

#    filename = '%s_%s_pic.gif' % (config["game"], i)
#    writeGif(filename, images, duration=0.2)


