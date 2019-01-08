/***************************************************************************
** picv3-v2.c
**
** A small program to convert AGI version 3 pictures to AGI version 2
** pictures so that they can be displayed using SHOWPIC.
**
** (c) Lance Ewing 1997
***************************************************************************/

#include <stdio.h>

#define  NORMAL     0
#define  ALTERNATE  1

void main(int argc, char **argv)
{
   FILE *v3File, *v2File;
   unsigned char data, oldData, outData;
   int mode = NORMAL;

   if (argc != 3) {
      printf("Usage:   picv2-v2 v3file v2file");
      exit(0);
   }

   if ((v3File = fopen(argv[1], "rb")) == NULL) {
      printf("Error opening picture file : %s\n", argv[1]);
      exit(0);
   }

   if ((v2File = fopen(argv[2], "wb")) == NULL) {
      printf("Error creating picture file : %s\n", argv[2]);
      exit(0);
   }


   while (!feof(v3File)) {

      data = fgetc(v3File);

      if (mode == ALTERNATE)
	 outData = ((data & 0xF0) >> 4) + ((oldData & 0x0F) << 4);
      else
	 outData = data;

      if ((outData == 0xF0) || (outData == 0xF2)) {
	 fputc(outData, v2File);
	 if (mode == NORMAL) {
	    data = fgetc(v3File);
	    fputc((data & 0xF0) >> 4, v2File);
	    mode = ALTERNATE;
	 }
	 else {
	    fputc((data & 0x0F), v2File);
	    mode = NORMAL;
	 }
      }
      else
	 fputc(outData, v2File);

      oldData = data;
   }

   fclose(v3File);
   fclose(v2File);
}