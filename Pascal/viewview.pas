{
  This is the VIEW displaying section from AGIhack.
  It's a unit, but can be easily modified to run as a separate program.

  If you want to compile this, email me and I will send you the units
  col2564 and common. However, you can see it in operation in AGIhack 2.0.

  It was written in Borland Pascal 7, but would probably
  compile under earlier versions.

  Written by Peter Kelly, ptrkelly@ozemail.com.au
  http://www.agidev.com/articles/agispec/examples/view/viewview.pas
}

unit viewview;

interface

uses crt,dos,graph,col2564,common;

procedure RunViewView(ResData1:TData;ResName1:string);

implementation


type Tceldata = array[0..20000] of byte;

     Tcel  = record
              width       : byte;
              height      : byte;
              mirror      : boolean;
              transcol    : byte;
              data        : ^Tceldata;  {size of data = width * 2 * height + 6}
            end;

var VIEWfile            : file of byte;
    VIEWfilename        : string;
    FileLoc             : longint;
    srec                : searchrec;
    NumLoops            : byte;
    NumCels             : array[0..15] of byte;
    cel                 : array[0..15,0..15] of Tcel;
    ch                  : char;
    ResName             : string;
    Description         : string;
    DescPos             : word;
    LoopLoc          : array[0..15] of word;
    LoopOccur        : array[0..15] of byte;
    CelLoc           : array[0..15,0..15] of word;
    ResData          : TData;
    ResDataPos       : word;
    ResSize          : word;

{***********************************************************************}
function ReadResByte : byte;
{reads a byte from the resource stored in memory}
{***********************************************************************}
begin
  if ResDataPos <= ResSize - 1 then
  begin
    ReadResByte := ResData.Data^[ResDataPos];
    ResDataPos := ResDataPos + 1;
  end
  else ReadResByte := 0;
end;

{***********************************************************************}
function ReadResLSMSWord : word;
{reads a byte from the resource stored in memory}
{***********************************************************************}
begin
  if ResDataPos <= ResSize - 2 then
  begin
    ReadResLSMSWord := ResData.Data^[ResDataPos+1]*256 + ResData.Data^[ResDataPos];
    ResDataPos := ResDataPos + 2;
  end
  else ReadResLSMSWord := 0;
end;

{***********************************************************************}
procedure SeekRes(seekpos:word);
{seeks to a certain position in the resource stored in memory}
{***********************************************************************}
begin
  if (seekpos>=0) and (seekpos<=ResSize-1) then
  begin
    ResDataPos := seekpos;
  end;
end;

{***********************************************************************}
procedure LoadCel(loopno,celno:byte);
{***********************************************************************}
var celX,celY        : byte;
    ChunkLength      : byte;
    ChunkCol         : byte;
    width, height    : byte;
    curbyte          : byte;
    templine         : array[0..200] of byte;

begin
  Width := Cel[loopno,celno].Width;
  Height := Cel[loopno,celno].Height;
  SeekRes(LoopLoc[loopno]+CelLoc[loopno,celno]+3);
  GetMem(Cel[loopno,celno].data,6+Width*2*Height);
  GetImage(0,0,Width*2-1,Height-1,Cel[loopno,celno].data^);
  celX := 0;
  celY := 0;
  repeat
  begin
    curbyte := ReadResByte;
    if curbyte > 0 then
    begin
      ChunkCol := (curbyte AND $F0) div $10;
      ChunkLength := curbyte AND $0F;
      for celX := celX to celX + ChunkLength*2-1 do
      begin
        Cel[loopno,celno].data^[4+cely*Width*2+celX] := ChunkCol;
      end;
      celX := celX + 1
    end
    else
    begin
      for celX := celX to Width*2-1 do
      begin
        Cel[loopno,celno].data^[4+cely*Width*2+celX] := Cel[loopno,celno].TransCol;
      end;
      if (Cel[loopno,celno].Mirror) and (LoopOccur[loopno]=2) then
      begin
        for celX := 0 to Cel[loopno,celno].Width*2 - 1 do
          begin
            templine[celX] := Cel[loopno,celno].data^[4+cely*Width*2+(Cel[loopno,celno].Width*2-1-celX)];
          end;
        for celX := 0 to Cel[loopno,celno].Width*2 - 1 do
          begin
            Cel[loopno,celno].data^[4+cely*Width*2+celX] := templine[celX];
          end;
      end;
      celY := celY + 1;
      celX := 0;
    end;
  end; until celY = Cel[loopno,celno].Height;
end;

{***********************************************************************}
procedure DiscardCel(loopno,celno:byte);
{***********************************************************************}
begin
  FreeMem(cel[loopno,celno].data,cel[loopno,celno].width*2*cel[loopno,celno].height+6);
end;

{***********************************************************************}
procedure ReadViewInfo;
{***********************************************************************}
var CurLoop          : byte;
    CurCel           : byte;
    curbyte          : byte;
    i : byte;

begin
  NumLoops := 0;
  CurLoop := 0;
  CurCel := 0;
  SeekRes(2);
  NumLoops := ReadResByte;
  Description := '';
  DescPos := ReadResLSMSWord;
  if DescPos > 0 then
  begin
    SeekRes(DescPos);
    repeat
    begin
      curbyte := ReadResByte;
      Description := Description + char(curbyte);
    end; until curbyte = 0;
  end;
  SeekRes(FileLoc+5);
  for CurLoop := 0 to NumLoops - 1 do
  begin
    LoopLoc[CurLoop] := ReadResLSMSWord;
    LoopOccur[CurLoop] := 1;
    if CurLoop > 0 then
      for i := 0 to CurLoop - 1 do
        begin
          if LoopLoc[CurLoop] = LoopLoc[i] then
            LoopOccur[CurLoop] := LoopOccur[CurLoop] + 1;
        end;
        begin; end;
  end;
  for CurLoop := 0 to NumLoops - 1 do
  begin
    SeekRes(LoopLoc[CurLoop]);
    NumCels[CurLoop] := ReadResByte;
    for CurCel := 0 to NumCels[CurLoop]-1 do
    begin
      CelLoc[CurLoop,CurCel] := ReadResLSMSWord;
    end;
    for CurCel := 0 to NumCels[CurLoop]-1 do
    begin
      SeekRes(LoopLoc[CurLoop]+CelLoc[CurLoop,CurCel]);
      Cel[CurLoop,CurCel].Width := ReadResByte;
      Cel[CurLoop,CurCel].Height := ReadResByte;
      curbyte := ReadResByte;
      Cel[CurLoop,CurCel].TransCol := curbyte AND $0F;
      if curbyte >= $80 then Cel[CurLoop,CurCel].Mirror := TRUE
        else Cel[CurLoop,CurCel].Mirror := FALSE;
    end;
    SeekRes(LoopLoc[0]+CelLoc[0,0]);
    Cel[0,0].Width := ReadResByte;
    Cel[0,0].Height := ReadResByte;
    curbyte := ReadResByte;
  end;
end;

{***********************************************************************}
procedure DisplayView;
{***********************************************************************}
const CelOffsetX       : word = 0;
      CelOffsetY       : word = 8;

var CurLoop            : byte;
    CurCel             : byte;
    OldLoop            : byte;
    OldCel             : byte;
    FinishedViewing    : boolean;
    NumDescLines       : byte;
    DescLine           : array[1..16] of string[80];
    temp1, temp2 : string;

  procedure DrawCel;
  begin
    CelOffsetY := 16 + ((200-NumDescLines*8-16) div 2) + (Cel[0,0].Height div 2) - Cel[CurLoop,CurCel].Height;
    SetColor(17);
    Bar3D(CelOffsetX-1,CelOffsetY-1,CelOffsetX+Cel[CurLoop,CurCel].Width*2,CelOffsetY+Cel[CurLoop,CurCel].Height,0,false);
    PutImage(CelOffsetX,CelOffsetY,Cel[CurLoop,CurCel].data^,NormalPut);
    SetColor(15);
    OutTextXY(112,0,'Loop '+Byte2Str(CurLoop)+'/'+Byte2Str(NumLoops-1));
    OutTextXY(208,0,'Cel '+Byte2Str(CurCel)+'/'+Byte2Str(NumCels[CurLoop]-1));
    OutTextXY(0,8,'Transparency Color ');
    SetColor(17);
    SetFillStyle(SolidFill,Cel[CurLoop,CurCel].Transcol);
    Bar3D(152,8,159,15,0,true);
  end;

  procedure EraseOldCel;
  begin
    SetFillstyle(SolidFill,0);
    bar(112,0,319,7);
    bar(CelOffsetX-1,CelOffsetY-1,CelOffsetX+Cel[OldLoop,OldCel].Width*2,CelOffsetY+Cel[OldLoop,OldCel].Height);
  end;

  procedure ShowDescription;
  var CurDescLine : byte;
      CurCharNo   : word;
      EndLastLine : word;
      LineBreakPos : word;
      LinesAdded : boolean;
  begin
    for CurDescLine := 1 to 16 do
      DescLine[CurDescLine] := '';
    NumDescLines := 0;
    EndLastLine := 0;
    for CurDescLine := 1 to 16 do
      DescLine[CurDescLine] := '';
    repeat
    begin
      CurCharNo := EndLastLine + 1 + 40 - Length(DescLine[NumDescLines+1]);
      repeat
      begin
        CurCharNo := CurCharNo - 1;
      end; until (copy(Description,CurCharNo,1)=' ') or (CurCharNo = EndLastLine+1)
                 or (CurCharNo >= Length(Description));
      if CurCharNo = EndLastLine+1 then CurCharNo := EndLastLine + 1 + 40 - Length(DescLine[NumDescLines+1]);
      NumDescLines := NumDescLines + 1;
      DescLine[NumDescLines] := DescLine[NumDescLines] + copy(Description,EndLastLine+1,CurCharNo - EndLastLine);

      LinesAdded := FALSE;
      repeat
      begin
        if NumDescLines > 12 then halt;
        LineBreakPos := Pos(chr($0A),DescLine[NumDescLines]);
        if LineBreakPos > 0 then
        begin
          DescLine[NumDescLines+1] := copy(DescLine[NumDescLines],LineBreakPos+1,800);
          DescLine[NumDescLines] := copy(DescLine[NumDescLines],1,LineBreakPos-1);
          NumDescLines := NumDescLines + 1;
          LinesAdded := TRUE;
        end;
      end; until LineBreakPos = 0;
      if LinesAdded then NumDescLines := NumDescLines - 1;
      EndLastLine := CurCharNo;
    end; until CurCharNo >= Length(Description);
    for CurDescLine := 1 to NumDescLines do
    begin
      OutTextXY(0,200-NumDescLines*8+CurDescLine*8-8,DescLine[CurDescLine]);
    end;
  end;

begin
  SetColor(15);
  SetFillstyle(SolidFill,0);
  if not (Description='') then ShowDescription else NumDescLines := 0;
  CelOffsetX := 160 - Cel[0,0].Width;
  CurLoop := 0;
  CurCel := 0;
  LoadCel(0,0);
  DrawCel;
  DiscardCel(0,0);
  SetColor(15);
  OutTextXY(0,0,copy(ResName,1,12));
  FinishedViewing := FALSE;
  repeat
  begin
    ch := readkey;
    if ch = #0 then
    begin
      ch := readkey;
      if (ch=RIGHTkey) and (CurCel<NumCels[CurLoop]-1) then
      begin
        OldLoop := CurLoop;
        OldCel := CurCel;
        CurCel := CurCel + 1;
        LoadCel(CurLoop,CurCel);
        EraseOldCel;
        DrawCel;
        DiscardCel(CurLoop,CurCel);
      end;
      if (ch=LEFTkey) and (CurCel>0) then
      begin
        OldLoop := CurLoop;
        OldCel := CurCel;
        CurCel := CurCel - 1;
        LoadCel(CurLoop,CurCel);
        EraseOldCel;
        DrawCel;
        DiscardCel(CurLoop,CurCel);
      end;
      if (ch=UPkey) and (CurLoop<NumLoops-1) then
      begin
        OldLoop := CurLoop;
        OldCel := CurCel;
        CurLoop := CurLoop + 1;
        CurCel := 0;
        LoadCel(CurLoop,CurCel);
        EraseOldCel;
        DrawCel;
        DiscardCel(CurLoop,CurCel);
      end;
      if (ch=DOWNkey) and (CurLoop>0) then
      begin
        OldLoop := CurLoop;
        OldCel := CurCel;
        CurLoop := CurLoop - 1;
        CurCel := 0;
        LoadCel(CurLoop,CurCel);
        EraseOldCel;
        DrawCel;
        DiscardCel(CurLoop,CurCel);
      end;
    end;
    if ch = ESCkey then FinishedViewing := TRUE;
  end; until FinishedViewing;
end;

{***********************************************************************}
procedure RunViewView(ResData1:TData;ResName1:string);
{***********************************************************************}
begin
  ResData := ResData1;
  ResDataPos := 0;
  ResSize := ResData.Size;
  ResName := ResName1;
  Init_256;
  setup_palette;
  ReadViewInfo;
  DisplayView;
  CloseGraph;
end;

end.