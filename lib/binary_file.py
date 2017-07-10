import struct


class file(object):

    def __init__(self, filename, **kwargs):

        self.filename = filename
        self.file = open(filename, 'rb')
        self.nibble = -1
        if 'seek' in kwargs:
            self.file.seek(kwargs.get('seek'), 0)


    def __enter__(self):
        return self


    def __exit__(self, *err):
        self.file.close()


    def get_bytes(self, count, **kwargs):

        if 'format' in kwargs:
            format = kwargs.get('format')
        else:
            format = 'B'

        result = struct.unpack(format, self.file.read(count))[0]

        if self.nibble >= 0:
            shifted_result = (self.nibble << ((count * 8) -4)) + (result >> 4)
            self.nibble = result & 0b00001111
            result = shifted_result

        return result


    def get_nibble(self):

        if self.nibble >= 0:
            result = self.nibble
            self.nibble = -1
        else:
            result = struct.unpack('B', self.file.read(1))[0]
            self.nibble = result & 0b00001111
            result = result >> 4

        return result


    def get_position(self):
        return self.file.tell()


    def seek(self, seek):
        self.file.seek(seek)
