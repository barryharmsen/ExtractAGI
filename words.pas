{
  This program displays the contents of the WORDS.TOK file

  It was written in Borland Pascal 7, but would probably
  compile under earlier versions.

  Written by Peter Kelly, ptrkelly@ozemail.com.au
}

program words;

uses crt,dos;

var ch : char;
    i,j : longint;

type Tdata = array[0..20000] of char;
     Tdataindex = array[1..2000] of byte;

var WordData : ^tdata;
    WordDataloc : word;
    WordIndex : array[0..10000] of word;
    NumWordBlocks : word;

procedure endprog;
begin
  dispose(WordData);
  halt;
end;

{------------------ WordBlock -----------------------------}
function WordBlock(blocknum:word) : string;
{function to handle read accesses to WordData}
var i : byte;
begin
  if WordIndex[blocknum]=0 then WordBlock := ''
  else
    for i := 0 to ord(WordData^[WordIndex[blocknum]]) do
      begin
        WordBlock[i] := WordData^[WordIndex[blocknum]+i];
      end;
end;

{------------------- SetWordBlock --------------------------}
procedure SetWordBlock(blocknum:word;data:string);
{function to handle write accesses to WordData}
var i : byte;
    current_char : char;
    current_char_str: string;
begin
  WordIndex[blocknum] := WordDataLoc;
  for i := 0 to length(data) do
    begin
      current_char_str := copy(data,i,1);
      WordData^[WordDataloc + i] := data[i];
    end;
  WordDataloc := WordDataLoc + length(data) + 1;
end;


{-------------------- ReadWords ----------------------------}
procedure ReadWords;
var  DataStart : word; {start of actual data in file}
     curbyte : byte;
     wordstok : file of byte;
     msbyte, lsbyte : byte;
     CurrentWord : string;
     PreviousWord : string;
     wordblocknum : word;
begin
  NumWordBlocks := 0;

  assign(wordstok,'WORDS.TOK');
  reset(wordstok);
  seek(wordstok,1);
  read(wordstok,lsbyte);
  DataStart := lsbyte;

  seek(wordstok,DataStart);
  CurrentWord := '';
  write('Reading words');
  repeat
  begin
    PreviousWord := CurrentWord;
    CurrentWord := '';
    read(wordstok,curbyte);

    CurrentWord := copy(PreviousWord,1,curbyte);
    repeat
    begin
      read(wordstok,curbyte);
      if (curbyte<$20) then
        begin
          CurrentWord := CurrentWord + chr(63 + 32 - curbyte);
        end
      else if curbyte=95 then
       begin
         CurrentWord := CurrentWord + ' ';
       end;
    end until curbyte >= $80;
    curbyte := curbyte - $80;
    CurrentWord := CurrentWord + chr(63 + 32 - curbyte);

    read(wordstok,msbyte);
    read(wordstok,lsbyte);
    wordblocknum := msbyte*256 + lsbyte;
    if wordblocknum > 10000 then wordblocknum := 0;
    if wordblocknum > NumWordBlocks then NumWordBlocks := WordBlockNum;
    if WordBlock(wordblocknum)='' then SetWordBlock(wordblocknum,CurrentWord)
      else SetWordBlock(wordblocknum,WordBlock(wordblocknum)+'|'+CurrentWord);
    write('.');
  end; until FilePos(wordstok)>FileSize(wordstok) - 2;

  close(wordstok);
end;

{--------------------- DisplayWords -------------------------------}
procedure DisplayWords;
var CurrentObject : byte;
    CurrentWordBlock : word;
    CurrentLine : byte;
begin
  CurrentLine := 1;
  clrscr;
  for CurrentWordBlock := 0 to NumWordBlocks do
    begin
      if Length(WordBlock(CurrentWordBlock)) > 0 then
      begin
        writeln(CurrentWordBlock,': ',WordBlock(CurrentWordBlock));
        CurrentLine := CurrentLine + (length(WordBlock(CurrentWordBlock)) div 80) + 1;
        if (CurrentLine >= 24) and (CurrentWordBlock < NumWordBlocks) then
          begin
            write('***Press any key***');
            ch := readkey;
            clrscr;
            CurrentLine := 1;
          end;
      end;
    end;
  write('***Press any key***');
  ch := readkey;
end;




begin
  new(WordData);
  WordDataLoc := 1;
  for i := 0 to 10000 do WordIndex[1] := 0;
  clrscr;

  ReadWords;
  DisplayWords;

  dispose(WordData);
end.



