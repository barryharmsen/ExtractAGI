import json
import os
import glob
import winsound
from PIL import Image
from lib import binary_file



# Load configuration
with open("config.json", "r") as infile:
    config = json.load(infile)

game_name = config['game']

with open(config["exportDir"]["main"] + 'dir.json') as dir_file:
    snd_dir = json.load(dir_file)
    game_version = snd_dir['game_version']

    for snd_index in snd_dir['SND']:

        snd_offset = snd_dir['SND'][snd_index]['offset']
        if game_version == 3:
            snd_vol = '%sVOL.%s' % (game_name, snd_dir['SND'][snd_index]['vol'])
        else:
            snd_vol = 'VOL.%s' % snd_dir['SND'][snd_index]['vol']

        print 'Index: %s, Offset: %s, Vol: %s' % (snd_index,
                                                  snd_offset,
                                                  snd_vol)

        filename = '%s%s' % (config["sourceDir"], snd_vol)

        with binary_file.file(filename, seek=snd_offset) as v:
            snd_offset_v1 = v.get_bytes(2, format='<H')
            snd_offset_v2 = v.get_bytes(2, format='<H')
            snd_offset_n1 = v.get_bytes(2, format='<H')
            snd_offset_v3 = v.get_bytes(2, format='<H')

            print 'Voice 1: %s, voice 2: %s, voice 3: %s, noise: %s' % (snd_offset_v1, snd_offset_v2, snd_offset_v3, snd_offset_n1)

            v.seek(snd_offset_v1)

            byte = v.get_bytes(2, format='H')

            while byte != 65535:
                snd_duration = byte
                snd_freq_1 = v.get_bytes(1)
                snd_freq_2 = v.get_bytes(1)
                snd_att = v.get_bytes(1)

                snd_freq = 111860 / ((snd_freq_1 & 0b00111111) << 4) + (snd_freq_2 & 0b00001111)


                print 'Duration: %s (%s), Frequency: %s (%s)' % (snd_duration, "{0:b}".format(snd_duration), snd_freq, "{0:b}".format(snd_freq))
                winsound.Beep(snd_freq, snd_duration / 1000)

                byte = v.get_bytes(2, format='H')
                print byte
