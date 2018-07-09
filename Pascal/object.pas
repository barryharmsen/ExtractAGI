{
  This program displays the contents of the OBJECT file

  It was written in Borland Pascal 7, but would probably
  compile under earlier versions.

  Written by Peter Kelly, ptrkelly@ozemail.com.au
}

program object1;
{reads and displays the AGI OBJECT file}

uses crt,dos;

const  encryption_key : array[1..11] of char=('A','v','i','s',chr(32),'D','u','r','g','a','n');

type string30 = string[30]; {string, max length = 30 bytes}

var i : integer;
    ch : char;
    DecryptedObjfile : array[0..3000] of byte; {max size of OBJECT is 3k}
    ObjectName : array[0..199] of string30; {max 200 objects=6k in memory}
    NumObjects : byte; {number of objects in the game}

procedure DecryptFile; {XOR the entire file with 'Avis Durgan'}
var curbyte : byte;
    objfile : file of byte;
begin
  assign(objfile,'OBJECT');
  reset(objfile);
  for i := 1 to FileSize(objfile) do {for each byte in the file}
    begin
      read(objfile,curbyte); {read byte from file}
      DecryptedObjfile[i-1] := curbyte XOR ord(encryption_key[i - (((i-1) div 11)*11)]); {get decrypted byte}
    end;
  close(objfile);
end;


procedure ReadObjectNames;
var lsbyte,msbyte: byte;
  objloc : word; {position of current object name}
  ObjnameStart : word; {the start of the first object name-no references past this point}
  RefPos : word; {current position in file of objname references}
  ObjnamePos : word; {current position in file of objnames}
  CurrentObject : byte;

begin
  CurrentObject := 0; {we start with object 0}
  lsbyte := DecryptedObjfile[0]; {work out where the object names start}
  msbyte := DecryptedObjfile[1];
  ObjnameStart := msbyte*256 + lsbyte + 3;
  RefPos := 3; {we are start with the 4th byte for references}
  repeat
  begin
    lsbyte := DecryptedObjfile[RefPos];   {work out location of object name}
    msbyte := DecryptedObjfile[RefPos+1];
    RefPos := RefPos + 3;
    {writeln(RefPos);}
    ObjnamePos := msbyte*256 + lsbyte + 3;
    ObjectName[CurrentObject] := '';
    repeat
    begin
      if DecryptedObjfile[ObjnamePos] > 0 then
        begin
          ObjectName[CurrentObject] := ObjectName[CurrentObject] + chr(DecryptedObjfile[ObjnamePos]);
          ObjnamePos := Objnamepos + 1;
        end;
    end; until DecryptedObjfile[ObjnamePos] = 0;
    CurrentObject := CurrentObject + 1;
  end; until RefPos >= ObjnameStart;
  NumObjects := CurrentObject - 1;
end;

procedure DisplayObjects;
var CurrentObject : byte;
    CurrentLine : byte;
begin
  CurrentLine := 1;
  clrscr;
  for CurrentObject := 0 to NumObjects - 1 do
    begin
      writeln('Object ',CurrentObject,': ',ObjectName[CurrentObject]);
      CurrentLine := CurrentLine + 1;
      if (CurrentLine = 25) and (CurrentObject < NumObjects-1) then
        begin
          write('***Press any key***');
          ch := readkey;
          clrscr;
          CurrentLine := 1;
        end;
    end;
  write('***Press any key***');
  ch := readkey;
end;

begin
  clrscr;
  DecryptFile; {reads the OBJECT file into memory and decrypts it by}
                {XORing every eleven bytes with 'Avis Durgan'}
  ReadObjectNames; {works out what the object names are, from the}
                     {decrypted data in memory}
  DisplayObjects; {display the list of objects on the screen}
end.